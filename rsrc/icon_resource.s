.section .rsrc,"dr"
.p2align 2
rsrc_begin:
    .long 0, 0
    .short 0, 0, 0, 2
    .long 3
    .long (icon_dir-rsrc_begin)+0x80000000
    .long 14
    .long (group_dir-rsrc_begin)+0x80000000
icon_dir:
    .long 0, 0
    .short 0, 0, 0, 7
    .long 1
    .long (icon_lang_1-rsrc_begin)+0x80000000
    .long 2
    .long (icon_lang_2-rsrc_begin)+0x80000000
    .long 3
    .long (icon_lang_3-rsrc_begin)+0x80000000
    .long 4
    .long (icon_lang_4-rsrc_begin)+0x80000000
    .long 5
    .long (icon_lang_5-rsrc_begin)+0x80000000
    .long 6
    .long (icon_lang_6-rsrc_begin)+0x80000000
    .long 7
    .long (icon_lang_7-rsrc_begin)+0x80000000
icon_lang_1:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1033
    .long icon_entry_1-rsrc_begin
icon_lang_2:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1033
    .long icon_entry_2-rsrc_begin
icon_lang_3:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1033
    .long icon_entry_3-rsrc_begin
icon_lang_4:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1033
    .long icon_entry_4-rsrc_begin
icon_lang_5:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1033
    .long icon_entry_5-rsrc_begin
icon_lang_6:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1033
    .long icon_entry_6-rsrc_begin
icon_lang_7:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1033
    .long icon_entry_7-rsrc_begin
group_dir:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1
    .long (group_lang-rsrc_begin)+0x80000000
group_lang:
    .long 0, 0
    .short 0, 0, 0, 1
    .long 1033
    .long group_entry-rsrc_begin
icon_entry_1:
    .long icon_data_1@imgrel
    .long 925
    .long 0, 0
icon_entry_2:
    .long icon_data_2@imgrel
    .long 1897
    .long 0, 0
icon_entry_3:
    .long icon_data_3@imgrel
    .long 3208
    .long 0, 0
icon_entry_4:
    .long icon_data_4@imgrel
    .long 6723
    .long 0, 0
icon_entry_5:
    .long icon_data_5@imgrel
    .long 11297
    .long 0, 0
icon_entry_6:
    .long icon_data_6@imgrel
    .long 38536
    .long 0, 0
icon_entry_7:
    .long icon_data_7@imgrel
    .long 121460
    .long 0, 0
group_entry:
    .long group_data@imgrel
    .long 104
    .long 0, 0
.p2align 2
icon_data_1:
    .incbin "rsrc/icon_1.bin"
    .p2align 2
icon_data_2:
    .incbin "rsrc/icon_2.bin"
    .p2align 2
icon_data_3:
    .incbin "rsrc/icon_3.bin"
    .p2align 2
icon_data_4:
    .incbin "rsrc/icon_4.bin"
    .p2align 2
icon_data_5:
    .incbin "rsrc/icon_5.bin"
    .p2align 2
icon_data_6:
    .incbin "rsrc/icon_6.bin"
    .p2align 2
icon_data_7:
    .incbin "rsrc/icon_7.bin"
    .p2align 2
group_data:
    .incbin "rsrc/group_icon.bin"
    .p2align 2
