#include <gba.h>

#include "MasterSystem.h"
#include "Cart.h"
#include "Sound.h"
#include "Gfx.h"
#include "ARMZ80/ARMZ80.h"


int smsPackState(void *statePtr) {
	int size = 0;
	size += Z80SaveState(statePtr+size, &Z80OpTable);
	size += VDPSaveState(statePtr+size, &VDP0);
	size += sn76496SaveState(statePtr+size, &SN76496_0);
	size += cartSaveState(statePtr+size);
	return size;
}

void smsUnpackState(const void *statePtr) {
	int size = 0;
	size += Z80LoadState(&Z80OpTable, statePtr+size);
	size += VDPLoadState(&VDP0, statePtr+size);
	size += sn76496LoadState(&SN76496_0, statePtr+size);
	size += cartLoadState(statePtr+size);
}

int smsGetStateSize() {
	int size = 0;
	size += Z80GetStateSize();
	size += VDPGetStateSize();
	size += sn76496GetStateSize();
	size += cartGetStateSize();
	return size;
}
