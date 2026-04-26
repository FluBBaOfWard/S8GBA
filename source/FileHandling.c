#include <gba.h>
#include <string.h>

#include "FileHandling.h"
#include "Emubase.h"
#include "Main.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Shared/AsmExtra.h"
#include "Gui.h"
#include "Equates.h"
#include "Cart.h"
#include "Gfx.h"
#include "io.h"

/// Used for GBA emulators or flash-carts to choose save type.
const char *const SRAM_TAG = "SRAM_Vnnn";

EWRAM_BSS int selectedGame = 0;
EWRAM_BSS ConfigData cfg;

//---------------------------------------------------------------------------------
void applyConfigData(void) {
	emuSettings  = cfg.emuSettings & ~EMUSPEED_MASK; // Clear speed setting.
	SPRS         = cfg.sprites;
	g3DEnable    = cfg.glasses;
	gConfigSet   = cfg.config;
	gScalingSet  = cfg.scaling & 3;
	gFlicker     = cfg.flicker & 1;
	gGammaValue  = cfg.gammaValue & 0x7;
	gColorValue  = (cfg.gammaValue >> 4) & 0x7;
	sleepTime    = cfg.sleepTime;
	joyCfg       = (joyCfg & ~0x400) | ((cfg.controller & 1) << 10);
	VDP0SetSprScan(SPRS);
}

void updateConfigData(void) {
	strcpy(cfg.magic, "cfg");
	cfg.emuSettings = emuSettings & ~EMUSPEED_MASK; // Clear speed setting.
	cfg.sprites     = SPRS;
	cfg.glasses     = g3DEnable;
	cfg.config      = gConfigSet;
	cfg.scaling     = gScalingSet & 3;
	cfg.flicker     = gFlicker & 1;
	cfg.gammaValue  = (gGammaValue & 0x7) | ((gColorValue & 0x7) << 4);
	cfg.sleepTime   = sleepTime;
	cfg.controller  = (joyCfg>>10) & 1;
}

void initSettings(void) {
	memset(&cfg, 0, sizeof(cfg));
	cfg.emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM | AUTOSLEEP_OFF | ENABLE_LIVE_UI;
	cfg.sprites     = 0;		// SpriteScanning On/Off;
	cfg.glasses     = 1;
	cfg.config      = 0x80;		// config, bit 7=BIOS on/off, bit 6=X as GG Start, bit 5=Select as Reset, bit 4=R as FastForward
	cfg.scaling     = SCALED;
	cfg.flicker     = 1;
	cfg.gammaValue  = 0x40;		// ColorValue = 4
	cfg.sleepTime   = 0x7F000000;	// 360 days...

	applyConfigData();
}

int loadSettings() {
	bytecopy_((u8 *)&cfg, (u8 *)SRAM+0x10000-sizeof(ConfigData), sizeof(ConfigData));
	if (strstr(cfg.magic,"cfg")) {
		applyConfigData();
		infoOutput("Settings loaded.");
		return 0;
	}
	else {
		updateConfigData();
		infoOutput("Error in settings file.");
	}
	return 1;
}
void saveSettings() {
	updateConfigData();

	bytecopy_((u8 *)SRAM+0x10000-sizeof(ConfigData), (u8 *)&cfg, sizeof(ConfigData));
	infoOutput("Settings saved.");
}

int loadNVRAM() {
	return 0;
}

void saveNVRAM() {
}

void loadState(void) {
//	unpackState(testState);
	infoOutput("Loaded state.");
}
void saveState(void) {
//	packState(testState);
	infoOutput("Saved state.");
}

//---------------------------------------------------------------------------------
bool loadGame(const RomHeader *rh) {
	if (rh) {
		return loadROM((const u8 *)rh + sizeof(RomHeader), rh->filesize);
	}
	return true;
}

//---------------------------------------------------------------------------------
bool loadROM(const u8 *rom, int size) {
	selectedGame = selected;
	cls(0);
	gRomSize = size;
	romSpacePtr = rom;
//	tlcs9000MemInit(romSpacePtr);
	checkMachine();
	setEmuSpeed(0);
	loadCart(0);
	gameInserted = true;
	if (emuSettings & AUTOLOAD_NVRAM) {
		loadNVRAM();
	}
	if (emuSettings & AUTOLOAD_STATE) {
		loadState();
	}
	closeMenu();
	return false;
}

void selectGame() {
	pauseEmulation = true;
	ui9();
	const RomHeader *rh = browseForFile();
	if (loadGame(rh)) {
		backOutOfMenu();
	}
	else {
		pauseEmulation = false;
	}
}

//---------------------------------------------------------------------------------
/*void ejectCart() {
	gRomSize = 0x200000;
	romSpacePtr = (u8 *)ejectCart;
	tlcs9000MemInit(romSpacePtr);
	gameInserted = false;
}*/

//---------------------------------------------------------------------------------
static int loadBIOS(void *dest) {

	int i;
	for (i=0; i<3; i++) {
		const RomHeader *rh = findBios(i);
		if (rh != NULL && (rh->filesize == 0x10000)) {
			memcpy(dest, (u8 *)rh + sizeof(RomHeader), 0x10000);
			return 1;
		}
	}
//	memcpy(dest, (u8 *)rawBios, 0x10000);
	return 0;
}

int loadColorBIOS(void) {
/*	if (loadBIOS(biosSpace)) {
		g_BIOSBASE_COLOR = biosSpace;
		return 1;
	}
	g_BIOSBASE_COLOR = NULL;
	return 0;*/
}

int loadBWBIOS(void) {
/*	if (loadBIOS(biosSpace)) {
		g_BIOSBASE_BNW = biosSpace;
		return 1;
	}
	g_BIOSBASE_BNW = NULL;
	return 0;*/
}

//---------------------------------------------------------------------------------
void checkMachine() {
/*	u8 newMachine = gMachineSet;
	if (newMachine == HW_AUTO) {
		if (ngpHeader->mode != 0) {
			newMachine = HW_NGPCOLOR;
		}
		else {
			newMachine = HW_NGPMONO;
		}
	}
	if (gMachine != newMachine) {
		gMachine = newMachine;
		if (gMachine == HW_NGPMONO) {
			gSOC = SOC_K1GE;
		}
		else {
			gSOC = SOC_K2GE;
		}
		machineInit();
	}*/
}
