"""Isolated PostgreSQL checks. Requires Docker and postgres:16-alpine locally."""
import json
import subprocess
import time
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
name = 'trama-check-' + uuid.uuid4().hex[:10]
A, B = '11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222'

def sql(query, owner=None, role='authenticated', fails=False):
    if owner:
        query = f"set role {role}; set request.jwt.claim.sub='{owner}';\n" + query
    r = subprocess.run(['docker','exec','-i',name,'psql','-h','127.0.0.1','-U','postgres','-qtA','-v','ON_ERROR_STOP=1'], input=query, text=True, capture_output=True)
    if fails:
        assert r.returncode != 0, 'Invalid request accepted'
        return
    assert r.returncode == 0, r.stderr
    return r.stdout.strip()

def exchange(batch, owner=A, cursor=0, fails=False):
    data = json.dumps(batch).replace("'", "''")
    result = sql(f"select public.trama_exchange('{data}'::jsonb,{cursor});", owner, fails=fails)
    return json.loads(result) if result else None

try:
    subprocess.run(['docker','run','--rm','--name',name,'-e','POSTGRES_PASSWORD=local-only-test','-d','postgres:16-alpine'], check=True, capture_output=True)
    for _ in range(40):
        ready = subprocess.run(['docker','exec',name,'pg_isready','-h','127.0.0.1','-U','postgres'], capture_output=True)
        if ready.returncode == 0: break
        time.sleep(.25)
    sql(f"""create role anon nologin; create role authenticated nologin;
    create schema auth; create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as 'select nullif(current_setting(''request.jwt.claim.sub'',true),'''')::uuid';
    grant usage on schema auth to authenticated;
    insert into auth.users values ('{A}'),('{B}');""")
    sql((ROOT/'backend/schema.sql').read_text())
    sql((ROOT/'backend/rubrics.sql').read_text())
    keys = json.loads(sql("select answers from trama_rubrics where key='session/ac';"))
    def item(i):
        return {'id':f'{i:064x}', 'kind':'session', 'data':{'id':f's{i}', 'version':1, 'lesson':'ac', 'time':'2026-11-01T12:00:00Z', 'answers':[{'item':n, 'answer':str(k),'correct':True} for n,k in enumerate(keys)]}}
    result = exchange([item(1)])
    assert len(result['events']) == 1
    exchange([item(1)])
    assert sql('select count(*) from trama_events;',A) == '1'
    assert exchange([],B)['events'] == []
    assert sql('select count(*) from trama_events;',B) == '0'
    assert len(exchange([item(1)],B)['events']) == 1
    sql('select * from trama_rubrics;',A,fails=True)
    sql('delete from trama_events;',A,fails=True)
    sql("select public.trama_exchange('[]',0);",A,role='anon',fails=True)
    bad = item(2); bad['data']['answers'][0]['correct'] = False
    exchange([bad], fails=True)
    bad = item(1); bad['data']['id'] = 'conflict'
    exchange([bad], fails=True)
    # Entire transaction rolls back if a later event fails validation.
    bad = item(3); bad['data']['lesson'] = 'unknown'
    exchange([item(2),bad], fails=True)
    assert sql('select count(*) from trama_events;',A) == '1'
    exchange([item(i) for i in range(2,52)])
    exchange([item(i) for i in range(52,102)])
    first = exchange([])
    assert len(first['events']) == 100 and first['more']
    last = exchange([],cursor=first['cursor'])
    assert len(last['events']) == 1 and not last['more']
    assert len(exchange([],B)['events']) == 1
    review_key = json.loads(sql("select answers from trama_rubrics where key='review/ac/0';"))[0]
    review = {'id': 'f'*64, 'kind':'review', 'data':{'lesson':'ac','round':0,'version':1,'time':'2026-11-02T12:00:00.000Z','answer':review_key,'correct':True}}
    exchange([review])
    review['id'] = 'e'*64; review['data']['round'] = '0'
    exchange([review],fails=True)
    review['data']['round'] = 0; review['data']['version'] = '1'
    exchange([review],fails=True)
    review['data']['version'] = 1; review['data']['time'] = '-infinity'
    exchange([review],fails=True)
    print('PASS: instalación, autenticación, aislamiento, permisos, reintentos, validación, rollback y paginación (101 eventos).')
finally:
    subprocess.run(['docker','rm','-f',name],capture_output=True)
