OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
  . = 0x80400000;
  .text : ALIGN(16) {
    *(.text.start)
    *(.text .text.*)
  }
  .user : ALIGN(4096) {
    *(.user)
  }
  .rodata : ALIGN(16) {
    *(.rodata .rodata.*)
  }
  .data : ALIGN(4096) {
    *(.data .data.*)
  }
  .bss (NOLOAD) : ALIGN(4096) {
    __bss_start = .;
    *(.bss .bss.* COMMON)
    __bss_end = .;
  }
  /DISCARD/ : {
    *(.comment .note .note.* .eh_frame .eh_frame_hdr)
  }
}
