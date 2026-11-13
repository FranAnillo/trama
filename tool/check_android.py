"""Check ZIP integrity and 16 KB ELF alignment in an Android artifact."""
import argparse,hashlib,struct,zipfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('artifact');args=p.parse_args()
path=Path(args.artifact)
checked=[]
with zipfile.ZipFile(path) as z:
    assert z.testzip() is None, 'Corrupt ZIP entry'
    for name in z.namelist():
        if name.endswith('.so') and any('/'+abi+'/' in '/'+name for abi in ['arm64-v8a','x86_64']):
            data=z.read(name)
            assert data[:4]==b'\x7fELF' and data[4]==2, name
            order='<' if data[5]==1 else '>'
            offset=struct.unpack_from(order+'Q',data,32)[0]
            size,count=struct.unpack_from(order+'HH',data,54)
            alignments=[]
            for n in range(count):
                start=offset+n*size
                if struct.unpack_from(order+'I',data,start)[0]==1:
                    alignment=struct.unpack_from(order+'Q',data,start+48)[0]
                    assert alignment>=16384, f'{name}: alignment {alignment} < 16 KB'
                    alignments.append(alignment)
            assert alignments, name
            checked.append(name)
assert checked, 'No 64-bit native libraries found'
print(f'PASS: {path.name}, ZIP íntegro y {len(checked)} bibliotecas de 64 bits con alineación ELF de 16 KB o superior.')
print('SHA256:',hashlib.sha256(path.read_bytes()).hexdigest())
