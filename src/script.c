#include "script.h"

int LISP_eval(char *expr)
{
  if(*(expr++) != '(')
    {
      EmuLog_String("Script error: expression does not begin with '('\n");
      return 0;
    }

  char *operator = (expr++); //read our operator

  uint32_t result = 0;
  
  switch(*operator)
    {
    case OP_ADD:
      result = LISP_compute_add(expr);
      break;
    case OP_SUB:
      result = LISP_compute_sub(expr);
      break;
    case OP_MUL:
      result = LISP_compute_mul(expr);
      break;
    case OP_DIV:
      result = LISP_compute_div(expr);
      break;
    default: break;
    }
  
  return result;
}

/* Compute functions */
int LISP_compute_add(char *expr)
{
  int sum = 0;

  //Read operand.
  while(*expr != ')')
    {

      //Skip spaces.
      if(*expr == ' ') { expr++; continue; }
      
      int m = 0;
      sscanf(expr++, "%d", &m);
      sum += m;
    }

  return sum;
}

int LISP_compute_sub(char *expr)
{
  //TODO: more than 2 operands
  int m, n = 0;

  //Skip spaces.
  while(*(++expr) == ' ');

  //Found the first operand.
  sscanf(expr, "%d", &m);
  ++expr;

  //Skip spaces.
  while(*(++expr) == ' ');

  //Found the second operand.
  sscanf(expr, "%d", &n);

  return m - n;
}

int LISP_compute_mul(char *expr)
{
  int product = 1;

  //Read operand.
  while(*expr != ')')
    {
      //Skip spaces.
      if(*expr == ' ') { expr++; continue; }

      int m = 0;
      sscanf(expr++, "%d", &m);
      product *= m;
    }

  return product;
}

int LISP_compute_div(char *expr)
{
  int m, n = 0;

  //Skip spaces.
  while(*(++expr) == ' ');

  //Found the first operand.
  sscanf(expr, "%d", &m);
  ++expr;

  //Skip spaces.
  while(*(++expr) == ' ');

  //Found the second operand.
  sscanf(expr, "%d", &n);

  return m/n;
}
