#ifndef EMUBASE
#define EMUBASE

#ifdef __cplusplus
extern "C" {
#endif

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
	int emuSettings;			// Misc standard settings
	int unused;					// unused
	u8 display;					// from gfx.s
	u8 flicker;					// from gfx.s
	u8 gammaValue;				// from gfx.s
	u8 sprites;					// from gfx.s
	u8 machine;					// from gfx.s
	u8 config;					// from cart.s
	u8 controller;				// from io.s
	u8 dipSwitch0;				// from io.s
} ConfigData;

#ifdef __cplusplus
} // extern "C"
#endif

#endif // EMUBASE
