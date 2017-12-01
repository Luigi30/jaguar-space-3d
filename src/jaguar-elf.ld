/* Memory description */
MEMORY
{
	ram: org = 0x4000 , len = 0x1FC000							/* Jaguar RAM information */
}

SECTIONS {
    . = 0x4000;
    .text: {
      *(.text CODE code)
    }
	
    . = ALIGN(32);
    .data: {
      VBCC_CONSTRUCTORS
      *(.data DATA data)
      . = ALIGN(0x1000);
      *(.SPRITES)
    }
	
    . = ALIGN(32);
    .bss: {
      *(.bss BSS bss)
      *(COMMON)
      _BSS_END = ALIGN(32);
    }
	
    . = ALIGN(32);
    .gpucode 0xF03000: AT ( ADDR(.text) + SIZEOF(.text) )
    {
	*(.gpucode CODE gpucode)
    }
	
    . = ALIGN(32);
    .dspcode 0xF1B000: AT ( ADDR(.dspcode) + SIZEOF(.dspcode) )
    {
	*(.dspcode CODE dspcode)
    }
	
	.heap:
	{
		PROVIDE(__HeapBase = ALIGN(2));							/* M68000 preference alignement */
		*(.heap HEAP);
	}

	.stack:
	{
		PROVIDE(__Stack = 0x1FFFFC);
	}
	
	/* DWARF debug sections. */
	/* Symbols in the DWARF debugging sections are relative to the beginning of the section so we begin them at 0. */
	/* DWARF 1 */
	.debug 0:
	{
		*(.debug)
	}
	.line 0:
	{
		*(.line)
	}
	/* GNU DWARF 1 extensions */
	.debug_srcinfo 0:
	{
		*(.debug_srcinfo)
	}
	.debug_sfnames 0:
	{
		*(.debug_sfnames)
	}
	/* DWARF 1.1 and DWARF 2 */
	.debug_aranges 0:
	{
		*(.debug_aranges)
	}
	.debug_pubnames 0:
	{
		*(.debug_pubnames)
	}
	/* DWARF 2 */
	.debug_info 0:
	{
		*(.debug_info .gnu.linkonce.wi.*)
	}
	.debug_abbrev 0:
	{
		*(.debug_abbrev)
	}
	.debug_line 0:
	{
		*(.debug_line)
	}
	.debug_frame 0:
	{
		*(.debug_frame)
	}
	.debug_str 0:
	{
		*(.debug_str)					/* String table used in .debug_info */
	}
	.debug_loc 0:
	{
		*(.debug_loc)					/* Location lists used in the DW_AT_location attributes */
	}
	.debug_macinfo 0:
	{
		*(.debug_macinfo)				/* Macro information */
	}
	.comment 0:
	{
		*(.comment)						/* ? */
	}
  };
