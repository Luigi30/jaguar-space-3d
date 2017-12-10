	include	"jaguar.inc"
	include "u235se.inc"
	
	xdef _DSP_LoadSoundEngine
	xdef _DSP_StartSoundEngine
	xdef _DSP_PlayModule
	
	xref dspcode
	
_DSP_LoadSoundEngine:
	move.w	#2048,d0
	lea		dspcode,a0
	move.l	#D_RAM,a1
	
.loop:
	move.l	(a0)+,(a1)+
	dbra.w	d0,.loop
	
	move.w	#$100,JOYSTICK
	rts
	
_DSP_StartSoundEngine:
	move.l	#D_RAM,D_PC
	move.l	#RISCGO,D_CTRL
	rts

_DSP_PlayModule:
	move.l	#_MOD_KillerTofu,a0
	move.l	a0,(U235SE_moduleaddr)
	
	jsr modinit
	
	move.l	#1,U235SE_playmod
	
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cnop 0,4 ;modules must be long-aligned
_MOD_KillerTofu:
	incbin "mods/tofu.mod"
	
	end