#include <string.h>

extern void WriteEmuLog(__reg("d0") unsigned char c);
void EmuLog_String(char *str);
