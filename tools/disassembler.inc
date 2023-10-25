.globalzp code_pointer
.global find_instruction
.global print_instruction
.global addressing_modes
.global addr_mode

MN_DEX = 0
MN_DEY = 1 
MN_TAX = 2
MN_TSB = 3
MN_BPL = 4
MN_BCC = 5
MN_CPX = 6
MN_EOR = 7
MN_TSX = 8
MN_DEC = 9
MN_STA = 10
MN_LDA = 11
MN_BEQ = 12
MN_ROL = 13
MN_STY = 14
MN_JMP = 15
MN_BMI = 16
MN_RTI = 17
MN_TAY = 18
MN_TXA = 19
MN_RTS = 20
MN_SED = 21
MN_LSR = 22
MN_BNE = 23
MN_JSR = 24
MN_LDY = 25
MN_SEC = 26
MN_BIT = 27
MN_LDX = 28
MN_TXS = 29
MN_SEI = 30
MN_ASL = 31
MN_BVS = 32
MN_CPY = 33
MN_CLI = 34
MN_CLD = 35
MN_TRB = 36
MN_CLC = 37
MN_BCS = 38
MN_ADC = 39
MN_CLV = 40
MN_STX = 41
MN_ROR = 42
MN_STZ = 43
MN_AND = 44
MN_PHP = 45
MN_INX = 46
MN_INY = 47
MN_PLP = 48
MN_PHA = 49
MN_CMP = 50
MN_TYA = 51
MN_PLY = 52
MN_PLX = 53
MN_BVC = 54
MN_SBC = 55
MN_PHY = 56
MN_PHX = 57
MN_BRK = 58
MN_PLA = 59
MN_INC = 60
MN_NOP = 61
MN_BRA = 62
MN_ORA = 63
MN_BBR0 = 64
MN_BBR1 = 65
MN_BBR2 = 66
MN_BBR3 = 67
MN_BBR4 = 68
MN_BBR5 = 69
MN_BBR6 = 70
MN_BBR7 = 71
MN_BBS0 = 72
MN_BBS1 = 73
MN_BBS2 = 74
MN_BBS3 = 75
MN_BBS4 = 76
MN_BBS5 = 77
MN_BBS6 = 78
MN_BBS7 = 79
MN_RMB0 = 80
MN_RMB1 = 81
MN_RMB2 = 82
MN_RMB3 = 83
MN_RMB4 = 84
MN_RMB5 = 85
MN_RMB6 = 86
MN_RMB7 = 87
MN_SMB0 = 88
MN_SMB1 = 89
MN_SMB2 = 90
MN_SMB3 = 91
MN_SMB4 = 92
MN_SMB5 = 93
MN_SMB6 = 94
MN_SMB7 = 95
MN_WAI  = 96
MN_STP  = 97

MODE_IAX  = 0 * 2
MODE_IZP  = 1 * 2
MODE_ZPX  = 2 * 2
MODE_ZPY  = 3 * 2
MODE_IZX  = 4 * 2
MODE_IMM  = 5 * 2
MODE_IZY  = 6 * 2
MODE_IND  = 7 * 2
MODE_ABS  = 8 * 2
MODE_REL  = 9 * 2
MODE_ABY  = 10 * 2
MODE_ABX  = 11 * 2
MODE_ZP   = 12 * 2
MODE_IMPL = 13 * 2
MODE_ZREL = 14 * 2      ; used by bbr and bbs

        .macro  inc16   addr
                clc
                lda     addr
                adc     #1
                sta     addr
                lda     addr+1
                adc     #0
                sta     addr+1
        .endmacro

        .macro  dec16   addr
                lda addr
                bne :+
                dec addr+1
:               dec addr
        .endmacro