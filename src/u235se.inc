;===============================================================================================================
; U-235 SoundEngine
; Includes
;
; Written by LinkoVitch 2011-2014
; Copyright 2011-2014 U-235  http://www.u-235.co.uk
; 
; Please read LICENSE.TXT for licensing information
;===============================================================================================================
 
;----------------------------------------------------------------------------------------------------- Variables
 
	xref	U235SE_period_ptr				; pointer to the period table 
	xref	U235SE_ptr_sample_bank			; pointer to the sound effects sample bank
 
	xref	U235SE_sfxplaylist_ptr			; address of sound effect playlist to process
 
	xref	U235SE_playmod					; control register for module playback
 
	xref	U235SE_playback_rate			; The current playback rate
	xref	U235SE_playback_period 			; The current playback rate's period
 
 
	xref U235SE_playbackmode 			; Sets mono or stereo for music and sfx
	xref U235SE_music_vol				; volume of music voices (0-64)
	xref U235SE_sfx_vol					; volume of sfx voices (0-64)
 
	xref U235SE_moduleaddr				; Pointer to the location of module in memory
 
	xref U235SE_sample_tbl
	xref U235SE_sfxplaylist_ptr
	xref U235SE_dsp_playlist
	xref U235SE_dsp_playlist_ptr 
 
	xref U235SE_voice_pos
	xref U235SE_voice_end
	xref U235SE_voice_periods
	xref U235SE_voice_counter 
 
	xref U235SE_modspeed					; Number of ticks per division 
	xref	U235SE_moddivision				; Current division in pattern
	xref U235SE_modposition 				; Current position in song
 
	xref		U235SE_voice_smp
	xref		U235SE_voice_roff
	xref		U235SE_voice_rend

	xref		U235SE_rng					; Random number generator output

	xref U235SE_endofdspram

;------------------------------------------------------------------------------------------------ Joypad Section

										; Pads : mask = xxxxxxCx xxBx2580 147*oxAP 369#RLDU
	xref		U235SE_pad1					; Pad 1 buttons pressed
	xref		U235SE_pad2					; Pad 2 buttons pressed

; 												Bit numbers for buttons in the mask for testing individual bits
U235SE_BBUT_UP			EQU		0		; Up
U235SE_BBUT_U			EQU		0
U235SE_BBUT_DOWN		EQU		1		; Down
U235SE_BBUT_D			EQU		1
U235SE_BBUT_LEFT		EQU		2		; Left
U235SE_BBUT_L			EQU		2
U235SE_BBUT_RIGHT		EQU		3		; Right
U235SE_BBUT_R			EQU		3		
U235SE_BBUT_HASH		EQU		4		; Hash (#)
U235SE_BBUT_9			EQU		5		; 9
U235SE_BBUT_6			EQU		6		; 6
U235SE_BBUT_3			EQU		7		; 3
U235SE_BBUT_PAUSE		EQU		8		; Pause
U235SE_BBUT_A			EQU		9		; A button
U235SE_BBUT_OPTION		EQU		11		; Option
U235SE_BBUT_STAR		EQU		12		; Star 
U235SE_BBUT_7			EQU		13		; 7
U235SE_BBUT_4			EQU		14		; 4
U235SE_BBUT_1			EQU		15		; 1
U235SE_BBUT_0			EQU		16		; 0 (zero)
U235SE_BBUT_8			EQU		17		; 8
U235SE_BBUT_5			EQU		18		; 5
U235SE_BBUT_2			EQU		19		; 2
U235SE_BBUT_B			EQU		21		; B button
U235SE_BBUT_C			EQU		25		; C button

; 												Numerical representations
U235SE_BUT_UP			EQU		1		; Up
U235SE_BUT_U			EQU		1
U235SE_BUT_DOWN			EQU		2		; Down
U235SE_BUT_D			EQU		2
U235SE_BUT_LEFT			EQU		4		; Left
U235SE_BUT_L			EQU		4
U235SE_BUT_RIGHT		EQU		8		; Right
U235SE_BUT_R			EQU		8		
U235SE_BUT_HASH			EQU		16		; Hash (#)
U235SE_BUT_9			EQU		32		; 9
U235SE_BUT_6			EQU		64		; 6
U235SE_BUT_3			EQU		$80		; 3
U235SE_BUT_PAUSE		EQU		$100	; Pause
U235SE_BUT_A			EQU		$200	; A button
U235SE_BUT_OPTION		EQU		$400	; Option
U235SE_BUT_STAR			EQU		$800	; Star 
U235SE_BUT_7			EQU		$1000	; 7
U235SE_BUT_4			EQU		$2000	; 4
U235SE_BUT_1			EQU		$4000	; 1
U235SE_BUT_0			EQU		$8000	; 0 (zero)
U235SE_BUT_8			EQU		$10000	; 8
U235SE_BUT_5			EQU		$20000	; 5
U235SE_BUT_2			EQU		$40000	; 2
U235SE_BUT_B			EQU		$80000	; B button
U235SE_BUT_C			EQU		$100000	; C button

;------------------------------------------------------------------------------------------------- Handy Equates
 
U235SE_MONO				EQU		0			; mono playback for either 0-3 or 4-7
U235SE_STEREO_MUSIC		EQU		1			; stereo playback for 0-3 (music voices)
U235SE_STEREO_SFX		EQU		2			; stereo playback for 4-7 (sfx voices)
 
U235SE_NOMOD			EQU		0			; no module playback
U235SE_PLAYMONO			EQU		1			; Play the module with mono mixing
U235SE_PLAYSTEREO		EQU		2			; Play the module with stereo mixing
 
U235SE_8KHZ				EQU		$00300042	; Set playback rate  (8.1kHz)
U235SE_12KHZ			EQU		$0030002C	; Set playback rate  (12.060kHz)
U235SE_16KHZ			EQU		$00300020 	; Set playback rate  (16.446kHz)
U235SE_24KHZ			EQU		$00300015	; Set playback rate  (24.67kHz)
U235SE_32KHZ			EQU		$00300010	; Set playback rate  (31.925kHz)
 
U235SE_8KHZ_PERIOD		EQU		1234		; 8kHz period
U235SE_12KHZ_PERIOD		EQU		829			; 12kHz period
U235SE_16KHZ_PERIOD		EQU		608			; 16kHz period
U235SE_24KHZ_PERIOD 	EQU		405			; 24kHz period
U235SE_32KHZ_PERIOD		EQU		313			; 32kHz period

;------------------------------------------------------------------------------------------------- 68k routines

	xref moddebug
	xref modinit
	xref vbimod
	xref modpatternt
	xref playsoundt
	xref modpattern
	xref playpattern
	xref playsound
	xref playsounds
	xref seqinit

 