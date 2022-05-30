header_lines = []

def parse_line(line):
    _, addr, label = line.split()
    label = label.lstrip(".")
    addr = addr.lstrip("0")
    if len(addr) > 2:
        addr = addr.zfill(4)
    else:
        addr = addr.zfill(2)
    addr = "$" + addr
    header_lines.append(label + " = " + addr)

    
with open('./build/pager_os/pager_os.vice') as vice_file:
    file_contents = vice_file.read()
    for line in file_contents.splitlines():
        parse_line(line)

with open('./build/pager_os/pager_os.inc', 'w') as header_file:
    header_file.write("\n".join(header_lines))
    header_file.close()
