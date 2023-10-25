.include "disassembler.inc"
.include "../os/jump_table.inc"

.zeropage

mnemonic:       .res 1
addr_mode:      .res 1
code_pointer:   .res 1

.code

;-------------------------------------------------------------
; This finds the instruction in the opcodes table. The opcodes
; table is 512 bytes long (256 entries of 2 bytes). The opcode
; is multiplied by 2 before being used as an index into the
; table. If multiplying by 2 sets the carry flag, the entry
; is in the second half of the table.
;-------------------------------------------------------------
find_instruction:
                lda     (code_pointer)  ; load the next opcode into A
                asl     a
                tay
                bcs     @second_half
                lda     opcodes,y
                sta     mnemonic
                lda     opcodes+1,y
                sta     addr_mode
                bra     @done
@second_half:   lda     opcodes+$100,y
                sta     mnemonic
                lda     opcodes+$101,y
                sta     addr_mode
@done:          rts

;==============================================================
;==============================================================
print_instruction:
                jsr     print_mn
                lda     #' '
                jsr     JMP_PUTC
                jsr     print_args
                rts

;==============================================================
; find the mnemonic in the mnemonics table. The index index is
; multiplied by 4 because the entries are 4 bytes long.
; There are less than 128 mnemonics, so the first left shift
; never sets the carry flag. There are more than 64 mnemonics
; so the second left shift can result in a set carry flag. The
; carry flag is checked to determine if the resulting index
; points to the first or second half of the table.
;==============================================================
print_mn:       lda     mnemonic        ; mutiply by 4 to get mnemonic index
                asl
                asl
                tay
                bcs     @second_half
                lda     mnemonics2+$0,y
                jsr     JMP_PUTC
                lda     mnemonics2+$1,y
                jsr     JMP_PUTC
                lda     mnemonics2+$2,y
                jsr     JMP_PUTC
                bra     @done
@second_half:   lda     mnemonics2+$100,y
                jsr     JMP_PUTC
                lda     mnemonics2+$101,y
                jsr     JMP_PUTC
                lda     mnemonics2+$102,y
                jsr     JMP_PUTC
                lda     mnemonics2+$103,y
                jsr     JMP_PUTC
@done:          rts


print_args:     ldy     addr_mode
                lda     addressing_modes,y    ; index into formats table
                tay
@loop:          lda     addressing_mode_formats,y
                beq     @done
                cmp     #'*'
                bne     @notargval
                lda     addressing_mode_formats+1,y
                cmp     #'*'            ; is next char also *? yes: 2 byte arg
                bne     @1bytearg
                iny
                jsr     print2bytearg
                bra     @next
@1bytearg:      jsr     print1bytearg
                bra     @next
@notargval:     jsr     JMP_PUTC
@next:          iny
                bra     @loop
@done:          rts

; x contains arg size
print1bytearg:  inc16   code_pointer
                lda     (code_pointer)
                jsr     JMP_PRINT_HEX
                rts

print2bytearg:  phy
                ldy     #2
@loop:          lda     (code_pointer),y
                jsr     JMP_PRINT_HEX
                dey
                bne     @loop
                inc16   code_pointer
                inc16   code_pointer
                ply
                rts
