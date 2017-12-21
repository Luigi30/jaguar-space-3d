#include "utils/list.h"

/* http://amigadev.elowar.com/read/ADCD_2.1/Includes_and_Autodocs_2._guide/node0081.html */

void NewList(struct List *list)
{
  //An empty list loops back on itself.
  list->lh_Head = (struct Node *)((long)list + 4);
  list->lh_Tail = NULL;
  list->lh_TailPred = (struct Node *)((long)list);
}

struct Node *FindName(struct List *list, char *name)
{
  struct Node *current = list->lh_Head;

  while(current != NULL)
    {
      if(strcmp(current->ln_Name, name) == 0)
	return current;
      else
	current = current->ln_Succ;
    }

  return NULL; //not found
}
