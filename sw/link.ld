MEMORY {
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 8K
    DMEM (rw) : ORIGIN = 0x00002000, LENGTH = 8K
}
SECTIONS {
    .text : { *(.text) } > IMEM
    .rodata : { *(.rodata) } > IMEM
    .data : { *(.data) } > DMEM
    .bss  : { *(.bss)  } > DMEM
}
