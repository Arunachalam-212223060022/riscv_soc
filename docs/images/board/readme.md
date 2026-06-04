# RISC-V RV32I SoC — Hardware Demo on Digilent Spartan-7 Boolean Board

The following images document the live hardware validation of the RISC-V SoC. After programming the bitstream (`soc_top_demo.bit`) onto the **Xilinx XC7S50CSGA324-1** FPGA, the embedded assembly program (`demo.S`) executes continuously — reading the slide switch states via the **GPIO peripheral**, mirroring them to the LEDs, and writing the switch binary value to the **7-segment display controller**. Each photo captures a different switch configuration, proving that the CPU, memory bus, GPIO, and Seg7 peripheral are all functioning correctly in real silicon.

---

## Image 1 — Board Power-On, All Switches Low


<img width="1280" height="951" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM" src="https://github.com/user-attachments/assets/7dfee9ad-7b99-4af7-9926-06878843caee" />


The Boolean board is powered on for the first time with all slide switches (SW0–SW7) in the LOW position. The RISC-V CPU has booted, executed the UART startup message (`"RISCV SOC OK\r\n"`), and entered the main loop. The 7-segment displays show the initial hex value corresponding to all switches being off. Only the power LED and the DONE indicator are lit, confirming that the FPGA bitstream has been loaded and the design is running.

---

## Image 2 — GPIO Mirror: Single Switch Toggled

<img width="1280" height="973" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (1)" src="https://github.com/user-attachments/assets/185fcf12-7c7e-4c7a-ba7c-717bb3d78995" />




One slide switch has been flipped HIGH. The RISC-V CPU reads the `GPIO_IN` register (memory address `0x20000004`), and the corresponding LED lights up — confirming that the `lw` (load word) and `sw` (store word) instructions through the memory-mapped GPIO peripheral are working correctly. The 7-segment display updates to reflect the new 1-bit switch value.

---

## Image 3 — Multiple Switches Active, LEDs and Seg7 Updating


<img width="1280" height="1039" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (2)" src="https://github.com/user-attachments/assets/944b15da-52df-41c7-82ca-9f335da4a744" />

Several switches are toggled ON simultaneously. The CPU's main loop reads the full 8-bit switch bus, writes it to `GPIO_OUT` (address `0x20000000`) to drive the LEDs, and writes the same value to the 7-segment display base address. The RGB LED on the right side of the board also glows, showing that multiple output registers are being driven. This confirms correct multi-bit data path operation through the SoC bus.

---

## Image 4 — Higher Switch Pattern, LED Row Lights Up


<img width="1280" height="962" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (3)" src="https://github.com/user-attachments/assets/2d96e2dc-c027-4c03-ab01-72d8321b18a5" />



A different combination of switches is active, producing a new LED pattern across the LD0–LD15 row. The 7-segment display reflects the updated binary value. The blue ambient glow from the RGB LEDs on the right confirms that the GPIO output register write is reaching multiple peripheral outputs each loop iteration, demonstrating the bus decode logic and combinational address multiplexer working in real time.

---

## Image 5 — All Switch Bits Changing, Full Display Update


<img width="1280" height="955" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (4)" src="https://github.com/user-attachments/assets/911fe4e3-40c3-44fd-85ca-b23f97d88685" />



More switches are pushed to the HIGH position. The LED row now shows a wider lit pattern, and the 7-segment display advances to a higher hex value. This image demonstrates that all eight GPIO input bits are being correctly captured by the CPU's `lw` instruction and propagated through the write-back path to both output peripherals simultaneously, validating multi-peripheral write in a single instruction loop.

---

## Image 6 — Nearly All Switches ON




<img width="1280" height="1019" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (5)" src="https://github.com/user-attachments/assets/963be9f5-cd4b-4f4f-9023-5f5073c2dc6e" />


Almost all slide switches are in the HIGH position. The LEDs across the full LD row are illuminated, and the 7-segment display shows a near-maximum hex value. The blue glow of the RGB LEDs is visible. This state exercises the full 8-bit width of the `GPIO_OUT` register, confirming that all byte lanes of the memory bus are functional and that the SoC correctly handles writes where all data bits are set.

---

## Image 7 — Switch Pattern: Single High Bit Isolated



<img width="1280" height="975" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (6)" src="https://github.com/user-attachments/assets/c5e55ca1-9a3f-411a-8a93-a2d8d782ffe7" />


The switches are set so that only one specific bit in the middle of the switch bank is HIGH. The corresponding single LED lights up precisely in the right position, and the 7-segment display reflects the isolated bit value. This confirms bit-accurate GPIO input reading — the CPU correctly isolates individual bits from the 32-bit `GPIO_IN` data bus read and mirrors them to the correct output pins.

---

## Image 8 — Green LED Bank Fully Lit




<img width="1280" height="910" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (7)" src="https://github.com/user-attachments/assets/a2f9a9a6-df6f-442d-98da-effefd23e7e6" />


With the switches producing a particular pattern, the entire right-side green LED bank is illuminated, creating a striking visual. The 7-segment display continues to track the switch value correctly. The UART TX/RX LEDs near the top of the board show activity, confirming that the UART peripheral successfully transmitted the boot message (`"RISCV SOC OK\r\n"`) at 115200 baud before the GPIO mirror loop began.

---

## Image 9 — Red RGB and Green LEDs Active Together



<img width="1280" height="920" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (8)" src="https://github.com/user-attachments/assets/420e1849-0913-42bb-834d-e9077551021c" />


A switch combination activates both the red RGB LED and green output LEDs simultaneously, creating a vivid multi-colour display. The 7-segment display shows a mid-range hex value matching the current switch state. This image highlights that the SoC's CPU is running at 12 MHz on the FPGA, completing the full read-GPIO → write-GPIO → write-Seg7 loop fast enough to respond to user input with zero perceptible delay.

---

## Image 10 — Final State: Varied Switch Configuration



<img width="1280" height="1007" alt="WhatsApp Image 2026-06-04 at 8 57 59 AM (9)" src="https://github.com/user-attachments/assets/9c47ce2f-37a4-490a-9982-fbceec733550" />

The final captured state shows a varied mix of switches ON and OFF, with the corresponding LED pattern and 7-segment display value in agreement. The blue ambient glow and DONE LED confirm the design is still running stably. Across all ten photographs, every switch toggle produced the correct, immediate response in both the LED array and the 7-segment display — confirming full end-to-end hardware validation of the RISC-V SoC: from the CPU executing assembly instructions, through the memory-mapped bus, to the GPIO and Seg7 peripheral outputs.

---

> **Platform:** Digilent Spartan-7 Boolean Board (Xilinx XC7S50CSGA324-1)  
> **Bitstream:** `fpga/bitstream/soc_top_demo.bit`  
> **Demo Program:** `sw/demo.S` — GPIO mirror loop + UART boot message  
> **FPGA Power:** 68 mW total on-chip power (Vivado 2023.1)
