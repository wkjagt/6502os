.export string_table

.code

string_table:
                .word s_startup, s_any_key

s_startup:      .byte "Shallow Thought v0.01", 0                
s_any_key:      .byte "Press any key", 0
