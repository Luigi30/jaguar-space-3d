#include "gfx/palette.h"

Palette *jaguar_palettes;
char skunkout[256];

void PALETTES_initialize()
{
	uint32_t color_count = (long)(vga_palettes_end - vga_palettes) / 3;
	
	sprintf(skunkout, "%d colors in palette data corresponding to %d palettes\n", color_count, color_count/256);
	skunkCONSOLEWRITE(skunkout);
	
	jaguar_palettes = malloc(32768);
	
	uint16_t current = 0;
	
	for(int palette=0; palette < (color_count / 256); palette++){		
		//sprintf(skunkout, "Loading palette %u\n", palette);
		//skunkCONSOLEWRITE(skunkout);
		
		for(int i=0; i<256; i++){
			jaguar_palettes[palette].colors[i].r = (vga_palettes[current] << 2);
			current++;
			jaguar_palettes[palette].colors[i].g = (vga_palettes[current] << 2);
			current++;
			jaguar_palettes[palette].colors[i].b = (vga_palettes[current] << 2);
			current++;
		}
		
		PaletteCount++;
	}
}

void PALETTES_select(uint8_t palette_num)
{
	sprintf(skunkout, "Selecting palette %ud", palette_num);
	skunkCONSOLEWRITE(skunkout);
	
	Palette pal = jaguar_palettes[palette_num];
	
	sprintf(skunkout, "%02X %02X %02X %02X %02X %02X\n", pal.colors[0].r, pal.colors[0].g, pal.colors[0].b, pal.colors[1].r, pal.colors[1].g, pal.colors[1].b);
	skunkCONSOLEWRITE(skunkout);
	
	//Load one of the palettes into the CLUT.
	for(int i=0; i<256; i++)
	{
		RGBColor color = pal.colors[i];
		jag_set_indexed_color(i, toRgb16(color.r, color.g, color.b));
	}
}

void PALETTES_load_from_array(uint16_t *colordata)
{
	for(int i=0;i<256;i++)
	{
		jag_set_indexed_color(i, colordata[i]);
	}
}
