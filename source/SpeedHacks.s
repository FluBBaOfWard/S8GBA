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

	mov r0,#0x20				;@ jrz
	ldr r1,=z80jrnzHack
	bl Z80RedirectOpcode
//	mov r0,#0x28				;@ jrz
//	ldr r1,=z80jrzHack
//	bl Z80RedirectOpcode

	ldmfd sp!,{r4-r6,lr}
	bx lr

;@----------------------------------------------------------------------------
z80jrnzHack:	;@ 0x20 JR NZ,*			Jump if not zero
;@----------------------------------------------------------------------------
	ldrsb r0,[z80pc],#1
	tst z80f,#PSR_Z
	bne skipJRNZ
	subeq z80cyc,z80cyc,#5*CYCLE
	addeq z80pc,z80pc,r0
	cmp r0,#-6					;@ AfterBurner, Out Run & PS.
	andeq z80cyc,z80cyc,#CYC_MASK
skipJRNZ:
	fetch 7
;@----------------------------------------------------------------------------
z80jrzHack:		;@ 0x28 JR Z,*			Jump if zero
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
