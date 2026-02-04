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

    .bss : {
        *(.bss*)
        *(COMMON)
    } > RAM
    PROVIDE(_stack_top = ORIGIN(RAM) + LENGTH(RAM));

}
