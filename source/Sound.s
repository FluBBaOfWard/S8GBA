#ifdef __arm__

#include "Shared/gba_asm.h"
#include "SN76496/SN76496.i"

#define MIX_LEN (528)

	.global soundMode
	.global SN76496_0

	.global soundInit
	.global soundReset
	.global vblSound1
	.global vblSound2
	.global setMuteSoundGUI
	.global setMuteSoundGame
	.global SN76496_W
	.global GG_Stereo_W

	.extern pauseEmulation


	.syntax unified
	.arm

	.section .ewram, "ax", %progbits
	.align 2
;@----------------------------------------------------------------------------
soundInit:
	.type soundInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5,lr}
	mov r5,#REG_BASE

;@	ldrh r0,[r5,#REG_SGBIAS]
;@	bic r0,r0,#0xc000			;@ Just change bits we know about.
;@	orr r0,r0,#0x8000			;@ PWM 7-bit 131.072kHz
;@	strh r0,[r5,#REG_SGBIAS]

	ldrb r4,soundMode
	cmp r4,#1					;@ If r4=0, no sound.

	movmi r0,#0
	ldreq r0,=0x0b040000		;@ Stop all channels, output ratio=100% dsA.  use directsound A for L&R, timer 0
	str r0,[r5,#REG_SGCNT_L]

	moveq r0,#0x80
	strh r0,[r5,#REG_SGCNT_X]	;@ Sound master enable

	mov r0,#0					;@ Triangle reset
	str r0,[r5,#REG_SG3CNT_L]	;@ Sound3 disable, mute, write bank 0

								;@ Mixer channels
	strh r5,[r5,#REG_DMA1CNT_H]	;@ DMA1 stop, SN76496
	add r0,r5,#REG_FIFO_A_L		;@ DMA1 destination..
	str r0,[r5,#REG_DMA1DAD]
	ldr r0,pcmPtr0
	str r0,[r5,#REG_DMA1SAD]	;@ DMA1 src=..


	ldr snptr,=SN76496_0
	mov r1,#1
	bl sn76496SetMixrate		;@ Sound, 0=low, 1=high mixrate
	ldr r1,=1536000
	bl sn76496SetFrequency		;@ Sound, chip frequency
	ldr r1,=FREQTBL
	bl sn76496Init				;@ Sound


	cmp r4,#1					;@ If r4=0, no sound.

	mov r2,#0					;@ Timer 0 controls sample rate:
	str r2,[r5,#REG_TM0CNT_L]	;@ Stop timer 0
	ldreq r1,[snptr,#mixRate]	;@ 924=Low, 532=High.
	rsbeq r2,r1,#0x810000		;@ Timer 0 on. Frequency = 0x1000000/r3 Hz
	streq r2,[r5,#REG_TM0CNT_L]

	ldmfd sp!,{r4-r5,lr}
	bx lr

;@----------------------------------------------------------------------------
soundReset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr snptr,=SN76496_0
	mov r1,#0					;@ SMS chip type
	bl sn76496Reset				;@ Sound
	ldmfd sp!,{lr}
	bx lr

;@----------------------------------------------------------------------------
setMuteSoundGUI:
	.type   setMuteSoundGUI STT_FUNC
;@----------------------------------------------------------------------------
	ldr r1,=pauseEmulation		;@ Output silence when emulation paused.
	ldrb r0,[r1]
	strb r0,muteSoundGUI
	bx lr
;@----------------------------------------------------------------------------
setMuteSoundGame:			;@ For System E ?
;@----------------------------------------------------------------------------
	strb r0,muteSoundGame
	bx lr
;@----------------------------------------------------------------------------
vblSound1:
;@----------------------------------------------------------------------------
	ldrb r0,soundMode			;@ If r0=0, no sound.
	cmp r0,#0
	bxeq lr

	mov r1,#REG_BASE
	strh r1,[r1,#REG_DMA1CNT_H]	;@ DMA1 stop
	ldr r2,pcmPtr0
	str r2,[r1,#REG_DMA1SAD]	;@ DMA1 src=..
	ldr r0,=0xB640				;@ noIRQ fifo 32bit repeat incsrc fixeddst
	strh r0,[r1,#REG_DMA1CNT_H]	;@ DMA1 go

	ldr r1,pcmPtr1
	str r1,pcmPtr0
	str r2,pcmPtr1

	bx lr
;@----------------------------------------------------------------------------
vblSound2:
;@----------------------------------------------------------------------------
	;@ Update DMA buffer for PCM
	ldrb r0,soundMode			;@ If r0=0, no sound.
	cmp r0,#0
	bxeq lr

	mov r2,#MIX_LEN
	ldr r1,pcmPtr0
	ldr r0,muteSound
	cmp r0,#0
	bne silenceMix

	ldreq snptr,=SN76496_0
	beq sn76496Mixer

;@----------------------------------------------------------------------------
silenceMix:					;@ r1=destination, r2=len
;@----------------------------------------------------------------------------
	mov r0,#0
silenceLoop:
	subs r2,r2,#4
	strpl r0,[r1],#4
	bhi silenceLoop

	bx lr
;@----------------------------------------------------------------------------
GG_Stereo_W:
;@----------------------------------------------------------------------------
	bx lr
//	ldr snptr,=SN76496_0
//	b sn76496GGW
;@----------------------------------------------------------------------------
SN76496_W:
SN_0_W:
;@----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}
	mov r1,r0
	ldr snptr,=SN76496_0
	bl sn76496W
	ldmfd sp!,{r3,pc}

;@----------------------------------------------------------------------------
pcmPtr0:	.long WAVBUFFER
pcmPtr1:	.long WAVBUFFER+MIX_LEN

muteSound:
muteSoundGUI:
	.byte 0
muteSoundGame:
	.byte 0
	.space 2
soundMode:
	.byte 1
	.space 3

#ifdef GBA
	.section .sbss				;@ This is EWRAM on GBA with devkitARM
#else
	.section .bss
#endif
	.align 2
SN76496_0:
	.space snSize
FREQTBL:
	.space 1024*2
WAVBUFFER:
	.space MIX_LEN*2
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
