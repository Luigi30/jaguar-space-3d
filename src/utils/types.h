#ifndef UTILS_TYPES_H
#define UTILS_TYPES_H

#ifndef VOID
#define VOID            void
#endif

/* General const support */
#ifndef CONST
#if __STDC__
#define CONST           const
#else
#define CONST
#endif
#endif

#ifndef VOLATILE
#if __STDC__
#define VOLATILE        volatile
#else
#define VOLATILE
#endif
#endif

#ifndef APTR_TYPEDEF
#define APTR_TYPEDEF
typedef void	       *APTR;	    /* 32-bit untyped pointer */
#endif
typedef long            LONG;       /* signed 32-bit quantity */
typedef unsigned long   ULONG;      /* unsigned 32-bit quantity */
typedef unsigned long   LONGBITS;   /* 32 bits manipulated individually */
typedef short           WORD;       /* signed 16-bit quantity */
typedef unsigned short  UWORD;      /* unsigned 16-bit quantity */
typedef unsigned short  WORDBITS;   /* 16 bits manipulated individually */
#if __STDC__
typedef signed char	BYTE;	    /* signed 8-bit quantity */
#else
typedef char		BYTE;	    /* signed 8-bit quantity */
#endif
typedef unsigned char   UBYTE;      /* unsigned 8-bit quantity */
typedef unsigned char   BYTEBITS;   /* 8 bits manipulated individually */
typedef unsigned short	RPTR;	    /* signed relative pointer */

#ifdef __cplusplus
typedef char           *STRPTR;     /* string pointer (NULL terminated) */
#else
typedef unsigned char  *STRPTR;     /* string pointer (NULL terminated) */
#endif

/* const support for pointer types */
typedef CONST void     *CONST_APTR;     /* 32-bit untyped const pointer */
#ifdef __cplusplus
typedef CONST char           *CONST_STRPTR; /* STRPTR to const data */
#else
typedef CONST unsigned char  *CONST_STRPTR; /* STRPTR to const data */
#endif

/* For compatibility only: (don't use in new code) */
typedef short           SHORT;      /* signed 16-bit quantity (use WORD) */
typedef unsigned short  USHORT;     /* unsigned 16-bit quantity (use UWORD) */
typedef short           COUNT;
typedef unsigned short  UCOUNT;
typedef ULONG		CPTR;


/* Types with specific semantics */
typedef float           FLOAT;
typedef double          DOUBLE;
typedef short           BOOL;
typedef unsigned char   TEXT;

#endif UTILS_TYPES_H