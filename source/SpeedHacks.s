#ifdef __arm__

#include "ARMZ80/ARMZ80mac.h"

	.global hacksInit

;@----------------------------------------------------------------------------

	.syntax unified
	.arm

	.section .text
	.align 2
;@----------------------------------------------------------------------------
hacksInit:
	.type   hacksInit STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}

//	mov r0,#0x28				;@ jrz
//	ldr r1,=z80jrzHack
//	bl Z80RedirectOpcode

	ldmfd sp!,{r4-r6,lr}
	bx lr

;@----------------------------------------------------------------------------
z80jrzHack:					;@ Jump if zero
;@----------------------------------------------------------------------------
	ldrsb r0,[z80pc],#1
	tst z80f,#PSR_Z
	beq skipJRZ
	subne z80cyc,z80cyc,#5*CYCLE
	addne z80pc,z80pc,r0
	cmp r0,#-28
	andeq z80cyc,z80cyc,#CYC_MASK
skipJRZ:
	fetch 7
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
