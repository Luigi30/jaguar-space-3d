#include "fixed.h"
#include "log.h"

char fx_temp_out[32];

FIXED_32 FIXED_ADD(FIXED_32 a, FIXED_32 b) { return a+b; }
FIXED_32 FIXED_SUB(FIXED_32 a, FIXED_32 b) { return a-b; }

FIXED_32 FIXED_MUL(FIXED_32 a, FIXED_32 b)
{
	FIXED_32 result = 0;
	uint64_t temp, long_a, long_b;
	
	long_a = 0;
	long_b = 0;
	
	if(a & 0x80000000) {
		long_a = 0xFFFFFFFF00000000;
	}
	if(b & 0x80000000)
	{
		long_b = 0xFFFFFFFF00000000;
	}
	
	long_a |= a;
	long_b |= b;
	
	temp = long_a*long_b;
	result = temp >> 16;
	
	//printf("a: %016llX\n", long_a);
	//printf("b: %016llX\n", long_b);
	//result = (a*b) >> 16;
	//printf("result: %016X\n", result);
	return result;
}

FIXED_32 FIXED_DIV(const FIXED_32 a, const FIXED_32 b)
{
	if(b == 0){
	        EmuLog_String("FIXED_DIV by 0!\n");
	}
	
	uint64_t result;
	int64_t long_a = 0;
	int64_t long_b = 0;
	
	if(a & 0x80000000)
	{
		long_a = 0xFFFFFFFF00000000;
	}
	if(b & 0x80000000)
	{
		long_b = 0xFFFFFFFF00000000;
	}
	
	long_a |= a;
	long_b |= b;
	
	return ((long_a * 65536) / long_b);
  
  /*
  FIXED_32 result;
  uint64_t temp;

  if(b != 0) {
    temp = ((uint64_t)a << 16) / ((uint64_t)b);
    result = temp; //reduce back to a uint32                                                                                                         
  }
  else {
    skunkCONSOLEWRITE("Fixed-point division by zero!\n");
    while(true) {};
  }

  return result;
  */
}

inline FIXED_32 FIXED_ABS(FIXED_32 a)
{
	return a & 0x7FFFFFFF;
}

#define FX_PRINTF_IDENTIFIER "%5ld.%u"
//#define FX_PRINTF_ARGUMENTS (int32_t)FIXED_INT(val), (uint16_t)((FIXED_FRAC(val) / 65536.0) * 10000)
#define FX_PRINTF_ARGUMENTS (int32_t)FIXED_INT(val), (FIXED_INT(val) > 0 ? (uint16_t)((FIXED_FRAC(val) / 65536.0) * 10000) : (uint16_t)((1.0 - (FIXED_FRAC(val) / 65536.0)) * 10000))
void FIXED_PRINTF(FIXED_32 val)
{
	printf(FX_PRINTF_IDENTIFIER, FX_PRINTF_ARGUMENTS);
}

void FIXED_SPRINTF(char *output, char *str, FIXED_32 val)
{
	char temp[16];
	sprintf(temp, FX_PRINTF_IDENTIFIER, FX_PRINTF_ARGUMENTS);
	sprintf(output, str, temp);
}

void FIXED_PRINT_TO_BUFFER(void *buffer, uint16_t x, uint16_t y, char *str, FIXED_32 val)
{
	FIXED_SPRINTF(fx_temp_out, str, val);
	BLIT_8x8_text_string(buffer, x, y, fx_temp_out);
}

#define FRACBITS 16
#define ITERS (15 + (FRACBITS >> 1))
FIXED_32 FIXED_SQRT(FIXED_32 val)
{
	//http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.178.3957&rep=rep1&type=pdf
	uint32_t root, remHi, remLo, testDiv, count;
	
	root = 0;    //Clear root
	remHi = 0;   //Clear high part of partial remainder
	remLo = val; //Get argument into low part of partial remainder
	count = ITERS;  //16.16 number
	
	do {
		remHi = (remHi << 2) | (remLo >> 30); remLo <<= 2;	
		root <<= 1;
		testDiv = (root << 1) + 1; //test radical
		if(remHi >= testDiv) {
			remHi -= testDiv;
			root++;
		}
	} while(count-- != 0);
			
	return root;
}

Vector3FX Vector3FX_Normalize(Vector3FX v)
{ 
  //Calculate magnitude.
  FIXED_32 magnitude = FIXED_SQRT((FIXED_MUL(v.x, v.x) + FIXED_MUL(v.y, v.y) + FIXED_MUL(v.z, v.z)));
  MMIO32(0x60010) = magnitude;
	
  FIXED_32 x = FIXED_DIV(v.x, FIXED_ABS(magnitude));
  FIXED_32 y = FIXED_DIV(v.y, FIXED_ABS(magnitude));
  FIXED_32 z = FIXED_DIV(v.z, FIXED_ABS(magnitude));

  Vector3FX result = { x, y, z };
  return result;
}

