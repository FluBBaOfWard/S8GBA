#include <gba.h>
#include <string.h>

#include "FileHandling.h"
#include "Equates.h"
#include "Main.h"
#include "Shared/EmuMenu.h"
#include "Shared/EmuSettings.h"
#include "Shared/FileHelper.h"
#include "Shared/SRAMHandler.h"
#include "Shared/AsmExtra.h"
#include "Gui.h"
#include "MasterSystem.h"
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
	gScalingSet  = cfg.display & 3;
	g3DEnable    = (cfg.display>>4) & 1;
	gFlicker     = cfg.flicker & 1;
	gGammaValue  = cfg.gammaValue & 0x7;
	gColorValue  = (cfg.gammaValue >> 4) & 0x7;
	SPRS         = cfg.sprites;
	gMachineSet  = cfg.machine & 0x1F;
	gRegion      = (cfg.machine >> 5) & 3;
	gConfigSet   = cfg.config;
	joyCfg       = (joyCfg & ~0x400) | ((cfg.controller & 1) << 10);
	VDP0SetSprScan(SPRS);
	setSleepValue(emuSettings & AUTOSLEEP_MASK);
}

void updateConfigData(void) {
	cfg.emuSettings = emuSettings & ~EMUSPEED_MASK; // Clear speed setting.
	cfg.display     = (gScalingSet & 3) | ((g3DEnable & 1)<<4);
	cfg.flicker     = gFlicker & 1;
	cfg.gammaValue  = (gGammaValue & 0x7) | ((gColorValue & 0x7) << 4);
	cfg.sprites     = SPRS;
	cfg.machine     = (gMachineSet & 0x1F) | ((gRegion & 3)<<5);
	cfg.config      = gConfigSet;
	cfg.controller  = (joyCfg>>10) & 1;
}

void initSettings(void) {
	memset(&cfg, 0, sizeof(cfg));
	cfg.emuSettings = AUTOPAUSE_EMULATION | AUTOLOAD_NVRAM | AUTOSLEEP_OFF;
	cfg.display     = SCALED_FIT | 0x10; // Scaling + 3DGlasses
	cfg.flicker     = 1;
	cfg.gammaValue  = 0x40;		// ColorValue = 4
	cfg.config      = 0x80;		// config, bit 7=BIOS on/off, bit 6=X as GG Start, bit 5=Select as Reset, bit 4=R as FastForward

	applyConfigData();
}

int loadSettings() {
	if (readFile((u8 *)&cfg, sizeof(cfg), SMSID)) {
		applyConfigData();
		infoOutput("Settings loaded.");
		return 0;
	}
	else {
		updateConfigData();
		infoOutput("No settings file found.");
	}
	return 1;
}
void saveSettings() {
	updateConfigData();

	if (writeFile((u8 *)&cfg, sizeof(cfg), SMSID, "Config")) {
		infoOutput("Settings saved.");
	}
	else {
		infoOutput("Could not save settings file.");
	}
}

int loadNVRAM() {
	if (loadEmuSram(EMU_SRAM, 0x8000)) {
		infoOutput("Loaded NVRAM.");
		return 1;
	}
	return 0;
}
void saveNVRAM() {
	if (gCartFlags & SRAMFLAG) {
		forceSaveNVRAM();
	}
}
int forceSaveNVRAMChk() {
	if (saveEmuSram(EMU_SRAM, 0x8000)) {
		infoOutput("Saved NVRAM.");
		return 1;
	}
	return 0;
}
void forceSaveNVRAM() {
	forceSaveNVRAMChk();
}
int loadStateChk() {
	if (getStateSize() < 0x10000
		&& quickLoad()) {
		infoOutput("Loaded State.");
		return loadNVRAM();
	}
	return 0;
}
int saveStateChk() {
	if (getStateSize() < 0x10000
		&& quickSave()) {
		infoOutput("Saved State.");
		return forceSaveNVRAMChk();
	}
	return 0;
}

void loadState() {
	loadStateChk();
}
void saveState() {
	saveStateChk();
}
int packState(void *statePtr) {
	return smsPackState(statePtr);
}
void unpackState(const void *statePtr) {
	smsUnpackState(statePtr);
}
int getStateSize() {
	return smsGetStateSize();
}

//---------------------------------------------------------------------------------
bool loadGame(const RomHeader *rh) {
	if (rh) {
		return loadROM(rh->romData, rh->filesize, rh->flags);
	}
	return true;
}

//---------------------------------------------------------------------------------
bool loadROM(const u8 *rom, int size, int emuFlags) {
	selectedGame = selected;
	cls(0);
	gRomSize = size;
	romSpacePtr = rom;
	checkMachine();
	setEmuSpeed(0);
	cartInitSRAM();
	loadCart(emuFlags);
	int loadedSRAM = 0;
	if (emuSettings & AUTOLOAD_STATE) {
		loadedSRAM = loadStateChk();
	}
	if ((emuSettings & AUTOLOAD_NVRAM)
		&& loadedSRAM == 0) {
		loadNVRAM();
	}
	gameInserted = true;
	powerIsOn = true;
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

void viewNVRAM() {
	pauseEmulation = true;
	ui12();
	skipScroll();
	manageNVRAM();
	backOutOfMenu();
}

void viewSStates() {
	pauseEmulation = true;
	ui13();
	skipScroll();
	loadStateMenu();
	backOutOfMenu();
}

//---------------------------------------------------------------------------------
void loadBIOSes(void) {
	const RomHeader *bh;
	int n = 0;
	g_BIOSBASE_US = NULL;
	g_BIOSBASE_JP = NULL;
	g_BIOSBASE_GG = NULL;
	g_BIOSBASE_COLECO = NULL;
	g_BIOSBASE_MSX = NULL;
	while ((bh = findBios(n++))) {
		const u8 *dest = (const u8 *)bh + sizeof(RomHeader);
		if (bh->flags & GG_MODE) {
			g_BIOSBASE_GG = dest;
		}
		else if (bh->flags & COL_MODE) {
			g_BIOSBASE_COLECO = dest;
		}
		else if (bh->flags & MSX_MODE) {
			g_BIOSBASE_MSX = dest;
		}
		else if (bh->flags & COUNTRY) {
			g_BIOSBASE_JP = dest;
		}
		else {
			g_BIOSBASE_US = dest;
		}
	}
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
