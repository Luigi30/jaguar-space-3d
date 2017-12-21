/* 	Implementation of the Amiga linked list functions because I like them and miss them.
	http://amigadev.elowar.com/read/ADCD_2.1/Libraries_Manual_guide/node02D9.html */

#ifndef LIST_H
#define LIST_H

#include <string.h>
#include <stdint.h>

#include "utils/node.h"

extern char skunkoutput[256];

//Minimum List header.
struct MinList
{
	struct MinNode *mlh_Head;		//Points to the first node in a list.
	struct MinNode *mlh_Tail;		//Is always NULL.
	struct MinNode *mlh_TailPred;	//Points to the last node in a list.
};

//Full-featured List structure.
struct List
{
	struct Node *lh_Head;			//Points to the first node in a list.
	struct Node *lh_Tail;			//Is always NULL.
	struct Node *lh_TailPred;		//Points to the last node in a list.
	uint8_t      lh_Type;			//Defines the type of nodes within the list.
	uint8_t      lh_Pad;			//Is a structure alignment byte.
};

/* List functions */
extern void AddHead(__reg("a0") struct List *list, __reg("a1") struct Node *node);
extern void AddTail(__reg("a0") struct List *list, __reg("a1") struct Node *node);

extern struct Node *RemHead(__reg("a0") struct List *list);
extern struct Node *RemTail(__reg("a0") struct List *list);

extern struct Node *Remove(__reg("a1") struct Node *node);
extern struct Node *FindName(struct List *list, char *name);

void NewList(struct List *lh);
#endif
