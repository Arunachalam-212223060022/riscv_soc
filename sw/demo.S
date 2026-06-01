.section .text
.global _start
_start:
    # ── Base addresses ──────────────────────
    li t0, 0x10000000   # UART base
    li t1, 0x20000000   # GPIO base
    li t2, 0x20000100   # SEG7

    # ── Print "RISCV SOC OK\r\n" ────────────
    la a0, msg
print_loop:
    lb a1, 0(a0)
    beqz a1, main_loop
wait_tx:
    lw a2, 4(t0)        # read UART status
    andi a2, a2, 1
    bnez a2, wait_tx    # wait if tx_busy
    sw a1, 0(t0)        # send byte
    addi a0, a0, 1
    j print_loop

    # ── Main loop: switches→LEDs, switches→SEG7 ──
main_loop:
    lw a0, 4(t1)        # read GPIO_IN (switches)
    sw a0, 0(t1)        # write GPIO_OUT (LEDs)
    sw a0, 0(t2)        # write SEG7
    j main_loop

.section .rodata
msg:
    .string "RISCV SOC OK\r\n"
