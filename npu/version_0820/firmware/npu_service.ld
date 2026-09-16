OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    FIRMWARE (rx) : ORIGIN = 0x80000000, LENGTH = 0x1000
}

SECTIONS
{
    . = ORIGIN(FIRMWARE);

    .text : ALIGN(8)
    {
        KEEP(*(.text.entry))
        *(.text .text.*)
    } > FIRMWARE

    .rodata : ALIGN(8)
    {
        *(.rodata .rodata.*)
    } > FIRMWARE

    .data : ALIGN(8)
    {
        *(.data .data.*)
    } > FIRMWARE

    . = ALIGN(8);
    __npu_service_image_end = .;

    ASSERT(_start == ORIGIN(FIRMWARE),
           "RV64 service firmware entry must remain 0x80000000")
    ASSERT(__npu_service_image_end <= ORIGIN(FIRMWARE) + LENGTH(FIRMWARE),
           "RV64 service firmware exceeds its 4 KiB instruction aperture")

    /DISCARD/ :
    {
        *(.comment)
        *(.note .note.*)
        *(.eh_frame .eh_frame.*)
    }
}
