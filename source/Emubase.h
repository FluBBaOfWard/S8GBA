#include "Shared/SRAMHandler.h"

#ifndef EMUBASE
#define EMUBASE

#define SMSID 0x1A534D53		// "SMS",0x1A

typedef struct {
	const u32 identifier;
	const u32 filesize;
	const u32 flags;			// See Equates.h emuflags.
	const u32 spritefollow;
	const u8 bios;				// Bit 0 = Bios.
	const u8 reserved[15];
	const char name[32];
	const u8 romData[];
} RomHeader;

typedef struct {				// (config struct)
	ConfigHeader ch;			// From SRAMHandler.
	int emuSettings;			// Misc standard settings
	int sleepTime;				// autoSleepTime
	u8 scaling;					// from gfx.s
	u8 flicker;					// from gfx.s
	u8 gammaValue;				// from gfx.s
	u8 sprites;					// from gfx.s
	u8 glasses;					// from gfx.s
	u8 config;					// from cart.s
	u8 controller;				// from io.s
	u8 dipSwitch0;				// from io.s
} ConfigData;

#endif // EMUBASE
