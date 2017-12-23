#include "log.h"

void EmuLog_String(char *str){
  for(int i=0;i<strlen(str);i++)
    WriteEmuLog(str[i]);
}