;-------------------------------------------------------------
; table is 512 bytes, and is indexed into by opcode byte and
; carry flag
;-------------------------------------------------------------
opcodes:        ; MSB 0 =======================
                .byte MN_BRK, MODE_IMPL    ;$00
                .byte MN_ORA, MODE_IZX     ;$01
                .byte 0, 0                 ;$02
                .byte 0, 0                 ;$03
                .byte MN_TSB, MODE_ZP      ;$04
                .byte MN_ORA, MODE_ZP      ;$05
                .byte MN_ASL, MODE_ZP      ;$06
                .byte MN_RMB0, MODE_ZP     ;$07
                .byte MN_PHP, MODE_IMPL    ;$08
                .byte MN_ORA, MODE_IMM     ;$09
                .byte MN_ASL, MODE_IMPL    ;$0a
                .byte 0, 0                 ;$0b
                .byte MN_TSB, MODE_ABS     ;$0c
                .byte MN_ORA, MODE_ABS     ;$0d
                .byte MN_ASL, MODE_ABS     ;$0e
                .byte MN_BBR0, MODE_ZREL   ;$0f
                ; MSB 1 =======================
                .byte MN_BPL, MODE_REL     ;$10
                .byte MN_ORA, MODE_IZY     ;$11
                .byte MN_ORA, MODE_IZP     ;$12
                .byte 0, 0                 ;$13
                .byte MN_TRB, MODE_ZP      ;$14
                .byte MN_ORA, MODE_ZPX     ;$15
                .byte MN_ASL, MODE_ZPX     ;$16
                .byte MN_RMB1, MODE_ZP     ;$17
                .byte MN_CLC, MODE_IMPL    ;$18
                .byte MN_ORA, MODE_ABY     ;$19
                .byte MN_INC, MODE_IMPL    ;$1a
                .byte 0, 0                 ;$1b
                .byte MN_TRB, MODE_ABS     ;$1c
                .byte MN_ORA, MODE_ABX     ;$1d
                .byte MN_ASL, MODE_ABX     ;$1e
                .byte MN_BBR1, MODE_ZREL   ;$1f
                ; MSB 2 =======================
                .byte MN_JSR, MODE_ABS     ;$20
                .byte MN_AND, MODE_IZX     ;$21
                .byte 0, 0                 ;$22
                .byte 0, 0                 ;$23
                .byte MN_BIT, MODE_ZP      ;$24
                .byte MN_AND, MODE_ZP      ;$25
                .byte MN_ROL, MODE_ZP      ;$26
                .byte MN_RMB2, MODE_ZP     ;$27
                .byte MN_PLP, MODE_IMPL    ;$28
                .byte MN_AND, MODE_IMM     ;$29
                .byte MN_ROL, MODE_IMPL    ;$2a
                .byte 0, 0                 ;$2b
                .byte MN_BIT, MODE_ABS     ;$2c
                .byte MN_AND, MODE_ABS     ;$2d
                .byte MN_ROL, MODE_ABS     ;$2e
                .byte MN_BBR2, MODE_ZREL   ;$2f
                ; MSB 3 =======================
                .byte MN_BMI, MODE_REL     ;$30
                .byte MN_AND, MODE_IZY     ;$31
                .byte MN_AND, MODE_IZP     ;$32
                .byte 0, 0                 ;$33
                .byte MN_BIT, MODE_ZPX     ;$34
                .byte MN_AND, MODE_ZPX     ;$35
                .byte MN_ROL, MODE_ZPX     ;$36
                .byte MN_RMB3, MODE_ZP     ;$37
                .byte MN_SEC, MODE_IMPL    ;$38
                .byte MN_AND, MODE_ABY     ;$39
                .byte MN_DEC, MODE_IMPL    ;$3a
                .byte 0, 0                 ;$3b
                .byte MN_BIT, MODE_ABX     ;$3c
                .byte MN_AND, MODE_ABX     ;$3d
                .byte MN_ROL, MODE_ABX     ;$3e
                .byte MN_BBR3, MODE_ZREL   ;$3f
                ; MSB 4 =======================
                .byte MN_RTI, MODE_IMPL    ;$40
                .byte MN_EOR, MODE_IZX     ;$41
                .byte 0, 0                 ;$42
                .byte 0, 0                 ;$43
                .byte 0, 0                 ;$44
                .byte MN_EOR, MODE_ZP      ;$45
                .byte MN_LSR, MODE_ZP      ;$46
                .byte MN_RMB4, MODE_ZP     ;$47
                .byte MN_PHA, MODE_IMPL    ;$48
                .byte MN_EOR, MODE_IMM     ;$49
                .byte MN_LSR, MODE_IMPL    ;$4a
                .byte 0, 0                 ;$4b
                .byte MN_JMP, MODE_ABS     ;$4c
                .byte MN_EOR, MODE_ABS     ;$4d
                .byte MN_LSR, MODE_ABS     ;$4e
                .byte MN_BBR4, MODE_ZREL   ;$4f
                ; MSB 5 =======================
                .byte MN_BVC, MODE_REL     ;$50
                .byte MN_EOR, MODE_IZY     ;$51
                .byte MN_EOR, MODE_IZP     ;$52
                .byte 0, 0                 ;$53
                .byte 0, 0                 ;$54
                .byte MN_EOR, MODE_ZPX     ;$55
                .byte MN_LSR, MODE_ZPX     ;$56
                .byte MN_RMB5, MODE_ZP     ;$57
                .byte MN_CLI, MODE_IMPL    ;$58
                .byte MN_EOR, MODE_ABY     ;$59
                .byte MN_PHY, MODE_IMPL    ;$5a
                .byte 0, 0                 ;$5b
                .byte 0, 0                 ;$5c
                .byte MN_EOR, MODE_ABX     ;$5d
                .byte MN_LSR, MODE_ABX     ;$5e
                .byte MN_BBR5, MODE_ZREL   ;$5f
                ; MSB 6 =======================
                .byte MN_RTS, MODE_IMPL    ;$60
                .byte MN_ADC, MODE_IZX     ;$61
                .byte 0, 0                 ;$62
                .byte 0, 0                 ;$63
                .byte MN_STZ, MODE_ZP      ;$64
                .byte MN_ADC, MODE_ZP      ;$65
                .byte MN_ROR, MODE_ZP      ;$66
                .byte MN_RMB6, MODE_ZP     ;$67
                .byte MN_PLA, MODE_IMPL    ;$68
                .byte MN_ADC, MODE_IMM     ;$69
                .byte MN_ROR, MODE_IMPL    ;$6a
                .byte 0, 0                 ;$6b
                .byte MN_JMP, MODE_IND     ;$6c
                .byte MN_ADC, MODE_ABS     ;$6d
                .byte MN_ROR, MODE_ABS     ;$6e
                .byte MN_BBR6, MODE_ZREL   ;$6f
                ; MSB 7 =======================
                .byte MN_BVS, MODE_REL     ;$70
                .byte MN_ADC, MODE_IZY     ;$71
                .byte MN_ADC, MODE_IZP     ;$72
                .byte 0, 0                 ;$73
                .byte MN_STZ, MODE_ZPX     ;$74
                .byte MN_ADC, MODE_ZPX     ;$75
                .byte MN_ROR, MODE_ZPX     ;$76
                .byte MN_RMB7, MODE_ZP     ;$77
                .byte MN_SEI, MODE_IMPL    ;$78
                .byte MN_ADC, MODE_ABY     ;$79
                .byte MN_PLY, MODE_IMPL    ;$7a
                .byte 0, 0                 ;$7b
                .byte MN_JMP, MODE_IAX     ;$7c
                .byte MN_ADC, MODE_ABX     ;$7d
                .byte MN_ROR, MODE_ABX     ;$7e
                .byte MN_BBR7, MODE_ZREL   ;$7f
                ; MSB 8 =======================
                .byte MN_BRA, MODE_REL     ;$80
                .byte MN_STA, MODE_IZX     ;$81
                .byte 0, 0                 ;$82
                .byte 0, 0                 ;$83
                .byte MN_STY, MODE_ZP      ;$84
                .byte MN_STA, MODE_ZP      ;$85
                .byte MN_STX, MODE_ZP      ;$86
                .byte MN_SMB0, MODE_ZP     ;$87
                .byte MN_DEY, MODE_IMPL    ;$88
                .byte MN_BIT, MODE_IMM     ;$89
                .byte MN_TXA, MODE_IMPL    ;$8a
                .byte 0, 0                 ;$8b
                .byte MN_STY, MODE_ABS     ;$8c
                .byte MN_STA, MODE_ABS     ;$8d
                .byte MN_STX, MODE_ABS     ;$8e
                .byte MN_BBS0, MODE_ZREL   ;$8f
                ; MSB 9 =======================
                .byte MN_BCC, MODE_REL     ;$90
                .byte MN_STA, MODE_IZY     ;$91
                .byte MN_STA, MODE_IZP     ;$92
                .byte 0, 0                 ;$93
                .byte MN_STY, MODE_ZPX     ;$94
                .byte MN_STA, MODE_ZPX     ;$95
                .byte MN_STX, MODE_ZPY     ;$96
                .byte MN_SMB1, MODE_ZP     ;$97
                .byte MN_TYA, MODE_IMPL    ;$98
                .byte MN_STA, MODE_ABY     ;$99
                .byte MN_TXS, MODE_IMPL    ;$9a
                .byte 0, 0                 ;$9b
                .byte MN_STZ, MODE_ABS     ;$9c
                .byte MN_STA, MODE_ABX     ;$9d
                .byte MN_STZ, MODE_ABX     ;$9e
                .byte MN_BBS1, MODE_ZREL   ;$9f
                ; MSB A =======================
                .byte MN_LDY, MODE_IMM     ;$a0
                .byte MN_LDA, MODE_IZX     ;$a1
                .byte MN_LDX, MODE_IMM     ;$a2
                .byte 0, 0                 ;$a3
                .byte MN_LDY, MODE_ZP      ;$a4
                .byte MN_LDA, MODE_ZP      ;$a5
                .byte MN_LDX, MODE_ZP      ;$a6
                .byte MN_SMB2, MODE_ZP     ;$a7
                .byte MN_TAY, MODE_IMPL    ;$a8
                .byte MN_LDA, MODE_IMM     ;$a9
                .byte MN_TAX, MODE_IMPL    ;$aa
                .byte 0, 0                 ;$ab
                .byte MN_LDY, MODE_ABS     ;$ac
                .byte MN_LDA, MODE_ABS     ;$ad
                .byte MN_LDX, MODE_ABS     ;$ae
                .byte MN_BBS2, MODE_ZREL   ;$af
                ; MSB B =======================
                .byte MN_BCS, MODE_REL     ;$b0
                .byte MN_LDA, MODE_IZY     ;$b1
                .byte MN_LDA, MODE_IZP     ;$b2
                .byte 0, 0                 ;$b3
                .byte MN_LDY, MODE_ZPX     ;$b4
                .byte MN_LDA, MODE_ZPX     ;$b5
                .byte MN_LDX, MODE_ZPY     ;$b6
                .byte MN_SMB3, MODE_ZP     ;$b7
                .byte MN_CLV, MODE_IMPL    ;$b8
                .byte MN_LDA, MODE_ABY     ;$b9
                .byte MN_TSX, MODE_IMPL    ;$ba
                .byte 0, 0                 ;$bb
                .byte MN_LDY, MODE_ABX     ;$bc
                .byte MN_LDA, MODE_ABX     ;$bd
                .byte MN_LDX, MODE_ABY     ;$be
                .byte MN_BBS3, MODE_ZREL   ;$bf
                ; MSB C =======================
                .byte MN_CPY, MODE_IMM     ;$c0
                .byte MN_CMP, MODE_IZX     ;$c1
                .byte 0, 0                 ;$c2
                .byte 0, 0                 ;$c3
                .byte MN_CPY, MODE_ZP      ;$c4
                .byte MN_CMP, MODE_ZP      ;$c5
                .byte MN_DEC, MODE_ZP      ;$c6
                .byte MN_SMB4, MODE_ZP     ;$c7
                .byte MN_INY, MODE_IMPL    ;$c8
                .byte MN_CMP, MODE_IMM     ;$c9
                .byte MN_DEX, MODE_IMPL    ;$ca
                .byte MN_WAI, MODE_IMPL    ;$cb
                .byte MN_CPY, MODE_ABS     ;$cc
                .byte MN_CMP, MODE_ABS     ;$cd
                .byte MN_DEC, MODE_ABS     ;$ce
                .byte MN_BBS4, MODE_ZREL   ;$cf
                ; MSB D =======================
                .byte MN_BNE, MODE_REL     ;$d0
                .byte MN_CMP, MODE_IZY     ;$d1
                .byte MN_CMP, MODE_IZP     ;$d2
                .byte 0, 0                 ;$d3
                .byte 0, 0                 ;$d4
                .byte MN_CMP, MODE_ZPX     ;$d5
                .byte MN_DEC, MODE_ZPX     ;$d6
                .byte MN_SMB5, MODE_ZP     ;$d7
                .byte MN_CLD, MODE_IMPL    ;$d8
                .byte MN_CMP, MODE_ABY     ;$d9
                .byte MN_PHX, MODE_IMPL    ;$da
                .byte MN_STP, MODE_IMPL    ;$db
                .byte 0, 0                 ;$dc
                .byte MN_CMP, MODE_ABX     ;$dd
                .byte MN_DEC, MODE_ABX     ;$de
                .byte MN_BBS5, MODE_ZREL   ;$df
                ; MSB E =======================
                .byte MN_CPX, MODE_IMM     ;$e0
                .byte MN_SBC, MODE_IZX     ;$e1
                .byte 0, 0                 ;$e2
                .byte 0, 0                 ;$e3
                .byte MN_CPX, MODE_ZP      ;$e4
                .byte MN_SBC, MODE_ZP      ;$e5
                .byte MN_INC, MODE_ZP      ;$e6
                .byte MN_SMB6, MODE_ZP     ;$e7
                .byte MN_INX, MODE_IMPL    ;$e8
                .byte MN_SBC, MODE_IMM     ;$e9
                .byte MN_NOP, MODE_IMPL    ;$ea (official NOP)
                .byte 0, 0                 ;$eb
                .byte MN_CPX, MODE_ABS     ;$ec
                .byte MN_SBC, MODE_ABS     ;$ed
                .byte MN_INC, MODE_ABS     ;$ee
                .byte MN_BBS6, MODE_ZREL   ;$ef
                ; MSB F =======================
                .byte MN_BEQ, MODE_REL     ;$f0
                .byte MN_SBC, MODE_IZY     ;$f1
                .byte MN_SBC, MODE_IZP     ;$f2
                .byte 0, 0                 ;$f3
                .byte 0, 0                 ;$f4
                .byte MN_SBC, MODE_ZPX     ;$f5
                .byte MN_INC, MODE_ZPX     ;$f6
                .byte MN_SMB7, MODE_ZP     ;$f7
                .byte MN_SED, MODE_IMPL    ;$f8
                .byte MN_SBC, MODE_ABY     ;$f9
                .byte MN_PLX, MODE_IMPL    ;$fa
                .byte 0, 0                 ;$fb
                .byte 0, 0                 ;$fc
                .byte MN_SBC, MODE_ABX     ;$fd
                .byte MN_INC, MODE_ABX     ;$fe
                .byte MN_BBS7, MODE_ZREL   ;$ff

                                        ; index
