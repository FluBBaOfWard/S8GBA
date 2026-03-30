#include <gba.h>
#include <string.h>

#include "Gui.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Main.h"
#include "FileHandling.h"
#include "Equates.h"
#include "Cart.h"
#include "Gfx.h"
#include "Sound.h"
#include "io.h"
#include "cpu.h"
#include "ARMZ80/Version.h"
#include "SegaVDP/Version.h"
#include "SN76496/Version.h"

#define EMUVERSION "V1.1.8 2026-03-29"

static void gammaChange(void);
static void machineSet(void);
static const char *getMachineText(void);
static void speedHackSet(void);
static const char *getSpeedHackText(void);
static void soundSet(void);
static const char *getSoundText(void);
static void stepFrameUI(void);
static void scalingSet(void);
static const char *getScalingText(void);
static void borderSet(void);
static void controllerSet(void);
static const char *getControllerText(void);
static void swapABSet(void);
static const char *getSwapABText(void);
static void bgrLayerSet(void);
static const char *getBgrLayerText(void);
static void sprLayerSet(void);
static const char *getSprLayerText(void);
static void spriteSet(void);
static void glassesSet(void);

static void countrySet(void);

static void updateGameInfo(void);

const MItem dummyItems[] = {
	{"", uiDummy},
};
const MItem mainItems[] = {
	{"File->", ui2},
	{"Controller->", ui3},
	{"Display->", ui4},
	{"Machine->", ui5},
	{"Settings->", ui6},
	{"Debug->", ui7},
	{"About->", ui8},
	{"Sleep", gbaSleep},
	{"Reset Console", resetConsole},
	{"Quit Emulator", ui10},
};
const MItem fileItems[] = {
	{"Load Game->", selectGame},
	{"Load State", loadState},
	{"Save State", saveState},
	{"Save Settings", saveSettings},
	{"Eject Game", ejectCart},
	{"Reset Game", resetConsole},
};
const MItem ctrlItems[] = {
	{"B Autofire: ", autoBSet, getAutoBText},
	{"A Autofire: ", autoASet, getAutoAText},
	{"Controller: ", controllerSet, getControllerText},
	{"Swap A-B:   ", swapABSet, getSwapABText},
};
const MItem displayItems[] = {
	{"Display: ", scalingSet, getScalingText},
	{"Scaling: ", flickSet, getFlickText},
	{"Gamma: ", gammaChange, getGammaText},
	{"GG Border:", borderSet},
	{"Perfect Sprites:", spriteSet},
	{"3D Display:", glassesSet},
};
const MItem machineItems[] = {
	{"Region:", countrySet},
	{"Machine: ", machineSet, getMachineText},
	{"Cpu Speed Hacks: ", speedHackSet, getSpeedHackText},
	{"Sound: ", soundSet, getSoundText},
};
const MItem setItems[] = {
	{"Speed: ", speedSet, getSpeedText},
	{"Autoload State: ", autoStateSet, getAutoStateText},
	{"Autosave Settings: ", autoSettingsSet, getAutoSettingsText},
	{"Autopause Game: ", autoPauseGameSet, getAutoPauseGameText},
	{"EWRAM Overclock: ", ewramSet, getEWRAMText},
	{"Autosleep: ", sleepSet, getSleepText},
};
const MItem debugItems[] = {
	{"Debug Output: ", debugTextSet, getDebugText},
	{"Disable Background: ", bgrLayerSet, getBgrLayerText},
	{"Disable Sprites: ", sprLayerSet, getSprLayerText},
	{"Step Frame", stepFrameUI},
};
const MItem fnList9[] = {
	{"", quickSelectGame},
};
const MItem quitItems[] = {
	{"Yes", exitEmulator},
	{"No", backOutOfMenu},
};

const Menu menu0 = MENU_M("", uiNullNormal, dummyItems);
Menu menu1 = MENU_M("Main Menu", uiAuto, mainItems);
const Menu menu2 = MENU_M("File Handling", uiAuto, fileItems);
const Menu menu3 = MENU_M("Controller Settings", uiAuto, ctrlItems);
const Menu menu4 = MENU_M("Display Settings", uiAuto, displayItems);
const Menu menu5 = MENU_M("Machine Settings", uiAuto, machineItems);
const Menu menu6 = MENU_M("Other Settings", uiAuto, setItems);
const Menu menu7 = MENU_M("Debug", uiAuto, debugItems);
const Menu menu8 = MENU_M("About", uiAbout, dummyItems);
const Menu menu9 = MENU_M("Load game", uiLoadGame, fnList9);
const Menu menu10 = MENU_M("Quit Emulator?", uiAuto, quitItems);

const Menu *const menus[] = {&menu0, &menu1, &menu2, &menu3, &menu4, &menu5, &menu6, &menu7, &menu8, &menu9, &menu10 };

EWRAM_BSS char gameInfoString[32];

char *const ctrlTxt[]   = {"1P","2P"};
char *const dispTxt[]   = {"Unscaled","Scaled"};

const char *const machTxt[] = {"Auto", "SG-1000", "SC-3000", "OMV", "SG-1000 II", "Mark III", "Master System", "Master System 2", "Game Gear", "Mega Drive", "Coleco", "MSX", "Sord M5"};
const char *const bordTxt[]  = {"Black", "Border Color", "None"};
const char *const cntrTxt[] = {"Auto", "US (NTSC)", "Europe (PAL)", "Japan (NTSC)"};

/// This is called at the start of the emulator
void setupGUI() {
//	keysSetRepeat(25, 4);	// Delay, repeat.
	menu1.itemCount = ARRSIZE(mainItems) - (enableExit?0:1);
	closeMenu();
}

/// This is called when going from emu to ui.
void enterGUI() {
}

