#ifdef __arm__

#include "Shared/gba_asm.h"
#include "Shared/EmuSettings.h"
#include "Equates.h"
#include "ARMZ80/ARMZ80.i"
#include "SegaVDP/SegaVDP.i"

	.global gColorValue
	.global g3DEnable
	.global gFlicker
	.global gTwitch
	.global gScaling
	.global gGfxMask
	.global yStart
	.global SPRS
	.global paletteMask
	.global bColor
	.global frameTotal
	.global VDP0
	.global VDPRAM				;@ Used by cart.s, init ram.
	.global EMUPALBUFF			;@ Needs to be flushed before dma copied.
	.global GFX_DISPCNT
	.global GFX_BG0CNT
	.global GFX_BG3CNT

	.global antWars
	.global gfxInit
	.global gfxReset
	.global setupScaling
	.global VDP0ApplyScaling
	.global paletteInit
	.global mapSGPalette
	.global paletteTxAll
	.global refreshGfx
	.global makeBorder
	.global endFrame
	.global spriteScannerStart
	.global spriteScanner
	.global sprDMADo0
	.global vblIrqHandler

	.global VDP0SetMode
	.global VDP0ScanlineBPReset
	.global VDP0SetSprScan
	.global VDP0LatchHCounter

	.global VDP0VCounterR
	.global VDP0HCounterR
	.global VDP0StatR
	.global VDP0DataR
	.global VDP0DataTMSW
	.global VDP0DataSMSW
	.global VDP0DataGGW
	.global VDP0DataMDW
	.global VDP0CtrlW
	.global VDP0CtrlMDW

	.syntax unified
	.arm

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2

antSeed:
	.long 0x800000
