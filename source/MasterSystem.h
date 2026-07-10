#ifndef MASTERSYSTEM_HEADER
#define MASTERSYSTEM_HEADER

#ifdef __cplusplus
extern "C" {
#endif

/// This runs all save state functions for each chip.
int smsPackState(void *statePtr);

/// This runs all load state functions for each chip.
void smsUnpackState(const void *statePtr);

/// Gets the total state size in bytes.
int smsGetStateSize(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // MASTERSYSTEM_HEADER
