"""Build a Windows x64 COFF .syso icon resource from a multi-size .ico.

Requirements: Python 3, clang. Windows PE RVA fixup happens post-build in
fix_icon_resource_pe.py for compatibility with Go's COFF resource linking.
"""
from pathlib import Path
import struct, subprocess
root=Path(__file__).parent
ico=(root/'assets/Tunnel_Escape_FE_Trainer.ico').read_bytes()
reserved,typ,count=struct.unpack_from('<HHH',ico,0)
assert reserved==0 and typ==1 and count>=1
icons=[]
rsrc=root/'rsrc'
rsrc.mkdir(exist_ok=True)
for i in range(count):
    w,h,colors,resv,planes,bpp,size,offset=struct.unpack_from('<BBBBHHII',ico,6+i*16)
    data=ico[offset:offset+size]
    filename=f'icon_{i+1}.bin'
    (rsrc/filename).write_bytes(data)
    icons.append((w,h,colors,resv,planes,bpp,size,i+1,filename))
group=struct.pack('<HHH',0,1,count)
for w,h,colors,resv,planes,bpp,size,idx,_ in icons:
    group+=struct.pack('<BBBBHHIH',w,h,colors,resv,planes,bpp,size,idx)
(rsrc/'group_icon.bin').write_bytes(group)
lines=[]
def out(line=''): lines.append(line)
out('.section .rsrc,"dr"')
out('.p2align 2')
out('rsrc_begin:')
def dirheader(n):
    out('    .long 0, 0')
    out('    .short 0, 0, 0, '+str(n))
dirheader(2)
out('    .long 3')
out('    .long (icon_dir-rsrc_begin)+0x80000000')
out('    .long 14')
out('    .long (group_dir-rsrc_begin)+0x80000000')
out('icon_dir:')
dirheader(count)
for i in range(count):
    out(f'    .long {i+1}')
    out(f'    .long (icon_lang_{i+1}-rsrc_begin)+0x80000000')
for i in range(count):
    out(f'icon_lang_{i+1}:')
    dirheader(1)
    out('    .long 1033')
    out(f'    .long icon_entry_{i+1}-rsrc_begin')
out('group_dir:')
dirheader(1)
out('    .long 1')
out('    .long (group_lang-rsrc_begin)+0x80000000')
out('group_lang:')
dirheader(1)
out('    .long 1033')
out('    .long group_entry-rsrc_begin')
for i,(_,_,_,_,_,_,size,_,_) in enumerate(icons):
    out(f'icon_entry_{i+1}:')
    out(f'    .long icon_data_{i+1}@imgrel')
    out(f'    .long {size}')
    out('    .long 0, 0')
out('group_entry:')
out('    .long group_data@imgrel')
out(f'    .long {len(group)}')
out('    .long 0, 0')
out('.p2align 2')
for i in range(count):
    out(f'icon_data_{i+1}:')
    out(f'    .incbin "rsrc/icon_{i+1}.bin"')
    out('    .p2align 2')
out('group_data:')
out('    .incbin "rsrc/group_icon.bin"')
out('    .p2align 2')
asm=rsrc/'icon_resource.s'
asm.write_text('\n'.join(lines)+'\n')
subprocess.run(['clang','--target=x86_64-w64-windows-gnu','-c',str(asm.relative_to(root)),'-o','rsrc_icon.syso'],cwd=root,check=True)
print('Resource compiled with',count,'icon sizes')