mnemonics2:     .byte  "DEX", 0         ; 0
                .byte  "DEY", 0         ; 4
                .byte  "TAX", 0         ; 8
                .byte  "TSB", 0         ; 12
                .byte  "BPL", 0         ; 16
                .byte  "BCC", 0         ; 20
                .byte  "CPX", 0         ; 24
                .byte  "EOR", 0         ; 28
                .byte  "TSX", 0         ; 32
                .byte  "DEC", 0         ; 36
                .byte  "STA", 0         ; 40
                .byte  "LDA", 0         ; 44
                .byte  "BEQ", 0         ; 
                .byte  "ROL", 0         ; 
                .byte  "STY", 0
                .byte  "JMP", 0
                .byte  "BMI", 0
                .byte  "RTI", 0
                .byte  "TAY", 0
                .byte  "TXA", 0
                .byte  "RTS", 0
                .byte  "SED", 0
                .byte  "LSR", 0
                .byte  "BNE", 0
                .byte  "JSR", 0
                .byte  "LDY", 0
                .byte  "SEC", 0
                .byte  "BIT", 0
                .byte  "LDX", 0
                .byte  "TXS", 0
                .byte  "SEI", 0
                .byte  "ASL", 0
                .byte  "BVS", 0
                .byte  "CPY", 0
                .byte  "CLI", 0
                .byte  "CLD", 0
                .byte  "TRB", 0
                .byte  "CLC", 0
                .byte  "BCS", 0
                .byte  "ADC", 0
                .byte  "CLV", 0
                .byte  "STX", 0
                .byte  "ROR", 0
                .byte  "STZ", 0
                .byte  "AND", 0
                .byte  "PHP", 0
                .byte  "INX", 0
                .byte  "INY", 0
                .byte  "PLP", 0
                .byte  "PHA", 0
                .byte  "CMP", 0
                .byte  "TYA", 0
                .byte  "PLY", 0
                .byte  "PLX", 0
                .byte  "BVC", 0
                .byte  "SBC", 0
                .byte  "PHY", 0
                .byte  "PHX", 0
                .byte  "BRK", 0
                .byte  "PLA", 0
                .byte  "INC", 0
                .byte  "NOP", 0
                .byte  "BRA", 0
                .byte  "ORA", 0
                .byte  "BBR0"