Vector3FX Vector3FX_CrossProduct(Vector3FX a, Vector3FX b)
{
	Vector3FX result = {
		FIXED_MUL(a.y, b.z) - FIXED_MUL(a.z, b.y),
		FIXED_MUL(a.z, b.x) - FIXED_MUL(a.x, b.z),
		FIXED_MUL(a.x, b.y) - FIXED_MUL(a.y, b.x)
	};
	return result;
}

FIXED_32 FIXED_SINE_TABLE[] =
{
	0x00000000, 0x00000478, 0x000008EF, 0x00000D66, 0x000011DB, 0x00001650, 0x00001AC2, 0x00001F33, 0x000023A1, 0x0000280C, 0x00002C74, 0x000030D9, 0x00003539, 0x00003996, 0x00003DEE, 0x00004242, 0x00004690, 0x00004AD9, 0x00004F1B, 0x00005358, 0x0000578E, 0x00005BBE, 0x00005FE6, 0x00006407, 0x0000681F, 0x00006C30, 0x00007039, 0x00007438, 0x0000782F, 0x00007C1C, 0x00007FFF, 0x000083D9, 0x000087A8, 0x00008B6D, 0x00008F27, 0x000092D5, 0x00009679, 0x00009A10, 0x00009D9B, 0x0000A11B, 0x0000A48D, 0x0000A7F3, 0x0000AB4B, 0x0000AE97, 0x0000B1D4, 0x0000B504, 0x0000B826, 0x0000BB39, 0x0000BE3E, 0x0000C134, 0x0000C41B, 0x0000C6F2, 0x0000C9BA, 0x0000CC73, 0x0000CF1B, 0x0000D1B3, 0x0000D43B, 0x0000D6B2, 0x0000D919, 0x0000DB6E, 0x0000DDB3, 0x0000DFE6, 0x0000E208, 0x0000E418, 0x0000E616, 0x0000E803, 0x0000E9DD, 0x0000EBA5, 0x0000ED5B, 0x0000EEFE, 0x0000F08F, 0x0000F20D, 0x0000F377, 0x0000F4CF, 0x0000F614, 0x0000F746, 0x0000F864, 0x0000F96F, 0x0000FA67, 0x0000FB4B, 0x0000FC1B, 0x0000FCD8, 0x0000FD81, 0x0000FE17, 0x0000FE98, 0x0000FF06, 0x0000FF5F, 0x0000FFA5, 0x0000FFD7, 0x0000FFF5, 0x00010000, 0x0000FFF5, 0x0000FFD7, 0x0000FFA5, 0x0000FF5F, 0x0000FF06, 0x0000FE98, 0x0000FE17, 0x0000FD81, 0x0000FCD8, 0x0000FC1B, 0x0000FB4B, 0x0000FA67, 0x0000F96F, 0x0000F864, 0x0000F746, 0x0000F614, 0x0000F4CF, 0x0000F377, 0x0000F20D, 0x0000F08F, 0x0000EEFE, 0x0000ED5B, 0x0000EBA5, 0x0000E9DD, 0x0000E803, 0x0000E616, 0x0000E418, 0x0000E208, 0x0000DFE6, 0x0000DDB3, 0x0000DB6E, 0x0000D919, 0x0000D6B2, 0x0000D43B, 0x0000D1B3, 0x0000CF1B, 0x0000CC73, 0x0000C9BA, 0x0000C6F2, 0x0000C41B, 0x0000C134, 0x0000BE3E, 0x0000BB39, 0x0000B826, 0x0000B504, 0x0000B1D4, 0x0000AE97, 0x0000AB4B, 0x0000A7F3, 0x0000A48D, 0x0000A11B, 0x00009D9B, 0x00009A10, 0x00009679, 0x000092D5, 0x00008F27, 0x00008B6D, 0x000087A8, 0x000083D9, 0x00007FFF, 0x00007C1C, 0x0000782F, 0x00007438, 0x00007039, 0x00006C30, 0x0000681F, 0x00006407, 0x00005FE6, 0x00005BBE, 0x0000578E, 0x00005358, 0x00004F1B, 0x00004AD9, 0x00004690, 0x00004242, 0x00003DEE, 0x00003996, 0x00003539, 0x000030D9, 0x00002C74, 0x0000280C, 0x000023A1, 0x00001F33, 0x00001AC2, 0x00001650, 0x000011DB, 0x00000D66, 0x000008EF, 0x00000478, 0x00000000, 0xFFFFFB88, 0xFFFFF711, 0xFFFFF29A, 0xFFFFEE25, 0xFFFFE9B0, 0xFFFFE53E, 0xFFFFE0CD, 0xFFFFDC5F, 0xFFFFD7F4, 0xFFFFD38C, 0xFFFFCF27, 0xFFFFCAC7, 0xFFFFC66A, 0xFFFFC212, 0xFFFFBDBE, 0xFFFFB970, 0xFFFFB527, 0xFFFFB0E5, 0xFFFFACA8, 0xFFFFA872, 0xFFFFA442, 0xFFFFA01A, 0xFFFF9BF9, 0xFFFF97E1, 0xFFFF93D0, 0xFFFF8FC7, 0xFFFF8BC8, 0xFFFF87D1, 0xFFFF83E4, 0xFFFF8000, 0xFFFF7C27, 0xFFFF7858, 0xFFFF7493, 0xFFFF70D9, 0xFFFF6D2B, 0xFFFF6987, 0xFFFF65F0, 0xFFFF6265, 0xFFFF5EE5, 0xFFFF5B73, 0xFFFF580D, 0xFFFF54B5, 0xFFFF5169, 0xFFFF4E2C, 0xFFFF4AFC, 0xFFFF47DA, 0xFFFF44C7, 0xFFFF41C2, 0xFFFF3ECC, 0xFFFF3BE5, 0xFFFF390E, 0xFFFF3646, 0xFFFF338D, 0xFFFF30E5, 0xFFFF2E4D, 0xFFFF2BC5, 0xFFFF294E, 0xFFFF26E7, 0xFFFF2492, 0xFFFF224D, 0xFFFF201A, 0xFFFF1DF8, 0xFFFF1BE8, 0xFFFF19EA, 0xFFFF17FD, 0xFFFF1623, 0xFFFF145B, 0xFFFF12A5, 0xFFFF1102, 0xFFFF0F71, 0xFFFF0DF3, 0xFFFF0C89, 0xFFFF0B31, 0xFFFF09EC, 0xFFFF08BA, 0xFFFF079C, 0xFFFF0691, 0xFFFF0599, 0xFFFF04B5, 0xFFFF03E5, 0xFFFF0328, 0xFFFF027F, 0xFFFF01E9, 0xFFFF0168, 0xFFFF00FA, 0xFFFF00A1, 0xFFFF005B, 0xFFFF0029, 0xFFFF000B, 0xFFFF0001, 0xFFFF000B, 0xFFFF0029, 0xFFFF005B, 0xFFFF00A1, 0xFFFF00FA, 0xFFFF0168, 0xFFFF01E9, 0xFFFF027F, 0xFFFF0328, 0xFFFF03E5, 0xFFFF04B5, 0xFFFF0599, 0xFFFF0691, 0xFFFF079C, 0xFFFF08BA, 0xFFFF09EC, 0xFFFF0B31, 0xFFFF0C89, 0xFFFF0DF3, 0xFFFF0F71, 0xFFFF1102, 0xFFFF12A5, 0xFFFF145B, 0xFFFF1623, 0xFFFF17FD, 0xFFFF19EA, 0xFFFF1BE8, 0xFFFF1DF8, 0xFFFF201A, 0xFFFF224D, 0xFFFF2492, 0xFFFF26E7, 0xFFFF294E, 0xFFFF2BC5, 0xFFFF2E4D, 0xFFFF30E5, 0xFFFF338D, 0xFFFF3646, 0xFFFF390E, 0xFFFF3BE5, 0xFFFF3ECC, 0xFFFF41C2, 0xFFFF44C7, 0xFFFF47DA, 0xFFFF4AFC, 0xFFFF4E2C, 0xFFFF5169, 0xFFFF54B5, 0xFFFF580D, 0xFFFF5B73, 0xFFFF5EE5, 0xFFFF6265, 0xFFFF65F0, 0xFFFF6987, 0xFFFF6D2B, 0xFFFF70D9, 0xFFFF7493, 0xFFFF7858, 0xFFFF7C27, 0xFFFF8000, 0xFFFF83E4, 0xFFFF87D1, 0xFFFF8BC8, 0xFFFF8FC7, 0xFFFF93D0, 0xFFFF97E1, 0xFFFF9BF9, 0xFFFFA01A, 0xFFFFA442, 0xFFFFA872, 0xFFFFACA8, 0xFFFFB0E5, 0xFFFFB527, 0xFFFFB970, 0xFFFFBDBE, 0xFFFFC212, 0xFFFFC66A, 0xFFFFCAC7, 0xFFFFCF27, 0xFFFFD38C, 0xFFFFD7F4, 0xFFFFDC5F, 0xFFFFE0CD, 0xFFFFE53E, 0xFFFFE9B0, 0xFFFFEE25, 0xFFFFF29A, 0xFFFFF711, 0xFFFFFB88
};

