#include <string.h>

#include "shared.h"

extern void EmuLog_Char(__reg("d0") unsigned char c);
extern void EmuLog_String(__reg("a0") char *str);
