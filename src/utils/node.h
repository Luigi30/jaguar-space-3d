#ifndef UTILS_NODE_H
#define UTILS_NODE_H

#include <stdint.h>

/* http://amigadev.elowar.com/read/ADCD_2.1/Libraries_Manual_guide/node02DB.html

The Node and MinNode structures are often incorporated into larger
structures, so groups of the larger structures can easily be linked
together.   For example, the Exec Interrupt structure is defined as
follows:

    struct Interrupt
    {
        struct Node is_Node;
        APTR        is_Data;
        VOID        (*is_Code)();
    };
	
Here the is_Data and is_Code fields represent the useful content of the
node.  Because the Interrupt structure begins with a Node structure, it
may be passed to any of the Exec List manipulation functions.
*/

//A basic node structure for linkage. Put at the beginning of linked list objects.
struct MinNode
{
	struct MinNode *mln_Succ; //Link to next node in list.
	struct MinNode *mln_Pred; //Link to previous node in list.
};

//A full-featured node structure.
struct Node
{
	struct Node *ln_Succ; //Link to next node in list.
	struct Node *ln_Pred; //Link to previous node in list.
	uint8_t      ln_Type; //Node type (TODO: define some).
	int8_t       ln_Pri;  //Node priority (TODO: define if this means anything for us).
	char        *ln_Name; //A NULL-terminated string containing a printable name for this node.
};
	
#endif