; index into formats table / instruction size
addressing_modes:
                .byte mode_iax_fmt  - addressing_mode_formats, 3
                .byte mode_izp_fmt  - addressing_mode_formats, 2
                .byte mode_zpx_fmt  - addressing_mode_formats, 2
                .byte mode_zpy_fmt  - addressing_mode_formats, 2
                .byte mode_izx_fmt  - addressing_mode_formats, 2
                .byte mode_imm_fmt  - addressing_mode_formats, 2
                .byte mode_izy_fmt  - addressing_mode_formats, 2
                .byte mode_ind_fmt  - addressing_mode_formats, 3
                .byte mode_abs_fmt  - addressing_mode_formats, 3
                .byte mode_rel_fmt  - addressing_mode_formats, 2
                .byte mode_aby_fmt  - addressing_mode_formats, 3
                .byte mode_abx_fmt  - addressing_mode_formats, 3
                .byte mode_zp_fmt   - addressing_mode_formats, 2
                .byte mode_impl_fmt - addressing_mode_formats, 1
                .byte mode_zrel_fmt - addressing_mode_formats, 3

;=========================================================================
; Formats for all the different addressing modes. These are all labelled
; because the entries are all different lengths, making it impossible to
; search through the table by the first byte of each entry. Instead, the
; addressing_modes table indexes into this table using calculated
; indexes.
; * will be replaced by the argument value
;=========================================================================
addressing_mode_formats:
mode_iax_fmt:   .byte "($**,x)",0
mode_izp_fmt:   .byte "($*)",0
mode_zpx_fmt:   .byte "$*,x",0
mode_zpy_fmt:   .byte "$*,y",0
mode_izx_fmt:   .byte "($*,x)",0
mode_imm_fmt:   .byte "#$*",0
mode_izy_fmt:   .byte "($*),y",0
mode_ind_fmt:   .byte "($**)",0
mode_abs_fmt:   .byte "$**",0
mode_rel_fmt:   .byte "$*",0
mode_aby_fmt:   .byte "$**,y",0
mode_abx_fmt:   .byte "$**,x",0
mode_zp_fmt:    .byte "$*",0
mode_impl_fmt:  .byte "",0
mode_zrel_fmt:  .byte "$*,$*",0