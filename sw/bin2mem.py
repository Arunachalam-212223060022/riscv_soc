import sys, struct
with open(sys.argv[1],'rb') as f: data = f.read()
data += b'\x00' * ((4 - len(data)%4)%4)
with open(sys.argv[2],'w') as f:
    for i in range(0, len(data), 4):
        f.write(f"{struct.unpack_from('<I',data,i)[0]:08x}\n")
