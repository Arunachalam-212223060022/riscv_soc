#!/bin/bash
set -e

RTL="../rtl/cpu/pc.v
     ../rtl/cpu/regfile.v
     ../rtl/cpu/immgen.v
     ../rtl/cpu/control.v
     ../rtl/cpu/alu_ctrl.v
     ../rtl/cpu/alu.v
     ../rtl/cpu/cpu_top.v
     ../rtl/memory/imem.v
     ../rtl/memory/dmem.v
     ../rtl/peripheral/uart.v
     ../rtl/peripheral/gpio.v
     ../rtl/peripheral/timer.v
     ../rtl/peripheral/intc.v
     ../rtl/soc_top.v"

run_tb() {
    TB=$1
    NAME=$2
    echo ""
    echo "===== $NAME ====="
    vcs -full64 -sverilog -q +define+SIMULATION \
        $RTL ../tb/${TB}.sv -o simv_${TB} -l compile_${TB}.log
    ./simv_${TB} -l sim_${TB}.log
    cat sim_${TB}.log | grep -E "PASS|FAIL|ALL"
}

run_tb tb_alu       "ALU"
run_tb tb_regfile   "REGISTER FILE"
run_tb tb_immgen    "IMMEDIATE GEN"
run_tb tb_control   "CONTROL UNIT"
run_tb tb_uart      "UART"
run_tb tb_gpio      "GPIO"
run_tb tb_timer     "TIMER"
run_tb tb_intc      "INTC"
run_tb tb_cpu_top   "CPU TOP"
run_tb tb_soc_top   "SOC TOP"

echo ""
echo "===== ALL SIMULATIONS COMPLETE ====="
