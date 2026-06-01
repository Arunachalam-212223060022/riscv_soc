// RTL filelist for VCS / NCLaunch simulation
// Usage: vcs -f sim/filelist/rtl.f -f sim/filelist/tb.f

// CPU core
rtl/cpu/pc.v
rtl/cpu/regfile.v
rtl/cpu/immgen.v
rtl/cpu/control.v
rtl/cpu/alu_ctrl.v
rtl/cpu/alu.v
rtl/cpu/cpu_top.v

// Memory
rtl/memory/imem.v
rtl/memory/dmem.v

// Peripherals
rtl/peripheral/uart.v
rtl/peripheral/gpio.v
rtl/peripheral/timer.v
rtl/peripheral/intc.v
rtl/peripheral/spi.v
rtl/peripheral/i2c.v
rtl/peripheral/seg7_ctrl.v

// Top-level
rtl/soc_top.v
