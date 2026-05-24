YSYXSOC_SRAM_BASE = 0x0f000000;
YSYXSOC_SRAM_SIZE = 0x00002000;
YSYXSOC_MROM_BASE = 0x20000000;
YSYXSOC_MROM_SIZE = 0x00001000;
YSYXSOC_STACK_SIZE = 0x00001000;

ENTRY(_start)

SECTIONS {
  . = YSYXSOC_MROM_BASE;

  .text : {
    KEEP(*(entry))
    *(.text*)
  }
  etext = .;
  _etext = .;

  .rodata : {
    *(.rodata*)
    *(.srodata*)
  }

  . = ALIGN(4);
  _data_load = .;

  .data YSYXSOC_SRAM_BASE : AT(_data_load) {
    _data_start = .;
    *(.data*)
    *(.sdata*)
    . = ALIGN(4);
    _data_end = .;
  }
  edata = _data_end;
  _data = _data_start;

  .bss (NOLOAD) : {
    . = ALIGN(4);
    _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    . = ALIGN(4);
    _bss_end = .;
  }

  _data_load_end = _data_load + SIZEOF(.data);
  _mrom_image_end = _data_load_end;

  . = ALIGN(16);
  end = .;
  _end = .;
  _heap_start = .;
  _stack_top = YSYXSOC_SRAM_BASE + YSYXSOC_SRAM_SIZE;
  _stack_pointer = _stack_top;
  _stack_bottom = _stack_top - YSYXSOC_STACK_SIZE;
  _heap_end = _stack_bottom;
}

ASSERT(_mrom_image_end <= YSYXSOC_MROM_BASE + YSYXSOC_MROM_SIZE, "ysyxsoc MROM image overflow")
ASSERT(_end <= _heap_end, "ysyxsoc SRAM data/bss/stack overflow")
ASSERT(_heap_start <= _heap_end, "ysyxsoc SRAM stack/heap overflow")
