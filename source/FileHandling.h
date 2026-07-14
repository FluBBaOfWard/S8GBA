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
void loadState(void);
void saveState(void);
int packState(void *statePtr);
void unpackState(const void *statePtr);
int getStateSize(void);
void checkMachine(void);
int loadNVRAM(void);
void saveNVRAM(void);
void forceSaveNVRAM(void);
//void ejectCart(void);
void selectGame(void);
void loadBIOSes(void);
void viewNVRAM(void);
void viewSStates(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // FILEHANDLING_HEADER
