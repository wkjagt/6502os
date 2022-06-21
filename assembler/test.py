from py65.devices.mpu65c02 import MPU

def test(mpu, rom, case):
    f = open(rom, 'rb')
    bytes = f.read()
    start_address = mpu.addrMask - len(bytes) + 1
    bytes = [ b for b in bytes ]  # make list

    # fill memory
    address = start_address
    length, index = len(bytes), 0
    end = start_address + length - 1

    while address <= end:
        mpu.memory[address] = bytes[index]
        index += 1
        if index == length:
            index = 0
        address += 1

    case_address = 0x8000
    case_end_address = 0x8000 + len(case)
    index = 0
    
    case = str.encode(case)
    while case_address < case_end_address:
        mpu.memory[case_address] = case[index]
        index += 1
        case_address += 1

    reset = mpu.RESET
    dest = mpu.memory[reset] + (mpu.memory[reset + 1] << 8)
    mpu.pc = dest

    while True:
        mpu.step()
        if mpu.memory[mpu.pc] == 0: # BRK opcode
            break


test_cases = [
    ('BRK', '$00', 0),
    ('ORA ($F3,x)', '$01', 1),
    ('ORA $F3', '$05', 5),
    ('ORA #$F3', '$09', 9),
    ('ORA $F3F3', '$0D', 13),
    ('ORA ($F3),y', '$11', 17),
    ('ORA ($F3)', '$12', 18),
    ('ORA $F3,x', '$15', 21),
    ('ORA $F3F3,y', '$19', 25),
    ('ORA $F3F3,x', '$1D', 29),
    ('TSB $F3', '$04', 4),
    ('TSB $F3F3', '$0C', 12),
    ('ASL $F3', '$06', 6),
    ('ASL', '$0A', 10),
    ('ASL $F3F3', '$0E', 14),
    ('ASL $F3,x', '$16', 22),
    ('ASL $F3F3,x', '$1E', 30),
    ('PHP', '$08', 8),
    ('BPL', '$10', 16),
    ('TRB $F3', '$14', 20),
    ('TRB $F3F3', '$1C', 28),
    ('CLC', '$18', 24),
    ('INC', '$1A', 26),
    ('INC $F3', '$E6', 230),
    ('INC $F3F3', '$EE', 238),
    ('INC $F3,x', '$F6', 246),
    ('INC $F3F3,x', '$FE', 254),
    ('JSR $F3F3', '$20', 32),
    ('AND ($F3,x)', '$21', 33),
    ('AND $F3', '$25', 37),
    ('AND #$F3', '$29', 41),
    ('AND $F3F3', '$2D', 45),
    ('AND ($F3),y', '$31', 49),
    ('AND ($F3)', '$32', 50),
    ('AND $F3,x', '$35', 53),
    ('AND $F3F3,y', '$39', 57),
    ('AND $F3F3,x', '$3D', 61),
    ('BIT $F3', '$24', 36),
    ('BIT $F3F3', '$2C', 44),
    ('BIT $F3,x', '$34', 52),
    ('BIT $F3F3,x', '$3C', 60),
    ('BIT #$F3', '$89', 137),
    ('ROL $F3', '$26', 38),
    ('ROL', '$2A', 42),
    ('ROL $F3F3', '$2E', 46),
    ('ROL $F3,x', '$36', 54),
    ('ROL $F3F3,x', '$3E', 62),
    ('PLP', '$28', 40),
    ('BMI', '$30', 48),
    ('SEC', '$38', 56),
    ('DEC', '$3A', 58),
    ('DEC $F3', '$C6', 198),
    ('DEC $F3F3', '$CE', 206),
    ('DEC $F3,x', '$D6', 214),
    ('DEC $F3F3,x', '$DE', 222),
    ('RTI', '$40', 64),
    ('EOR ($F3,x)', '$41', 65),
    ('EOR $F3', '$45', 69),
    ('EOR #$F3', '$49', 73),
    ('EOR $F3F3', '$4D', 77),
    ('EOR ($F3),y', '$51', 81),
    ('EOR ($F3)', '$52', 82),
    ('EOR $F3,x', '$55', 85),
    ('EOR $F3F3,y', '$59', 89),
    ('EOR $F3F3,x', '$5D', 93),
    ('LSR $F3', '$46', 70),
    ('LSR', '$4A', 74),
    ('LSR $F3F3', '$4E', 78),
    ('LSR $F3,x', '$56', 86),
    ('LSR $F3F3,x', '$5E', 94),
    ('PHA', '$48', 72),
    ('JMP $F3F3', '$4C', 76),
    ('JMP ($F3F3)', '$6C', 108),
    ('JMP ($F3F3,x)', '$7C', 124),
    ('BVC', '$50', 80),
    ('CLI', '$58', 88),
    ('PHY', '$5A', 90),
    ('RTS', '$60', 96),
    ('ADC ($F3,x)', '$61', 97),
    ('ADC $F3', '$65', 101),
    ('ADC #$F3', '$69', 105),
    ('ADC $F3F3', '$6D', 109),
    ('ADC ($F3),y', '$71', 113),
    ('ADC ($F3)', '$72', 114),
    ('ADC $F3,x', '$75', 117),
    ('ADC $F3F3,y', '$79', 121),
    ('ADC $F3F3,x', '$7D', 125),
    ('STZ $F3', '$64', 100),
    ('STZ $F3,x', '$74', 116),
    ('STZ $F3F3', '$9C', 156),
    ('STZ $F3F3,x', '$9E', 158),
    ('ROR $F3', '$66', 102),
    ('ROR', '$6A', 106),
    ('ROR $F3F3', '$6E', 110),
    ('ROR $F3,x', '$76', 118),
    ('ROR $F3F3,x', '$7E', 126),
    ('PLA', '$68', 104),
    ('BVS', '$70', 112),
    ('SEI', '$78', 120),
    ('PLY', '$7A', 122),
    ('BRA', '$80', 128),
    ('STA ($F3,x)', '$81', 129),
    ('STA $F3', '$85', 133),
    ('STA $F3F3', '$8D', 141),
    ('STA ($F3),y', '$91', 145),
    ('STA ($F3)', '$92', 146),
    ('STA $F3,x', '$95', 149),
    ('STA $F3F3,y', '$99', 153),
    ('STA $F3F3,x', '$9D', 157),
    ('STY $F3', '$84', 132),
    ('STY $F3F3', '$8C', 140),
    ('STY $F3,x', '$94', 148),
    ('STX $F3', '$86', 134),
    ('STX $F3F3', '$8E', 142),
    ('STX $F3,y', '$96', 150),
    ('DEY', '$88', 136),
    ('TXA', '$8A', 138),
    ('BCC', '$90', 144),
    ('TYA', '$98', 152),
    ('TXS', '$9A', 154),
    ('LDY #$F3', '$A0', 160),
    ('LDY $F3', '$A4', 164),
    ('LDY $F3F3', '$AC', 172),
    ('LDY $F3,x', '$B4', 180),
    ('LDY $F3F3,x', '$BC', 188),
    ('LDA ($F3,x)', '$A1', 161),
    ('LDA $F3', '$A5', 165),
    ('LDA #$F3', '$A9', 169),
    ('LDA $F3F3', '$AD', 173),
    ('LDA ($F3),y', '$B1', 177),
    ('LDA ($F3)', '$B2', 178),
    ('LDA $F3,x', '$B5', 181),
    ('LDA $F3F3,y', '$B9', 185),
    ('LDA $F3F3,x', '$BD', 189),
    ('LDX #$F3', '$A2', 162),
    ('LDX $F3', '$A6', 166),
    ('LDX $F3F3', '$AE', 174),
    ('LDX $F3,y', '$B6', 182),
    ('LDX $F3F3,y', '$BE', 190),
    ('TAY', '$A8', 168),
    ('TAX', '$AA', 170),
    ('BCS', '$B0', 176),
    ('CLV', '$B8', 184),
    ('TSX', '$BA', 186),
    ('CPY #$F3', '$C0', 192),
    ('CPY $F3', '$C4', 196),
    ('CPY $F3F3', '$CC', 204),
    ('CMP ($F3,x)', '$C1', 193),
    ('CMP $F3', '$C5', 197),
    ('CMP #$F3', '$C9', 201),
    ('CMP $F3F3', '$CD', 205),
    ('CMP ($F3),y', '$D1', 209),
    ('CMP ($F3)', '$D2', 210),
    ('CMP $F3,x', '$D5', 213),
    ('CMP $F3F3,y', '$D9', 217),
    ('CMP $F3F3,x', '$DD', 221),
    ('INY', '$C8', 200),
    ('DEX', '$CA', 202),
    ('BNE', '$D0', 208),
    ('CLD', '$D8', 216),
    ('PHX', '$DA', 218),
    ('CPX #$F3', '$E0', 224),
    ('CPX $F3', '$E4', 228),
    ('CPX $F3F3', '$EC', 236),
    ('SBC ($F3,x)', '$E1', 225),
    ('SBC $F3', '$E5', 229),
    ('SBC #$F3', '$E9', 233),
    ('SBC $F3F3', '$ED', 237),
    ('SBC ($F3),y', '$F1', 241),
    ('SBC ($F3)', '$F2', 242),
    ('SBC $F3,x', '$F5', 245),
    ('SBC $F3F3,y', '$F9', 249),
    ('SBC $F3F3,x', '$FD', 253),
    ('INX', '$E8', 232),
    ('NOP', '$EA', 234),
    ('BEQ', '$F0', 240),
    ('SED', '$F8', 248),
    ('PLX', '$FA', 250),
]

succeed_count = 0
for case in test_cases:
    mpu = MPU()
    test(
        mpu,
        "../../6502/tmp/test.rom",
        case[0]
    )
    found_opcode = mpu.memory[0x44]
    expected_opcode = case[2]

    if found_opcode != expected_opcode:
        print("Fail: " + case[0] + ", expected: " + case[1] + ", actual: " + "$%x" % found_opcode)
    else:
        succeed_count +=1

print("Passed: " + str(succeed_count) + "/" + str(len(test_cases)))