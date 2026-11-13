-- Apply in the Supabase SQL editor for the pilot, then apply rubrics.sql.
create table if not exists public.trama_rubrics (
  key text primary key,
  answers jsonb not null
);
alter table public.trama_rubrics enable row level security;
revoke all on public.trama_rubrics from anon, authenticated;

create table if not exists public.trama_events (
  seq bigint generated always as identity primary key,
  owner uuid not null references auth.users(id) on delete cascade,
  id text not null check(id ~ '^[0-9a-f]{64}$'),
  kind text not null check(kind in ('session','review')),
  data jsonb not null,
  unique(owner,id)
);
alter table public.trama_events enable row level security;
revoke all on public.trama_events from anon, authenticated;
grant select on public.trama_events to authenticated;
drop policy if exists trama_own_events on public.trama_events;
create policy trama_own_events on public.trama_events for select to authenticated using(owner=auth.uid());

create or replace function public.trama_exchange(batch jsonb,after_seq bigint default 0)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  item jsonb;
  payload jsonb;
  rubric jsonb;
  response jsonb;
  prior public.trama_events;
  rows jsonb;
  last_seq bigint;
  ack jsonb := '[]';
  idx integer;
  expected boolean;
begin
  if uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if after_seq < 0 or jsonb_typeof(batch) is distinct from 'array' or jsonb_array_length(batch)>50 or octet_length(batch::text)>262144 then
    raise exception 'Invalid batch';
  end if;
  -- Serialize each account's inserts and reads so a cursor cannot skip an
  -- uncommitted event with a smaller sequence number.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(uid::text,0));
  if (select count(*) from public.trama_events where owner=uid)>20000 then raise exception 'Pilot quota reached'; end if;
  for item in select value from jsonb_array_elements(batch) loop
    payload:=item->'data';
    if jsonb_typeof(item->'id') is distinct from 'string'
       or (item->>'id') !~ '^[0-9a-f]{64}$'
       or jsonb_typeof(payload) is distinct from 'object'
       or payload->'version' is distinct from '1'::jsonb
       or jsonb_typeof(payload->'time') is distinct from 'string'
       or (payload->>'time') !~ '^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,6})?Z$'
       or (payload->>'time')::timestamptz > now()+interval '10 minutes' then raise exception 'Invalid event'; end if;
    select * into prior from public.trama_events where owner=uid and id=item->>'id';
    if found then
      if prior.kind is distinct from item->>'kind' or prior.data is distinct from payload then raise exception 'Conflicting event identifier'; end if;
    else
      if item->>'kind'='session' then
        select answers into rubric from public.trama_rubrics where key='session/'||(payload->>'lesson');
        if rubric is null or jsonb_typeof(payload->'answers') is distinct from 'array'
           or jsonb_array_length(payload->'answers')<>jsonb_array_length(rubric)
           or jsonb_typeof(payload->'id') is distinct from 'string'
           or length(payload->>'id') not between 1 and 128 then raise exception 'Invalid session'; end if;
        for idx in 0..jsonb_array_length(rubric)-1 loop
          response:=payload->'answers'->idx;
          expected:=trim(response->>'answer')=(rubric->>idx);
          if response->'item' is distinct from to_jsonb(idx)
             or jsonb_typeof(response->'answer') is distinct from 'string'
             or response->'correct' is distinct from to_jsonb(expected) then raise exception 'Invalid answer'; end if;
        end loop;
      elsif item->>'kind'='review' then
        select answers into rubric from public.trama_rubrics where key='review/'||(payload->>'lesson')||'/'||(payload->>'round');
        if rubric is null or jsonb_typeof(payload->'round') is distinct from 'number'
           or (payload->>'round') !~ '^[0-9]+$'
           or jsonb_typeof(payload->'answer') is distinct from 'string' then raise exception 'Unsupported review'; end if;
        expected:=(payload->>'answer')=(rubric->>0);
        if payload->'correct' is distinct from to_jsonb(expected) then raise exception 'Invalid review answer'; end if;
      else raise exception 'Unknown event type';
      end if;
      insert into public.trama_events(owner,id,kind,data) values(uid,item->>'id',item->>'kind',payload);
    end if;
    ack:=ack||jsonb_build_array(item->>'id');
  end loop;
  select coalesce(jsonb_agg(jsonb_build_object('id',id,'kind',kind,'data',data) order by seq),'[]'),coalesce(max(seq),after_seq)
    into rows,last_seq from (select * from public.trama_events where owner=uid and seq>after_seq order by seq limit 100) page;
  return jsonb_build_object('ack',ack,'events',rows,'cursor',last_seq,'more',
    exists(select 1 from public.trama_events where owner=uid and seq>last_seq));
end;
$$;
revoke all on function public.trama_exchange(jsonb,bigint) from public;
grant execute on function public.trama_exchange(jsonb,bigint) to authenticated;
