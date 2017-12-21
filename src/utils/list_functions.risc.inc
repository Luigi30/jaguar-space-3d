* Get next in list
  .macro SUCC
  load	(\1),\2
  .endm

* Get previous node in list - requires a NODE_OFFSET equr
  .macro PRED
  load	 #4,NODE_OFFSET
  load	 (NODE_OFFSET+\1),\2
  .endm
  