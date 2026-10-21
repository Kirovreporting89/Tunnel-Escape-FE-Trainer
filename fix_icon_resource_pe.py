"""Verify and fix icon RVA pointers in the compiled Windows PE .rsrc.

Go's linker sometimes resolves IMAGE_REL_AMD64_ADDR32NB relocations for
incbin sublabels at the resource section start instead of the intended data.
This resolves the actual icon bytes and updates only those pointers.
"""
import struct, sys
from pathlib import Path
root=Path(__file__).parent
exe=Path(sys.argv[1])
data=bytearray(exe.read_bytes())
pe=struct.unpack_from('<I',data,0x3c)[0]
assert data[pe:pe+4]==b'PE\0\0'
coff=pe+4
sections=struct.unpack_from('<H',data,coff+2)[0]
opt=coff+20
assert struct.unpack_from('<H',data,opt)[0]==0x20b
optlen=struct.unpack_from('<H',data,coff+16)[0]
rsrc_rva,rsrc_sz=struct.unpack_from('<II',data,opt+112+2*8)
assert rsrc_rva and rsrc_sz

def rva_to_off(rva):
    for i in range(sections):
        entry=opt+optlen+40*i
        virtsz,vaddr,rawsz,rawoff=struct.unpack_from('<IIII',data,entry+8)
        if vaddr<=rva <vaddr+max(virtsz,rawsz):
            return rawoff+(rva-vaddr)
    raise ValueError(f'Unknown RVA {rva:x}')
resoff=rva_to_off(rsrc_rva)

def resources():
    def visit(rel,depth,typ=None,idx=None):
        off=resoff+rel
        named,ids=struct.unpack_from('<HH',data,off+12)
        total=named+ids
        for j in range(total):
            idval,nextval=struct.unpack_from('<II',data,off+16+j*8)
            if depth==0: newtyp=idval&0xffff; newidx=None
            elif depth==1: newtyp=typ; newidx=idval&0xffff
            else: newtyp=typ; newidx=idx
            if nextval&0x80000000:
                yield from visit(nextval&0x7fffffff,depth+1,newtyp,newidx)
            else:
                yield newtyp,newidx,resoff+(nextval&0x7fffffff)
    yield from visit(0,0)

ico=(root/'assets/Tunnel_Escape_FE_Trainer.ico').read_bytes()
_,_,count=struct.unpack_from('<HHH',ico,0)
icon_bytes={}
group=struct.pack('<HHH',0,1,count)
for i in range(count):
    w,h,cl,rs,planes,bpp,size,offset=struct.unpack_from('<BBBBHHII',ico,6+i*16)
    icon_bytes[i+1]=ico[offset:offset+size]
    group+=struct.pack('<BBBBHHIH',w,h,cl,rs,planes,bpp,size,i+1)
found={}
for typ,idx,entry_off in resources():
    if typ==3 and idx in icon_bytes: blob=icon_bytes[idx]
    elif typ==14 and idx==1: blob=group
    else: continue
    ptr=data.find(blob,resoff)
    if ptr<0: raise RuntimeError(f'Resource icon type={typ} id={idx} not found')
    desired_rva=rsrc_rva+(ptr-resoff)
    _,oldsize=struct.unpack_from('<II',data,entry_off)
    if oldsize!=len(blob): raise RuntimeError(f'Unexpected size for {typ}/{idx}: {oldsize} vs {len(blob)}')
    struct.pack_into('<I',data,entry_off,desired_rva)
    found[(typ,idx)]=(ptr,desired_rva)
expected=count+1
if len(found)!=expected: raise RuntimeError(f'Only found {len(found)}/{expected} icon resources')
exe.write_bytes(data)
print('Patched and verified',len(found),'PE icon resources',exe, 'resource RVA:',hex(rsrc_rva))
for key in sorted(found):print(key,hex(found[key][1]))
