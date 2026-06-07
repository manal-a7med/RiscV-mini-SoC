OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
    /* 4KB Instruction Memory at 0x0 */
    FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 1K
    /* 4KB Data Memory at 0x10000 */
    RAM (rwx)  : ORIGIN = 0x00010000, LENGTH = 1K
}

SECTIONS
{
    .text : {
        *(.text*)
    } > FLASH

    .rodata : {
        *(.rodata*)
    } > FLASH

    .data : {
        *(.data*)
    } > RAM AT > FLASH

/* # The .bss section is for uninitialized data. It should be placed in RAM, but it doesn't need to be stored in the binary since it will be zero-initialized at runtime.
# AT > FLASH CAN BE REMOVED AS I have no ROM/RAM split in a simulation-only flow.
# note : The linker.ld .data VMA/LMA split requires a startup copy loop that boot.S doesn't have — harmless now but 
will silently break any future global variable initialisation */

    .bss : {
        *(.bss*)
        *(COMMON)
    } > RAM
    PROVIDE(_stack_top = ORIGIN(RAM) + LENGTH(RAM));

}
