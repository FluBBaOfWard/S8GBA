#ifndef FILEHANDLING_HEADER
#define FILEHANDLING_HEADER

#ifdef __cplusplus
extern "C" {
#endif

#include "Emubase.h"

#define FILEEXTENSIONS ".sms.gg.sg.sc"

extern ConfigData cfg;

void initSettings(void);
bool updateSettingsFromNGP(void);
int loadSettings(void);
void saveSettings(void);
bool loadROM(const u8 *rom, int size, int emuFlags);
bool loadGame(const RomHeader *rh);
void checkMachine(void);
int loadNVRAM(void);
void saveNVRAM(void);
void forceSaveNVRAM(void);
void loadState(void);
void saveState(void);
//void ejectCart(void);
void selectGame(void);
void loadBIOSes(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // FILEHANDLING_HEADER
