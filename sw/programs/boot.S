.section .text
.global _start

_start:
    # 1. Initialize Stack Pointer (sp)
    # Correct Stack Pointer for 1KB RAM (Origin + 1024)
    li sp, 0x00010400

    # 2. Clear BSS (optional but good practice)
    # 3. Jump to main
    jal ra, main

    # 4. If main ever returns, trap the CPU in a loop
_hang:
    j _hang

    