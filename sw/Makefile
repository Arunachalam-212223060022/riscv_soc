CROSS = riscv64-unknown-elf
CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -T link.ld

all:
	$(CROSS)-gcc $(CFLAGS) -o demo.elf demo.S
	$(CROSS)-objcopy -O binary demo.elf demo.bin
	python3 bin2mem.py demo.bin program.mem
	cp program.mem ~/riscv_soc/rtl/memory/program.mem

clean:
	rm -f *.elf *.bin *.mem