FIXED_32 FIXED_COSINE_TABLE[] =
{
	0x00010000, 0x0000FFF5, 0x0000FFD7, 0x0000FFA5, 0x0000FF5F, 0x0000FF06, 0x0000FE98, 0x0000FE17, 0x0000FD81, 0x0000FCD8, 0x0000FC1B, 0x0000FB4B, 0x0000FA67, 0x0000F96F, 0x0000F864, 0x0000F746, 0x0000F614, 0x0000F4CF, 0x0000F377, 0x0000F20D, 0x0000F08F, 0x0000EEFE, 0x0000ED5B, 0x0000EBA5, 0x0000E9DD, 0x0000E803, 0x0000E616, 0x0000E418, 0x0000E208, 0x0000DFE6, 0x0000DDB3, 0x0000DB6E, 0x0000D919, 0x0000D6B2, 0x0000D43B, 0x0000D1B3, 0x0000CF1B, 0x0000CC73, 0x0000C9BA, 0x0000C6F2, 0x0000C41B, 0x0000C134, 0x0000BE3E, 0x0000BB39, 0x0000B826, 0x0000B504, 0x0000B1D4, 0x0000AE97, 0x0000AB4B, 0x0000A7F3, 0x0000A48D, 0x0000A11B, 0x00009D9B, 0x00009A10, 0x00009679, 0x000092D5, 0x00008F27, 0x00008B6D, 0x000087A8, 0x000083D9, 0x00008000, 0x00007C1C, 0x0000782F, 0x00007438, 0x00007039, 0x00006C30, 0x0000681F, 0x00006407, 0x00005FE6, 0x00005BBE, 0x0000578E, 0x00005358, 0x00004F1B, 0x00004AD9, 0x00004690, 0x00004242, 0x00003DEE, 0x00003996, 0x00003539, 0x000030D9, 0x00002C74, 0x0000280C, 0x000023A1, 0x00001F33, 0x00001AC2, 0x00001650, 0x000011DB, 0x00000D66, 0x000008EF, 0x00000478, 0x00000000, 0xFFFFFB88, 0xFFFFF711, 0xFFFFF29A, 0xFFFFEE25, 0xFFFFE9B0, 0xFFFFE53E, 0xFFFFE0CD, 0xFFFFDC5F, 0xFFFFD7F4, 0xFFFFD38C, 0xFFFFCF27, 0xFFFFCAC7, 0xFFFFC66A, 0xFFFFC212, 0xFFFFBDBE, 0xFFFFB970, 0xFFFFB527, 0xFFFFB0E5, 0xFFFFACA8, 0xFFFFA872, 0xFFFFA442, 0xFFFFA01A, 0xFFFF9BF9, 0xFFFF97E1, 0xFFFF93D0, 0xFFFF8FC7, 0xFFFF8BC8, 0xFFFF87D1, 0xFFFF83E4, 0xFFFF8001, 0xFFFF7C27, 0xFFFF7858, 0xFFFF7493, 0xFFFF70D9, 0xFFFF6D2B, 0xFFFF6987, 0xFFFF65F0, 0xFFFF6265, 0xFFFF5EE5, 0xFFFF5B73, 0xFFFF580D, 0xFFFF54B5, 0xFFFF5169, 0xFFFF4E2C, 0xFFFF4AFC, 0xFFFF47DA, 0xFFFF44C7, 0xFFFF41C2, 0xFFFF3ECC, 0xFFFF3BE5, 0xFFFF390E, 0xFFFF3646, 0xFFFF338D, 0xFFFF30E5, 0xFFFF2E4D, 0xFFFF2BC5, 0xFFFF294E, 0xFFFF26E7, 0xFFFF2492, 0xFFFF224D, 0xFFFF201A, 0xFFFF1DF8, 0xFFFF1BE8, 0xFFFF19EA, 0xFFFF17FD, 0xFFFF1623, 0xFFFF145B, 0xFFFF12A5, 0xFFFF1102, 0xFFFF0F71, 0xFFFF0DF3, 0xFFFF0C89, 0xFFFF0B31, 0xFFFF09EC, 0xFFFF08BA, 0xFFFF079C, 0xFFFF0691, 0xFFFF0599, 0xFFFF04B5, 0xFFFF03E5, 0xFFFF0328, 0xFFFF027F, 0xFFFF01E9, 0xFFFF0168, 0xFFFF00FA, 0xFFFF00A1, 0xFFFF005B, 0xFFFF0029, 0xFFFF000B, 0xFFFF0001, 0xFFFF000B, 0xFFFF0029, 0xFFFF005B, 0xFFFF00A1, 0xFFFF00FA, 0xFFFF0168, 0xFFFF01E9, 0xFFFF027F, 0xFFFF0328, 0xFFFF03E5, 0xFFFF04B5, 0xFFFF0599, 0xFFFF0691, 0xFFFF079C, 0xFFFF08BA, 0xFFFF09EC, 0xFFFF0B31, 0xFFFF0C89, 0xFFFF0DF3, 0xFFFF0F71, 0xFFFF1102, 0xFFFF12A5, 0xFFFF145B, 0xFFFF1623, 0xFFFF17FD, 0xFFFF19EA, 0xFFFF1BE8, 0xFFFF1DF8, 0xFFFF201A, 0xFFFF224D, 0xFFFF2492, 0xFFFF26E7, 0xFFFF294E, 0xFFFF2BC5, 0xFFFF2E4D, 0xFFFF30E5, 0xFFFF338D, 0xFFFF3646, 0xFFFF390E, 0xFFFF3BE5, 0xFFFF3ECC, 0xFFFF41C2, 0xFFFF44C7, 0xFFFF47DA, 0xFFFF4AFC, 0xFFFF4E2C, 0xFFFF5169, 0xFFFF54B5, 0xFFFF580D, 0xFFFF5B73, 0xFFFF5EE5, 0xFFFF6265, 0xFFFF65F0, 0xFFFF6987, 0xFFFF6D2B, 0xFFFF70D9, 0xFFFF7493, 0xFFFF7858, 0xFFFF7C27, 0xFFFF8000, 0xFFFF83E4, 0xFFFF87D1, 0xFFFF8BC8, 0xFFFF8FC7, 0xFFFF93D0, 0xFFFF97E1, 0xFFFF9BF9, 0xFFFFA01A, 0xFFFFA442, 0xFFFFA872, 0xFFFFACA8, 0xFFFFB0E5, 0xFFFFB527, 0xFFFFB970, 0xFFFFBDBE, 0xFFFFC212, 0xFFFFC66A, 0xFFFFCAC7, 0xFFFFCF27, 0xFFFFD38C, 0xFFFFD7F4, 0xFFFFDC5F, 0xFFFFE0CD, 0xFFFFE53E, 0xFFFFE9B0, 0xFFFFEE25, 0xFFFFF29A, 0xFFFFF711, 0xFFFFFB88, 0x00000000, 0x00000478, 0x000008EF, 0x00000D66, 0x000011DB, 0x00001650, 0x00001AC2, 0x00001F33, 0x000023A1, 0x0000280C, 0x00002C74, 0x000030D9, 0x00003539, 0x00003996, 0x00003DEE, 0x00004242, 0x00004690, 0x00004AD9, 0x00004F1B, 0x00005358, 0x0000578E, 0x00005BBE, 0x00005FE6, 0x00006407, 0x0000681F, 0x00006C30, 0x00007039, 0x00007438, 0x0000782F, 0x00007C1C, 0x00008000, 0x000083D9, 0x000087A8, 0x00008B6D, 0x00008F27, 0x000092D5, 0x00009679, 0x00009A10, 0x00009D9B, 0x0000A11B, 0x0000A48D, 0x0000A7F3, 0x0000AB4B, 0x0000AE97, 0x0000B1D4, 0x0000B504, 0x0000B826, 0x0000BB39, 0x0000BE3E, 0x0000C134, 0x0000C41B, 0x0000C6F2, 0x0000C9BA, 0x0000CC73, 0x0000CF1B, 0x0000D1B3, 0x0000D43B, 0x0000D6B2, 0x0000D919, 0x0000DB6E, 0x0000DDB3, 0x0000DFE6, 0x0000E208, 0x0000E418, 0x0000E616, 0x0000E803, 0x0000E9DD, 0x0000EBA5, 0x0000ED5B, 0x0000EEFE, 0x0000F08F, 0x0000F20D, 0x0000F377, 0x0000F4CF, 0x0000F614, 0x0000F746, 0x0000F864, 0x0000F96F, 0x0000FA67, 0x0000FB4B, 0x0000FC1B, 0x0000FCD8, 0x0000FD81, 0x0000FE17, 0x0000FE98, 0x0000FF06, 0x0000FF5F, 0x0000FFA5, 0x0000FFD7, 0x0000FFF5
};
