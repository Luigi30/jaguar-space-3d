/* script.h */
/* scripting facility - important for video games you know */

#include <stdio.h>
#include <inttypes.h>
#include "log.h"

#define OP_ADD '+'
#define OP_SUB '-'
#define OP_MUL '*'
#define OP_DIV '/'

int LISP_eval(char *expr);

int LISP_compute_add(char *expr);
int LISP_compute_sub(char *expr);
int LISP_compute_mul(char *expr);
int LISP_compute_div(char *expr);