;@----------------------------------------------------------------------------
antWars:
	.type antWars STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}

	mov r0,#0x40
	ldr r1,=VDP0
	strb r0,[r1,#vdpMode2Bak2]

	ldr r0,=EMUPALBUFF			;@ Setup palette for antWars.
	mov r4,#0
	strh r4,[r0]
	strh r4,[r0,#0x40]
	ldr r4,=0x7FFF
	strh r4,[r0,#0x1E]

	ldr r4,[r1,#vdpBgrMapOfs1]
	mov r0,#BG_GFX
	add r4,r0,r4,lsl#3
	mov r0,#0
tmLoop:
	add r1,r0,#8
	strh r1,[r4],#2
	add r0,r0,#1
	cmp r0,#1024
	bne tmLoop

	mov r0,r4
	ldr r1,=0x02000200
	mov r2,#0x800/4
	bl memset_					;@ BG1/BG3 clear

	ldr r0,=BG_GFX+0x04100
	ldr r3,antSeed
	ldr r1,=32*192
antLoop0:
	mov r2,#8
antLoop1:
	movs r3,r3,lsr#1
	eorcs r3,r3,#0xE10000
	mov r4,r4,lsl#4
	orrcs r4,r4,#0xF
	subs r2,r2,#1
	bne antLoop1
	str r4,[r0],#4
	subs r1,r1,#1
	bne antLoop0

	str r3,antSeed
	ldmfd sp!,{r4,lr}
	bx lr
;@----------------------------------------------------------------------------
gfxInit:					;@ (called from main.c) only need to call once
	.type gfxInit STT_FUNC
;@----------------------------------------------------------------------------
	b rendererInit
;@----------------------------------------------------------------------------
gfxReset:					;@ Called with cpuReset
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}

//	ldr r0,=gfxstate
	mov r1,#0
//	mov r2,#1					;@ 2*4
//	bl memclr_					;@ Clear GFX regs

	ldr r0,=wTop
	str r1,[r0]
	ldr r0,=yStart
	strb r1,[r0]

	bl VDP0Reset

//	bl clearTileMaps

	ldr r0,=OAMBuffer1			;@ No stray sprites please
	mov r1,#0x200+SCREEN_HEIGHT
	mov r2,#0x400
	bl memset_
	mov r0,#OAM
	mov r2,#0x100
	bl memset_

	ldr r0,=0x7FFF
	ldr r1,=paletteMask
	str r0,[r1]

	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl mapSGPalette
	ldr r0,=gGammaValue
	ldrb r0,[r0]
	bl paletteInit				;@ Do palette mapping
	bl paletteTxAll				;@ Transfer it

	bl makeBorder
	bl setupScaling

	ldr r0,=gEmuFlags
	ldr r0,[r0]
	tst r0,#PALTIMING
	moveq r0,#59				;@ NTSC
	movne r0,#49				;@ PAL
//	ldr r1,=fpsNominal
//	strb r0,[r1]

	ldmfd sp!,{pc}

;@----------------------------------------------------------------------------
HWToVDP:
	;@    Auto            SG-1000         SC-3000         OMV
	.byte VDPSega3155246, VDPTMS9918,     VDPTMS9918,     VDPTMS9918
	;@    SG1000II        Mark 3          SMS1            SMS2
	.byte VDPSega3155066, VDPSega3155124, VDPSega3155124, VDPSega3155246
	;@    GG              MD              Coleco          MSX
	.byte VDPSega3155378, VDPSega3155313, VDPTMS9918,     VDPTMS9918
	;@    SORDM5          Sys-E           SG1k AC         Mega Tech
	.byte VDPTMS9918,     VDPSega3155124, VDPTMS9918,     VDPSega3155246
	.pool
;@----------------------------------------------------------------------------
VDP0Reset:
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
	ldr vdpptr,=VDP0
	ldr r0,=VDPRAM
	str r0,[vdpptr,#VRAMPtr]	;@ This needs to be set before reset.
	ldr r3,=gMachine
	ldrb r3,[r3]
	adr r1,HWToVDP
	ldrb r0,[r1,r3]
	ldr r1,=Z80SetIRQPinCurrentCpu
	ldr r2,=Z80SetNMIPinCurrentCpu
	cmp r3,#HW_COLECO
	ldreq r1,=Z80SetNMIPinCurrentCpu
	ldr r3,=gEmuFlags
	ldr r3,[r3]
	tst r3,#PALTIMING
	orrne r0,r0,#TVTYPEPAL
	tst r3,#GG_MODE
	orrne r0,r0,#GGMODE
	bl VDPReset				;@ r0=vdp/tv type, r1 = IRQ function ptr, r2 = debounce routine, r12 = vdpptr.
	ldr r0,=OAMBuffer1
	str r0,[vdpptr,#vdpTmpOAMBuffer]
	ldr r0,=OAMBuffer2
	str r0,[vdpptr,#vdpDMAOAMBuffer]

	mov r0,#0x0000				;@ BGR map
	str r0,[vdpptr,#vdpBgrMapOfs0]
	mov r0,#0x0000				;@ BGR map
	str r0,[vdpptr,#vdpBgrMapOfs1]
	mov r0,#0x04000				;@ BGR tiles
	str r0,[vdpptr,#vdpBgrTileOfs]
	mov r0,#0x14000				;@ SPR tiles
	str r0,[vdpptr,#vdpSprTileOfs]

	ldr r0,=gEmuFlags
	ldr r0,[r0]
	tst r0,#PALTIMING
	moveq r0,#60
	movne r0,#50
	bl setTargetFPS
	ldmfd sp!,{pc}
;@----------------------------------------------------------------------------
clearTileMaps:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,lr}
	add r3,vdpptr,#vdpBgrMapOfs0
	mov r6,#2
clrTmLoop2:
	ldr r4,[r3],#4
	mov r0,#BG_GFX
	add r4,r0,r4,lsl#3
	mov r5,#2
clrTmLoop1:
	add r0,r4,#0x700
	add r4,r4,#0x800
	mov r1,#0x100/4
	bl memclr_
	subs r5,r5,#1
	bne clrTmLoop1
	subs r6,r6,#1
	bne clrTmLoop2
	ldmfd sp!,{r4-r6,pc}
;@----------------------------------------------------------------------------
makeBorder:					;@ Also called from UI.c, r0 = border type.
	.type   makeBorder STT_FUNC
;@----------------------------------------------------------------------------

	mov r1,#0x00C0				;@ H start-end
	mov r2,#0x00C0				;@ H start-end
	ldr r12,=0xC0F0				;@ H start-end Win1

	ldrb r0,bColor
	cmp r0,#2
	beq setBorderValues

	ldr r0,=gEmuFlags
	ldrb r0,[r0]
	tst r0,#GG_MODE

	orrne r1,r1,#0x2800			;@ H start-end
	orrne r2,r2,#0x2800			;@ H start-end
	ldrne r12,=0xC0C8			;@ H start-end Win1
setBorderValues:
	str r1,Window0HValue_normal
	str r2,Window0HValue_col0
	str r12,Window1HValue
	
	mov r1,#REG_BASE
	mov r0,#0x0008
	strh r0,[r1,#REG_WINOUT]

	bx lr

;@----------------------------------------------------------------------------
setupScaling:		;@ r0-r3, r12 modified.
	.type   setupScaling STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r0,bColor
	cmp r0,#2
	ldr r3,=gEmuFlags
	ldrb r3,[r3]
	biceq r3,r3,#GG_MODE
	ldr r2,=gMachine
	ldrb r2,[r2]
	ldr r1,=gScalingSet
	ldrb r1,[r1]
	adr r0,BG_SCALING_1_1

	tst r3,#GG_MODE
	adrne r0,BG_SCALING_1_1_GG
	cmp r1,#SCALED_1_1
	beq loadScaleValues

	cmp r1,#SCALED_FIT
	bne noFit
	adr r0,BG_SCALING_TO_FIT
	tst r3,#GG_MODE
	adrne r0,BG_SCALING_1_1_GG
	b loadScaleValues
noFit:
	cmp r1,#SCALED_ASPECT
	bne loadScaleValues

	adr r0,BG_SCALING_ASPECT_NTSC
	tst r3,#PALTIMING
	adrne r0,BG_SCALING_ASPECT_PAL
	cmp r2,#HW_GG
	adreq r0,BG_SCALING_ASPECT_GG
	tst r3,#GG_MODE
	adrne r0,BG_SCALING_ASPECT_GGMODE

loadScaleValues:
	ldmia r0!,{r1-r3}
	adr r12,BG_SCALING_TBL
	stmia r12,{r1-r3}

	ldmia r0!,{r1-r3}
	adr r12,BG_SCALING_WIN
	stmia r12,{r1-r3}

	ldmia r0!,{r1-r3}
	adr r12,BG_SCALING_OFS
	stmia r12,{r1-r3}

	ldmia r0!,{r1-r3}
	adr r12,scaleSprParam
	stmia r12,{r1-r3}
	
	b buildSpriteScaling

BG_SCALING_TO_FIT:				;@ 192->SCREEN_HEIGHT, 224->S_H, 240->S_H
	.long 0xD560,0xB710,0xACCD
	.long SCREEN_HEIGHT,SCREEN_HEIGHT,SCREEN_HEIGHT
	.long 0x0000,0x0000,0x0000
	.long 0x0100,0x0120,0x0099
BG_SCALING_1_1:
	.long 0xFFFF,0xFFFF,0xFFFF
	.long SCREEN_HEIGHT,SCREEN_HEIGHT,SCREEN_HEIGHT
	.long 0x0000,0x0010,0x0018
	.long 0x0100,0x0100,0x0080
BG_SCALING_1_1_GG:
	.long 0xFFFF,0xFFFF,0xFFFF
	.long 0x0898,0x0898,0x0898
	.long 0x0010,0x0020,0x0028
	.long 0x0100,0x0100,0x0080
BG_SCALING_ASPECT_PAL:			;@ 192->142, 224->165, 240->177
	.long 0xBD56,0xBD56,0xBD56
	.long 0x0900 + SCREEN_HEIGHT-9,SCREEN_HEIGHT,SCREEN_HEIGHT
	.long    -13,      2,     8
	.long 0x0150,0x0150,0x00AD
BG_SCALING_ASPECT_NTSC:			;@ 192->170, 224->199, 240->213
	.long 0xE38F,0xE2AB,0xE2AB
	.long SCREEN_HEIGHT,SCREEN_HEIGHT,SCREEN_HEIGHT
	.long      5,0x0004,0x000C
	.long 0x0100,0x0120,0x0090
BG_SCALING_ASPECT_GG:			;@ 192->160, 216->180, 6->5
	.long 0xD555,0xD555,0xD555
	.long SCREEN_HEIGHT,SCREEN_HEIGHT,SCREEN_HEIGHT
	.long      0,    10,    12
	.long 0x0133,0x0133,0x0092
BG_SCALING_ASPECT_GGMODE:		;@ 160x144 -> 160x120, 6->5
	.long 0xD555,0xD555,0xD555
	.long 0x249C,0x249C,0x249C
	.long    -19,    -3,0x0008
	.long 0x0133,0x0133,0x0092

BG_SCALING_TBL:
	.long 0,0,0
BG_SCALING_WIN:
	.long SCREEN_HEIGHT,SCREEN_HEIGHT,SCREEN_HEIGHT
BG_SCALING_OFS:
	.long 0,0,0

scaleParms:
	.long 0x0000				;@ Rotate value
	.long 0x0100				;@ Normal Horizontal
	.long 0x0080				;@ Double Horizontal
scaleSprParam:
	.long 0x0100				;@ Scaled Normal Vertical
	.long 0x0120				;@ Scaled 8x16 Vertical
	.long 0x0099				;@ Scaled Double Vertical
	.long OAMBuffer1+6
	.long OAM+768+6
;@----------------------------------------------------------------------------
buildSpriteScaling:
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r8}
	adr r7,scaleParms			;@ Set sprite scaling params
	ldmia r7,{r0-r7}

	mov r8,#4
scaleLoop:
	strh r1,[r6],#8				;@ buffer1, buffer2. normal sprites
	strh r0,[r6],#8
	strh r0,[r6],#8
	strh r3,[r6],#8
		strh r1,[r6],#8			;@ 8x16 sprites
		strh r0,[r6],#8
		strh r0,[r6],#8
		strh r4,[r6],#8
			strh r2,[r6],#8		;@ Double sprites
			strh r0,[r6],#8
			strh r0,[r6],#8
			strh r5,[r6],#8
				strh r2,[r6],#8	;@ 8x16 double sprites
				strh r0,[r6],#8
				strh r0,[r6],#8
				strh r5,[r6],#8
	add r6,r6,#0x380
	subs r8,r8,#1
	bne scaleLoop

	strh r3,[r7],#8				;@ 0x07000306
	strh r0,[r7],#8
	strh r0,[r7],#8
	strh r4,[r7]

	ldmfd sp!,{r4-r8}
	bx lr
;@----------------------------------------------------------------------------
VDP0ApplyScaling:		;@ r0-r2, r12 modified.
	.type VDP0ApplyScaling STT_FUNC
;@----------------------------------------------------------------------------
	ldr vdpptr,=VDP0
;@----------------------------------------------------------------------------
applyScaling:		;@ r0-r2 modified, r12 = vdpptr.
;@----------------------------------------------------------------------------
	ldrb r0,[vdpptr,#vdpHeightMode]
	and r0,r0,#VDPMODE_HEIGHTMASK	;@ 224 and/or 240 height
	adr r2,BG_SCALING_TBL
	ldr r1,[r2,r0,lsr#2]
	str r1,bgScaleValue
	adr r2,BG_SCALING_WIN
	ldr r1,[r2,r0,lsr#2]
	str r1,WindowVValue
	adr r2,BG_SCALING_OFS
	ldr r1,[r2,r0,lsr#2]
	ldr r0,=yStart
	strb r1,[r0]
	bx lr
;@----------------------------------------------------------------------------
paletteInit:		;@ r0-r3 modified.
	.type   paletteInit STT_FUNC
;@ Called by ui.c:  void paletteInit(u8 gammaVal);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r9,lr}
	mov r7,r0					;@ Gamma value = 0 -> 4
	ldr vdpptr,=VDP0
	ldr r6,=mappedRGB
	ldrb r8,gColorValue			;@ Color value = 0 -> 4
	mov r4,#4096*2
	sub r4,r4,#2
noMap:							;@ Map BGR12  ->  BGR15
	mov r0,r4,lsr#1
	bl VDPGetRGBFromIndex
	mov r1,r8
	bl yConvert
	mov r9,r0

	mov r1,r7
	mov r0,r9,lsr#16
	bl gammaConvert
	mov r5,r0

	mov r0,r9,lsr#8
	and r0,r0,#0xFF
	bl gammaConvert
	orr r5,r0,r5,lsl#5

	and r0,r9,#0xFF
	bl gammaConvert
	orr r5,r0,r5,lsl#5

	strh r5,[r6,r4]
	subs r4,r4,#2
	bpl noMap
	ldmfd sp!,{r4-r9,lr}
	bx lr

;@----------------------------------------------------------------------------
mapSGPalette:
	.type   mapSGPalette STT_FUNC
;@ Called by ui.c:  void mapSGPalette(u8 gammaVal);
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	mov r10,r0					;@ Gamma value = 0 -> 4
	ldr vdpptr,=VDP0
	ldr r7,=EMUPALBUFF+0x80
	ldr r8,=EMUPALBUFF+0x202
	ldr r9,=BG_PALETTE+0x202
	mov r4,#16
mapSGLoop:						;@ Map RGB24  ->  BGR15
	rsb r0,r4,#16
	bl VDPGetRGBFromIndexSG
	ldrb r1,gColorValue
	bl yConvert
	mov r11,r0

	mov r1,r10
	mov r0,r11,lsr#16
	bl gammaConvert
	mov r5,r0

	mov r0,r11,lsr#8
	and r0,r0,#0xff
	bl gammaConvert
	orr r5,r0,r5,lsl#5

	and r0,r11,#0xff
	bl gammaConvert
	orr r5,r0,r5,lsl#5

	strh r5,[r7],#2
	strh r5,[r8],#0x20
	strh r5,[r9],#0x20
	subs r4,r4,#1
	bne mapSGLoop
	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
yPrefix:					;@ Takes r0=BGR12, outputs r0=BGR24
;@----------------------------------------------------------------------------
	mov r2,r0,lsr#8				;@ Blue
	and r1,r0,#0xF0				;@ Green
	and r0,r0,#0x0F				;@ Red
	orr r0,r0,r1,lsl#8
	orr r0,r0,r2,lsl#16
	orr r0,r0,r0,lsl#4
;@----------------------------------------------------------------------------
yConvert:					;@ r0=BGR24, r1=color 0-4, outputs r0=BGR24
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5}
	mov r3,r0,lsr#16
	mov r2,r0,lsr#8
	and r2,r2,#0xFF
	and r0,r0,#0xFF

	mov r5,#77
	mul r4,r5,r0				;@ Red
	mov r5,#151
	mla r4,r5,r2,r4				;@ Green
	mov r5,#29
	mla r4,r5,r3,r4				;@ Blue

	rsb r5,r1,#4
	mul r4,r5,r4				;@ B&W
	orr r0,r0,r0,lsl#8
	mla r0,r1,r0,r4
	mov r0,r0,lsr#10

	orr r3,r3,r3,lsl#8
	mla r3,r1,r3,r4
	mov r3,r3,lsr#10

	orr r2,r2,r2,lsl#8
	mla r2,r1,r2,r4
	mov r2,r2,lsr#10

	orr r0,r0,r2,lsl#8
	orr r0,r0,r3,lsl#16

	ldmfd sp!,{r4-r5}
	bx lr
;@----------------------------------------------------------------------------
gPrefix:
	orr r0,r0,r0,lsl#4
;@----------------------------------------------------------------------------
gammaConvert:	;@ Takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;@----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr
;@----------------------------------------------------------------------------
paletteTxGGSG:				;@ For SG modes on GG
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r5}
	ldr r2,=EMUPALBUFF+2
	add r3,r2,#0x80
	ldr r4,=EMUPALBUFF+0x202
	add r5,r4,#0x20
	mov r1,#0xf
ggSGLoop:
	ldrh r0,[r2],#2
	strh r0,[r3],#2
	ldrh r0,[r4],#2
	strh r0,[r5],#0x20
	subs r1,r1,#1
	bne ggSGLoop

	ldmfd sp!,{r4-r5}
	bx lr

	.pool

#ifdef NDS
	.section .itcm, "ax", %progbits		;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For everything else
#endif
	.align 2
;@----------------------------------------------------------------------------
paletteTxAll:				;@ Called from ui.c
	.type   paletteTxAll STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,lr}
	ldr r0,=EMUPALBUFF
	ldr r1,=VDP0+vdpPaletteRAM
	ldr r2,=mappedRGB
	ldr r7,=paletteMask
	ldr r5,[r7]
	add r3,r0,#0x40
	add r12,r0,#480
	bl copyPalette

	ldr r0,=0x7FFF
	str r0,[r7]					;@ Restore paletteMask
	ldmfd sp!,{r4-r7,lr}
	bx lr

copyPalette:
	mov r6,#0x3E
txLoop:
	movs r4,r6,lsl#27
	ldrh r4,[r1,r6]
	mov r4,r4,lsl#1
	ldrh r4,[r2,r4]
	and r4,r4,r5				;@ Palette mask for anaglyph 3D.
	strhne r4,[r0,r6]			;@ Bgtile palette
	strheq r4,[r3,r6]			;@ Background palette
	strhcs r4,[r12,r6]			;@ Sprite palette

	subs r6,r6,#2
	bpl txLoop
	bx lr

;@----------------------------------------------------------------------------
scaleBuffer3:
scaleLoop3:
	ldrb r4,[r1,r3,lsl#1]
	add r4,r4,r8
	mov r5,r4
	mov r9,r4
	stmia r0!,{r4,r5,r9}
	subs r6,r6,r6,lsl#16
	subcs r6,r6,r6,lsl#16
	addcs r8,r8,#0x10000
	adcs r3,r3,#1
	subcs r8,r8,r7,lsl#16
	subs r2,r2,#1
	bne scaleLoop3
	bx lr
;@----------------------------------------------------------------------------
scaleBuffer4:
	stmfd sp!,{r10}
	sub r10,r8,r4,lsl#16
	bic r10,r10,#0xFF
scaleLoop4:
	ldrb r4,[r1,r3,lsl#1]
	add r4,r4,r8
	mov r5,r4
	mov r9,r4
	sub r11,r4,r10
	stmia r0!,{r4,r5,r9,r11}
	subs r6,r6,r6,lsl#16
	subcs r6,r6,r6,lsl#16
	addcs r8,r8,#0x10000
	adcs r3,r3,#1
	subcs r8,r8,r7,lsl#16
	subcs r10,r10,r7,lsl#16
	subs r2,r2,#1
	bne scaleLoop4
	ldmfd sp!,{r10}
	bx lr

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
vblIrqHandler:
	.type vblIrqHandler STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}
	bl soundSwapBuffers
	bl calculateFPS
	ldr vdpptr,=VDP0

	ldrb r3,[vdpptr,#vdpYScrollBak1]
	ldr r7,[vdpptr,#vdpScrollMask]
	add r5,vdpptr,#scrollBuff
	ldr r4,=yStart
	ldrsb r4,[r4]
	add r5,r5,r4,lsl#1
	adds r3,r3,r4
	addmi r3,r3,r7

	ldr r6,bgScaleValue

	mul r1,r6,r3
	beq noLoop
	sub r6,r6,r1,lsl#16
	cmn r6,r6,lsl#16
	mov r1,#0
	movcc r1,#1
@	rsbs r1,r3,#0
@	bpl noLoop
@setLoop:
@	adds r6,r6,r6,lsl#16
@	adcs r1,r1,#1
@	bmi setLoop					;@ r1 will come out as 0 or 1.
noLoop:

	ldr r0,gFlicker
	eors r0,r0,r0,lsl#31
	str r0,gFlicker
	bpl noJump
	subs r6,r6,r6,lsl#16
	movcs r1,#1
noJump:
	add r5,r5,r1,lsl#1
	add r3,r3,r1
	cmp r1,#0
	subne r6,r6,r6,lsl#16

	ldr r0,=selectedMenu
	ldr r0,[r0]
	ldrb r10,[vdpptr,#vdpMode1]
	cmp r0,#0
	bicne r10,r10,#0x80

	ldr r0,=DMA0Buff
	mov r8,#(GAME_WIDTH-SCREEN_WIDTH)/2
	orr r8,r8,r3,lsl#16
	subs r3,r3,r7
	subpl r3,r3,r7
	subpl r8,r8,r7,lsl#16
	sub r5,r5,r3,lsl#1
	add r1,r5,#1
	mov r2,#SCREEN_HEIGHT
	tst r10,#0x80				;@ Columns 24-31 locked?
	adr lr,scaleRet
	beq scaleBuffer3
	bne scaleBuffer4
scaleRet:

	mov r8,#REG_BASE
	strh r8,[r8,#REG_DMA0CNT_H]	;@ DMA0 stop

	add r0,r8,#REG_DMA0SAD
	ldr r1,=DMA0Buff
;@	mov r1,r1					;@ Setup DMA buffer for scrolling:
	tst r10,#0x80				;@ Columns 24-31 locked?
	ldmiaeq r1!,{r3-r5}			;@ Read
	ldmiane r1!,{r3-r6}			;@ Read
	add r2,r8,#REG_BG0HOFS		;@ DMA0 always goes here
	stmiaeq r2,{r3-r5}			;@ Set 1st value manually, HBL is AFTER 1st line
	stmiane r2,{r3-r6}			;@ Set 1st value manually, HBL is AFTER 1st line
	ldr r3,=0xA6600003			;@ noIRQ hblank 32bit repeat incsrc inc_reloaddst, 3 word
	addne r3,r3,#1
	stmia r0,{r1-r3}			;@ DMA0 go

	add r0,r8,#REG_DMA3SAD

	ldr r1,[vdpptr,#vdpDMAOAMBuffer]	;@ DMA3 src, OAM transfer:
	mov r2,#OAM					;@ DMA3 dst
	mov r3,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r3,r3,#0x100			;@ 128 sprites (1024 bytes)
	stmia r0,{r1-r3}			;@ DMA3 go

	ldr r1,=EMUPALBUFF			;@ DMA3 src, Palette transfer:
	mov r2,#BG_PALETTE			;@ DMA3 dst
	mov r3,#0x84000000			;@ noIRQ 32bit incsrc incdst
	orr r3,r3,#0x100			;@ 256 words (1024 bytes)
	stmia r0,{r1-r3}			;@ DMA3 go

	ldr r2,[vdpptr,#vdpBgrMapOfs0]
	add r0,r2,#0x0005
	strh r0,[r8,#REG_BG0CNT]
	ldr r3,=0x02870102
	add r0,r2,r3
	ldr r1,[vdpptr,#vdpBgrTileOfs]
	add r0,r0,r1,lsr#12
	strh r0,[r8,#REG_BG1CNT]
	ldreq r0,=GFX_BG3CNT		;@ No side panel
	ldrheq r0,[r0]
	strh r0,[r8,#REG_BG3CNT]
	add r0,r2,r3,lsr#16
	strh r0,[r8,#REG_BG2CNT]

	mov r0,#0x003F
	ldrb r1,gGfxMask
	bic r0,r0,r1
	ldrb r1,[vdpptr,#vdpMode2Bak2]
	tst r1,#0x40
	biceq r0,r0,#0x0017			;@ Turn off sprites and bg
	orr r0,r0,r0,lsl#8

	tst r10,#0x80				;@ Columns 24-31 locked?
	bicne r0,r0,#0x0308

	strh r0,[r8,#REG_WININ]

	tst r1,#0x20				;@ Column 0 blanked?
	ldreq r0,Window0HValue_normal
	ldrne r0,Window0HValue_col0
	strh r0,[r8,#REG_WIN0H]
	ldr r0,Window1HValue
	strh r0,[r8,#REG_WIN1H]
	ldr r0,WindowVValue
	strh r0,[r8,#REG_WIN0V]
	strh r0,[r8,#REG_WIN1V]

@	ldrh r0,DisplayControl		;@ 1d sprites, Win0, OBJ, BG0/1/2/3 enable. mode0.
@	orrne r0,r0,#0x6000			;@ Enable Win0 & 1
@	ldrb r2,[vdpptr,#vdpMode2Bak2]
@	tst r2,#0x40
@	biceq r0,r0,#0x1700			;@ Turn off sprites and bg
@	ldrb r2,gfxLayerMask
@	bic r0,r0,r2,lsl#8

	ldrb r4,[vdpptr,#vdpTVType]
	bl scanKeys
	bl soundRender
	ldmfd sp!,{r4-r11,lr}
	bx lr
;@----------------------------------------------------------------------------
DisplayControl:
	.short 0x3F40,0
Window0HValue_normal:
	.long 0x00C0
Window0HValue_col0:
	.long 0x00C0
Window1HValue:
	.long 0xC000
WindowVValue:
	.long SCREEN_HEIGHT
;@----------------------------------------------------------------------------
bgScaleValue:	.long 0x00002B10			;@ was 0x2AAB

gFlicker:		.byte 1
				.skip 2
gTwitch:		.byte 0

gScaling:		.byte SCALED
gGfxMask:		.byte 0
gColorValue:	.byte 4
bColor:			.byte 0
g3DEnable:		.byte 1
				.skip 3
;@----------------------------------------------------------------------------
endFrame:					;@ Called at screen end (~line 192)	(r0 & r2 safe to use)
;@----------------------------------------------------------------------------
	stmfd sp!,{r1,r3-r11,lr}

	ldrb r1,[vdpptr,#vdpXScroll]
	bl VDPReg08W
;@--------------------------
	bl applyScaling
	adr lr,sDMARet
	ldrb r0,[vdpptr,#vdpRealMode]
	cmp r0,#VDPMODE_4
	bmi sprDMADoM2
	beq sprDMADo1
sDMARet:
;@--------------------------
	ldrb r4,[vdpptr,#vdpType]
	cmp r4,#VDPSega3155378		;@ HW_GG
	bleq paletteTxGGSG
;@--------------------------

	ldr r2,=EMUPALBUFF
	ldr r1,=bColor
	ldrb r0,[r1]
	cmp r0,#0
	cmpeq r4,#VDPSega3155378	;@ HW_GG
	beq setBc
	ldrb r0,[vdpptr,#vdpRealMode]
	add r3,r2,#0x80				;@ SG palette
	cmp r0,#0x04				;@ Mode4?
	addpl r3,r3,#0x180			;@ Use normal palette
	ldrb r4,[vdpptr,#vdpBDColor]
	and r1,r4,#0xF				;@ Border color
	add r1,r3,r1,lsl#1
	ldrh r0,[r1]

	mov r1,r4,lsr#4				;@ Text color for TMS9918 modes.
	add r1,r3,r1,lsl#1
	ldrh r1,[r1]
	strhmi r1,[r2,#64+2]
setBc:
	strh r0,[r2]				;@ Color 0


	ldrb r0,[vdpptr,#vdpMode2Bak1]
	strb r0,[vdpptr,#vdpMode2Bak2]

	ldr r0,[vdpptr,#vdpDMAOAMBuffer]
	ldr r1,[vdpptr,#vdpTmpOAMBuffer]
	str r0,[vdpptr,#vdpTmpOAMBuffer]
	str r1,[vdpptr,#vdpDMAOAMBuffer]

	ldr r0,[vdpptr,#vdpBgrMapOfs0]
	ldr r1,[vdpptr,#vdpBgrMapOfs1]
	str r0,[vdpptr,#vdpBgrMapOfs1]
	str r1,[vdpptr,#vdpBgrMapOfs0]

	ldr r0,=windowTop			;@ Load wtop, store in wtop+4.......load wtop+8, store in wtop+12
	ldmia r0,{r1-r3}			;@ Load with post increment
	stmib r0,{r1-r3}			;@ Store with pre increment


	ldr r0,frameTotal
	add r0,r0,#1
	str r0,frameTotal
	ldmfd sp!,{r1,r3-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
VDP0SetMode:
	.type VDP0SetMode STT_FUNC
;@----------------------------------------------------------------------------
	ldr vdpptr,=VDP0
	b VDPSetMode
;@----------------------------------------------------------------------------
spriteScannerStart:
	stmfd sp!,{r3-r10}
;@	mov r11,r11

	ldr r9,[vdpptr,#VRAMPtr]
	ldrb r0,[vdpptr,#vdpSATOffset]
	and r0,r0,#0x7E
	add r9,r9,r0,lsl#7
	add r8,r9,#0x80+0x80

	ldrb r10,[vdpptr,#vdpSPROffset]	;@ First or second half of VRAM for sprites?
	and r10,r10,#4

	ldr r2,[vdpptr,#vdpSprStop]
	cmp r2,#0xD0
	moveq r2,#0xFFFFFFD0

	ldr r4,=SMSOAMBuff
	add r5,r4,#0x80
	ldrb r3,[vdpptr,#vdpScrStartLine]
	sub r1,r3,#0xF

	mov r6,#0
	mov r7,#-0x80
ss1Loop:
	ldrsb r0,[r9],#1			;@ MasterSystem OBJ, r0=Ypos.
	cmp r0,r2
	beq ss1End
	cmp r0,r3
	bgt ss1Chk
	cmp r0,r1
	bpl ss1Add
ss1Chk:
	adds r7,r7,#2
	bne ss1Loop
ss1End:
	str r6,smsOamIndex
	strb r2,[r4,r6]

	ldmfd sp!,{r3-r10}
	bx lr

ss1Add:
	strb r0,[r4,r6]
	ldrh r0,[r8,r7]				;@ MasterSystem OBJ, r0=Tile,Xpos.
	orr r0,r0,r10,lsl#14
	str r0,[r5,r6,lsl#2]
	cmp r6,#0x7F
	addmi r6,r6,#1
	bmi ss1Chk
	b ss1End

;@----------------------------------------------------------------------------
spriteScanner:
	stmfd sp!,{r4-r10}

	ldr r9,[vdpptr,#VRAMPtr]
	ldrb r0,[vdpptr,#vdpSATOffset]
	and r0,r0,#0x7E
	add r9,r9,r0,lsl#7
	add r8,r9,#0x80+0x80

	ldrb r10,[vdpptr,#vdpSPROffset]	;@ First or second half of VRAM for sprites?
	and r10,r10,#4

	ldr r2,[vdpptr,#vdpSprStop]
	ldr r4,=SMSOAMBuff
	add r5,r4,#0x80
;@	ldr r1,[vdpptr,#vdpScanline]	;@ r1 is allready scanline.
	ldr r6,smsOamIndex
	mov r7,#-0x80
ss0Loop:
	ldrb r0,[r9],#1					;@ MasterSystem OBJ, r0=Ypos.
	cmp r0,r2
	cmpne r0,r1
	beq ss0Add
ss0Chk:
	adds r7,r7,#2
	bne ss0Loop
ss0End:
	str r6,smsOamIndex
	strb r2,[r4,r6]
	ldmfd sp!,{r4-r10}
	b sprsScanlineHook

ss0Add:
	cmp r0,r2
	beq ss0End

	strb r0,[r4,r6]
	ldrh r0,[r8,r7]					;@ MasterSystem OBJ, r4=Tile,Xpos.
	orr r0,r0,r10,lsl#14
	str r0,[r5,r6,lsl#2]
	cmp r6,#0x7F
	addmi r6,r6,#1
	bmi ss0Chk
	b ss0End

#ifdef NDS
	.section .itcm, "ax", %progbits		;@ For the NDS ARM9
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For everything else
#endif
	.align 2
;@----------------------------------------------------------------------------
;@sprDMADo:					;@ Called from endFrame. YATX
;@----------------------------------------------------------------------------
#define PRIORITY	(0x800)		// 0x800=AGB OBJ priority 2

sprDMADo0:						;@ Called from earlyFrame if no spr scanning.
	ldr r2,[vdpptr,#vdpTmpOAMBuffer]	;@ Destination
	b sprPassDoM4

sprDMADo1:						;@ Called from endFrame.
	ldr r2,[vdpptr,#vdpTmpOAMBuffer]	;@ Destination
	ldrb r0,[vdpptr,#vdpSprScan]
	cmp r0,#0
	bne pSprDo
	add r2,r2,#0x200


sprPassDoM4:
	mov r8,#64					;@ Number of sprites
	ldr r10,[vdpptr,#VRAMPtr]
	ldrb r0,[vdpptr,#vdpSATOffset]
	and r0,r0,#0x7E
	add r10,r10,r0,lsl#7
	mov r6,#0x100				;@ r6= scale obj

	ldr r11,[vdpptr,#vdpSprStop]
	ldrb r0,[vdpptr,#vdpMode2]
	movs r0,r0,lsl#31			;@ Double pixels/8x16 size
	orrmi r6,r6,#0x00000200		;@ Doublesize
	orrmi r6,r6,#0x04000000		;@ Scaling param
	orrcs r6,r6,#0x00008000		;@ 8x16 shape
	orrcs r6,r6,#0x02000000		;@ Scaling param

	ldr r5,=bgScaleValue
	ldr r5,[r5]
	add r5,r5,#1
dm4_1:
	add r9,r10,#0x80
	mov r7,#PRIORITY+0x200			;@ Spr tiles are at the end of Spr RAM.
	ldrb r0,[vdpptr,#vdpSPROffset]	;@ First or second half of VRAM for sprites?
	tst r0,#4
	orrne r7,r7,#0x100
	ldrb r1,[vdpptr,#vdpMode1]
	and r1,r1,#8				;@ EC
	add r1,r1,#(GAME_WIDTH-SCREEN_WIDTH)/2
	mov r1,r1,lsl#23
dm4_2:
	ldrb r0,[r10],#1			;@ MasterSystem OBJ, r0=Ypos.
	ldrh r4,[r9],#2				;@ MasterSystem OBJ, r4=Tile,Xpos.
	cmp r0,r11
	beq dm4_3					;@ Skip the rest if sprite Y=208

	cmp r0,#0xEF
	subpl r0,r0,#0x100
	add r0,r0,#1
	ldr r3,=yStart
	ldrsb r3,[r3]
	sub r0,r0,r3

	mov r3,#4
	tst r6,#0x02000000
	movne r3,r3,lsl#1
	tst r6,#0x04000000
	movne r3,r3,lsl#1
	add r0,r0,r3

	mul r0,r5,r0
	sub r0,r0,r3,lsl#16
	and r0,r0,#0xFF0000
	orr r0,r6,r0,lsr#16			;@ Size plus scaling?
	and r3,r4,#0xFF
	rsb r3,r1,r3,lsl#23
	orr r0,r0,r3,lsr#7
	str r0,[r2],#4				;@ Store OBJ Atr 0,1. Xpos, ypos, flip, scale/rot, size, shape.

	bic r4,r4,r6,lsr#7			;@ Only even tiles in 8x16 mode
	orr r0,r7,r4,lsr#8			;@ Priority & tile offset
	strh r0,[r2],#4				;@ Store OBJ Atr 2. Pattern, palette.
	subs r8,r8,#1
	bne dm4_2
	bx lr

dm4_3:
	mov r0,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
dm4_4:
	str r0,[r2],#8
	subs r8,r8,#1
	bne dm4_4
	bx lr

#ifdef GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
pSprDo:
	ldr r8,smsOamIndex
	cmp r8,#0
	beq pSpr3
	ldr r10,=SMSOAMBuff

	mov r6,#0x100				;@ r6= scale obj

	ldr r11,[vdpptr,#vdpSprStop]
	ldrb r0,[vdpptr,#vdpMode2]
	movs r0,r0,lsl#31			;@ Double pixels/8x16 size
	orrmi r6,r6,#0x00000200		;@ Doublesize
	orrmi r6,r6,#0x04000000		;@ Scaling param
	orrcs r6,r6,#0x00008000		;@ 8x16 shape
	orrcs r6,r6,#0x02000000		;@ Scaling param

	ldr r5,bgScaleValue
	add r5,r5,#1
pSpr1:
	add r9,r10,#0x80
	mov r7,#PRIORITY
	ldrb r1,[vdpptr,#vdpMode1]
	and r1,r1,#8				;@ EC
	add r1,r1,#(GAME_WIDTH-SCREEN_WIDTH)/2
	mov r1,r1,lsl#23
pSpr2:
	ldrb r0,[r10],#1			;@ MasterSystem OBJ, r0=Ypos.
	ldr r4,[r9],#4				;@ MasterSystem OBJ, r4=Tile,Xpos.
	cmp r0,r11
	beq pSpr3					;@ Skip the rest if sprite Y=208

	cmp r0,#0xEF
	subpl r0,r0,#0x100
	add r0,r0,#1
	ldr r3,=yStart
	ldrsb r3,[r3]
	sub r0,r0,r3

	mov r3,#4
	tst r6,#0x02000000
	movne r3,r3,lsl#1
	tst r6,#0x04000000
	movne r3,r3,lsl#1
	add r0,r0,r3

	mul r0,r5,r0
	sub r0,r0,r3,lsl#16
	and r0,r0,#0xFF0000
	orr r0,r6,r0,lsr#16			;@ Size plus scaling?
	and r3,r4,#0xFF
	rsb r3,r1,r3,lsl#23
	orr r0,r0,r3,lsr#7
	str r0,[r2],#4				;@ Store OBJ Atr 0,1. Xpos, ypos, flip, scale/rot, size, shape.

	bic r4,r4,r6,lsr#7			;@ Only even tiles in 8x16 mode
	orr r0,r7,r4,lsr#8			;@ Priority & tile offset
	strh r0,[r2],#4				;@ Store OBJ Atr 2. Pattern, palette.
	subs r8,r8,#1
	bne pSpr2

pSpr3:
	ldr r0,smsOamIndex
	sub r8,r0,r8
	rsb r8,r8,#0x80
	mov r0,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
pSpr4:
	subs r8,r8,#1
	strpl r0,[r2],#8
	bhi pSpr4
	bx lr

;@----------------------------------------------------------------------------
sprDMADoM2:					;@ Called from endFrame.
;@----------------------------------------------------------------------------
	ldr r2,[vdpptr,#vdpTmpOAMBuffer]	;@ Destination

	ldrb r1,[vdpptr,#vdpSATOffset]
	ldr r10,[vdpptr,#VRAMPtr]
	and r1,r1,#0x7F
	add r10,r10,r1,lsl#7

	mov r6,#0x100				;@ r6= scale obj

	ldrb r1,[vdpptr,#vdpMode2]
	movs r1,r1,lsl#31			;@ Double pixels/16x16 size
	orrmi r6,r6,#0x00000200		;@ Doublesize
	orrmi r6,r6,#0x04000000		;@ Scaling param
	orrcs r6,r6,#0x00008000		;@ 8x16 shape
	orrcs r6,r6,#0x02000000		;@ Scaling param

	ldr r5,bgScaleValue
	add r5,r5,#1

	mov r8,#32					;@ Number of sprites
	cmp r0,#VDPMODE_1
	beq dm2_3					;@ No sprites in Mode1
	mov r7,#PRIORITY+0x300		;@ Tile nr offset
	mov r1,#0x10000000
dm2_2:
	ldr r4,[r10],#4				;@ MasterSystem OBJ, r0=Ypos.
	mov r0,r4,lsl#24
	cmp r0,#0xD0000000
	beq dm2_3					;@ Skip the rest if sprite Y=208
	and r9,r4,#0xFF00
	and r3,r1,r4,lsr#3			;@ EC early clock, x -=32.
	add r3,r3,#((GAME_WIDTH-SCREEN_WIDTH)/2)<<23
	rsb r9,r3,r9,lsl#15

	mov r0,r0,lsr#24
	cmp r0,#0xEF
	subpl r0,r0,#0x100
	add r0,r0,#1
	ldr r3,=yStart
	ldrsb r3,[r3]
	sub r0,r0,r3

	movs r3,r6,lsl#6			;@ 16x16 size + scaling?
	mov r3,#4					;@ Sprites are scaled around the center
	movmi r3,r3,lsl#1			;@ That's why this is needed
	movcs r3,r3,lsl#1
	add r0,r0,r3

	mul r0,r5,r0
	sub r0,r0,r3,lsl#16
	and r0,r0,#0xFF0000
	orr r0,r6,r0,lsr#16			;@ Size plus scaling?
	tst r4,#0xF000000			;@ Color 0 sprite = invisible.
	moveq r0,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
	orr r3,r0,r9,lsr#7
	str r3,[r2],#4				;@ Store OBJ Atr 0,1. Xpos, ypos, flip, scale/rot, size, shape.

	mov r4,r4,ror#24
	orr r3,r7,r4,lsr#24			;@ Tiles + tileoffset + priority
	orr r3,r3,r4,lsl#12			;@ Palette
	tst r6,#0x00008000			;@ 16x16 size?
	bicne r3,r3,#3				;@ Only even tiles in 16x16 mode
	strh r3,[r2],#4				;@ Store OBJ Atr 2. Pattern, palette.

	moveq r0,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
	addne r3,r3,#2				;@ Tile+2
	addne r9,r9,#0x04000000
	tstne r6,#0x00000200		;@ Zoom?
	addne r9,r9,#0x04000000
	orr r0,r0,r9,lsr#7
	str r0,[r2],#4				;@ Store OBJ Atr 0,1. Xpos, ypos, flip, scale/rot, size, shape.
	strh r3,[r2],#4				;@ Store OBJ Atr 2. Pattern, palette.

	subs r8,r8,#1
	bne dm2_2

dm2_3:
	add r8,r8,#32
	mov r0,#0x200+SCREEN_HEIGHT	;@ Double, y=SCREEN_HEIGHT
dm2_4:
	str r0,[r2],#8
	str r0,[r2],#8
	subs r8,r8,#1
	bne dm2_4
	bx lr

;@----------------------------------------------------------------------------
VDP0ScanlineBPReset:
	.type VDP0ScanlineBPReset STT_FUNC
;@----------------------------------------------------------------------------
	ldr vdpptr,=VDP0
	b VDPScanlineBPReset
;@----------------------------------------------------------------------------
VDP0SetSprScan:
	.type VDP0SetSprScan STT_FUNC
;@----------------------------------------------------------------------------
	ldr vdpptr,=VDP0
	b VDPSetSprScan
;@----------------------------------------------------------------------------
VDP0LatchHCounter:
;@----------------------------------------------------------------------------
	ldr vdpptr,=VDP0
	b VDPLatchHCounter

;@----------------------------------------------------------------------------

smsOamIndex:		.long 0
windowTop:			.long 0
wTop:
	.long 0,0,0		;@ windowtop  (this label too)   L/R scrolling in unscaled mode
frameTotal:			;@ let ui.c see frame count for savestates
	.long 0
paletteMask:		.long 0x7FFF

gfxState:
yStart:				.byte 0
SPRS:				.byte 0		;@ SpriteScanning On/Off
				.byte 0
				.byte 0
GFX_DISPCNT:
	.long 0
GFX_BG0CNT:
	.short 0
GFX_BG3CNT:
	.short 0


#ifdef NDS
	.section .sbss				;@ This is DTCM on NDS with devkitARM
#else
	.section .bss				;@ This is IWRAM on GBA with devkitARM
#endif
	.align 2
VDP0:
	.space vdpSize

#ifdef GBA
	.section .sbss				;@ This is EWRAM on GBA with devkitARM
#else
	.section .bss
#endif
	.align 2
VDPRAM:
	.space 0x4000
	.size VDPRAM, 0x4000

SMSOAMBuff:
	.space 0x280
OAMBuffer1:
	.space 0x400
OAMBuffer2:
	.space 0x400
DMA0Buff:
	.space SCREEN_HEIGHT*4*4
mappedRGB:
	.space 0x2000
EMUPALBUFF:
	.space 0x400
;@----------------------------------------------------------------------------
	.end
#endif // #ifdef __arm__
