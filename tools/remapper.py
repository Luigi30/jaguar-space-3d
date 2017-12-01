import struct

palette_entries = []

def parse_line(line):
    if "dc.w" in line:
        splitLine = line.rstrip("\r\n").split('\t')
        for word in splitLine:
            if "$" in word and word != "$0000":
                splitWord = word.split(' ')
                palette_entries.append(splitWord)

def triple_to_rgb16(r, g, b):
    return ((r & 0xf8) << 8) | ((b & 0xf8) << 3) | ((g & 0xfc) >> 2)
                
def main():
#    shapes_palette = open("../images/tyrian_shp_rgb_pal.s")

#    for line in shapes_palette:
#        parse_line(line)

    shapes_palette = open("../images/shapes.pal")
    for line in shapes_palette:
        colors = line.split(" ")
        palette_entries.append(triple_to_rgb16(int(colors[0]), int(colors[1]), int(colors[2])))

    print "File palette is: "
    print [x for x in palette_entries]

    vga_palette_file = open("../data/palette.dat", "rb")
    vga_palette_file.seek(3)

    for palette_num in xrange(0, 22):
        vga_palette = []
    
        for i in xrange(0, 256):
            vga_colors = struct.unpack('BBB', vga_palette_file.read(3))
            rgbvalue = triple_to_rgb16(int(vga_colors[0]), int(vga_colors[1]), int(vga_colors[2]))
            vga_palette.append(rgbvalue)
            #print "Color: {0:02X} {1:02X} {2:02X} -> {3:04X}".format(colors[0], colors[1], colors[2], rgbvalue)

            #print vga_palette

        common = len([x for x in vga_palette if x in palette_entries])
        print "Common elements in file and palette {0}: {1} ".format(palette_num, common)

main()
