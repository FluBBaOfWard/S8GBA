#ifndef CART_HEADER
#define CART_HEADER

#ifdef __cplusplus
extern "C" {
#endif

extern u32 gRomSize;
extern u32 gEmuFlags;
extern u8 gCartFlags;
extern u8 gConfigSet;
extern u8 gScalingSet;
extern u8 gMachineSet;
extern u8 gMachine;
extern u8 gRegion;
extern u8 gArcadeGameSet;

extern u8 *romSpacePtr;
extern u8 EMU_SRAM[0x8000];
extern void *g_BIOSBASE_US;
extern void *g_BIOSBASE_JP;
extern void *g_BIOSBASE_GG;
extern void *g_BIOSBASE_COLECO;
extern void *g_BIOSBASE_MSX;
extern void *g_BIOSBASE_SORDM5;

void machineInit(void);
void loadCart(int);
void ejectCart(void);

/**
* Saves the state of cart to the destination.
* @param  *destination: Where to save the state.
* @return The size of the state.
*/
int cartSaveState(void *destination);

/**
* Loads the state of cart from the source.
* @param  *source: Where to load the state from.
* @return The size of the state.
*/
int cartLoadState(const void *source);

/**
 * Gets the state size of cart state.
 * @return The size of the state.
 */
int cartGetStateSize(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // CART_HEADER