/// This is called going from ui to emu.
void exitGUI() {
	setupBorderPalette();
}

void quickSelectGame() {
	openMenu();
	selectGame();
	closeMenu();
}

void uiNullNormal() {
	uiNullDefault();
}

void uiAbout() {
	setupSubMenuText();
	updateGameInfo();
	drawText("B:        SMS Button 1", 3);
	drawText("A:        SMS Button 2", 4);
	drawText("Start:    Pause Button", 5);
	drawText("Select:   Reset", 6);
	drawText("DPad:     Joystick", 7);

	drawText(gameInfoString, 10);

	drawText("S8GBA       " EMUVERSION, 16);
	drawText("ARMZ80      " ARMZ80VERSION, 17);
	drawText("SEGAVDP     " SEGAVDPVERSION, 18);
	drawText("SNGG76496   " ARMSN76496VERSION, 19);
}

void uiLoadGame() {
	setupSubMenuText();
}

void nullUINormal(int key) {
}

void nullUIDebug(int key) {
}

void resetConsole() {
	checkMachine();
	loadCart(0);
}

void updateGameInfo() {
	char catalog[8];
//	strlMerge(gameInfoString, "Game Name: ", ngpHeader->name, sizeof(gameInfoString));
	strlcat(gameInfoString, " #", sizeof(gameInfoString));
//	short2HexStr(catalog, ngpHeader->catalog);
	strlcat(gameInfoString, catalog, sizeof(gameInfoString));
}

/**
 * Handles debug output for SDSC
 */
void sdscHandler(const unsigned char sdscChar) {
/*	sdscBuffer[sdscPtr++] = sdscChar;
	if (sdscChar == 10 || sdscChar == 13 || sdscPtr >= 79) {
		sdscBuffer[sdscPtr] = 0;
		sdscPtr = 0;
		debugOutput(sdscBuffer);
	}*/
}

//---------------------------------------------------------------------------------
void debugIO(u16 port, u8 val, const char *message) {
	char debugString[32];

	debugString[0] = 0;
	strlcat(debugString, message, sizeof(debugString));
	short2HexStr(&debugString[strlen(debugString)], port);
	strlcat(debugString, " val:", sizeof(debugString));
	char2HexStr(&debugString[strlen(debugString)], val);
	debugOutput(debugString);
}
//---------------------------------------------------------------------------------
void debugIOUnimplR(u16 port) {
	debugIO(port, 0, "Unimpl R port:");
}
void debugIOUnimplW(u8 val, u16 port) {
	debugIO(port, val, "Unimpl W port:");
}
void debugUndefinedInstruction() {
	debugOutput("Undefined Instruction.");
}
void debugCrashInstruction() {
	debugOutput("CPU Crash!");
}

void stepFrameUI() {
	stepFrame();
	setupMenuPalette();
}
//---------------------------------------------------------------------------------
/// Switch between Player 1 & Player 2 controls
void controllerSet() {				// See io.s: refreshEMUjoypads
	joyCfg ^= 0x20000000;
}
const char *getControllerText() {
	return ctrlTxt[(joyCfg>>29)&1];
}

/// Swap A & B buttons
void swapABSet() {
	joyCfg ^= 0x400;
}
const char *getSwapABText() {
	return autoTxt[(joyCfg>>10)&1];
}

/// Turn on/off scaling
void scalingSet(){
	gScaling ^= 0x01;
//	refreshGfx();
}
const char *getScalingText() {
	return dispTxt[gScaling];
}

/// Change gamma (brightness)
void gammaChange() {
	gammaSet();
	paletteInit(gGammaValue);
	paletteTxAll();					// Make new palette visible
	setupMenuPalette();
}

void colorSet() {
	gColorValue++;
	if (gColorValue > 4) {
		gColorValue = 0;
	}
	paletteInit(gGammaValue);
	mapSGPalette(gGammaValue);
	paletteTxAll();					// Make new palette visible
}

void borderSet() {
	bColor++;
	if (bColor > 2) {
		bColor = 0;
	}
	makeBorder();
}

/// Turn on/off rendering of background
void bgrLayerSet() {
	gGfxMask ^= 0x02;
}
const char *getBgrLayerText() {
	return autoTxt[(gGfxMask>>1)&1];
}
/// Turn on/off rendering of sprites
void sprLayerSet() {
	gGfxMask ^= 0x10;
}
const char *getSprLayerText() {
	return autoTxt[(gGfxMask>>4)&1];
}

void spriteSet() {
	SPRS ^= 1;
}

void glassesSet() {
	g3DEnable ^= 1;
}

void countrySet() {
	int i;
	gRegion = (gRegion+1)&3;
	i = (gRegion)-1;
	if (i < 0) {
		i = 0;
	}
	if (gMachine == HW_GG) {
		i &= ~PALTIMING;
	}
	gEmuFlags = (gEmuFlags & ~3) | i;
//	soundSetFrequency();
	VDP0ScanlineBPReset();
	setupScaling();
	VDP0ApplyScaling();
	VDP0SetMode();
}

void machineSet() {
	gMachineSet++;
	if (gMachineSet >= HW_SELECT_END) {
		gMachineSet = 0;
	}
}
const char *getMachineText() {
	return machTxt[gMachineSet];
}

void speedHackSet() {
	emuSettings ^= ALLOW_SPEED_HACKS;
//	hacksInit();
}
const char *getSpeedHackText() {
	return autoTxt[(emuSettings & ALLOW_SPEED_HACKS)>>17];
}

void soundSet() {
	soundMode++;
	if (soundMode > 1) {
		soundMode = 0;
	}
	soundInit();
}
const char *getSoundText() {
	return autoTxt[soundMode&1];
}
