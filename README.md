# S8GBA V1.1.9

<img align="right" width="220" src="./logo.png" />

This is a SEGA 8Bit emulator for the Nintendo GBA, it supports the following systems:

	SEGA SG-1000 / SG-1000 II
	SEGA SC-3000
	SEGA Mark III
	SEGA Master System J, 1 & 2
	SEGA Game Gear
	Othello Multivision
	Coleco

Some systems require you to add their Bios'es to function correctly.

Features:

	Most things you'd expect from an SMS emulator.
	Except these...

Missing:

	Correct sprite collision.
	Speech samples.
	EEPROM save for the few GG games that use it.

Check your roms!
<https://www.smspower.org/maxim/Software/SMSChecker>

## How to use

On Windows run S8GBA.exe to add roms to the emulator, you can also add a real bios.
Do no overwrite the original .gba file!
On other platforms you can use the [HTML Builder](https://flubbaofward.github.io/S8GBA/Builder.html),
always add the bios files before any normal roms.

The header is defined in Emubase.h, it's 64 bytes long, the size field is in
little endian, the 32bit id is 0x1A534D53 (LE).
The name field can be 31 bytes plus a terminating zero.
There is an example header file included, "sms.header".

When the emulator starts, you press L+R to open up the menu.
Now you can use the cross to navigate the menus, A to select an option, B to
go back a step.

When playing SMS 3D games you might want to turn down the color a bit for
better 3D effect, I have only tested with red/cyan glasses.

## Menu

### File

* Load Game: Select a game to load.
* Load State: Load state for the currently running game.
* Save State: Save state for the currently running game.
* Save NVRAM: Save non volatile ram (EEPROM/SRAM) for the currently running game.
* Manage NVRAM: Delete unwanted NVRAM files.
* Manage States: Delete unwanted state files.
* Save Settings: Save the current settings.
* Eject Game: Eject the currently running game, can be used to play BIOS games.

### Controller

* Autofire: Select if you want autofire.
* Controller: 2P control player 2.
* Swap A-B: Swap which GBA button is mapped to which SMS/GG button.
* Joypad Type: You can select 3 button Megadrive/Genesis pad.
* Use Select as Reset: Map the GBA SELECT button to the SMS Reset button.
* Use R as FastForward: Select turbo speed as long as R button is held.

### Display

* Display: Here you can select if you want scaled or unscaled screenmode.
* Scaling: Here you can select if you want flicker or barebones lineskip.
* Gamma: Lets you change the gamma ("brightness").
* Color: Lets you change the color.
* GG Border: Lets you change between black, bordercolor and none.
* Perfect Sprites: Uses more cpu.
* 3D Display: Terminator vs Robocop needs this off.
* Lock Top Rows: This keeps the 2 top rows at the top in unscaled mode.

### Machine

* Region: Change the region of the SMS and video standard.
* Machine: Here you can select the hardware, Auto should work for most games.
* Cpu Speed Hacks: Allow speed hacks.
* Sound: Not emulating sound can give a speed boost.

### Settings

* Speed: Switch between speed modes, can also be toggled with L+START.
  * Normal: Game runs at its normal speed.
  * 200%: Game can run up to double speed.
  * Max: Games can run up to 4 times normal speed.
  * 50%: Game runs at half speed.
* Autoload State: Toggle Savestate autoloading. Automatically load the
 savestate associated with the selected game.
* Autoload NVRAM: Toggle NVRAM autoloading. Automatically load the
 NVRAM associated with the selected game.
* Autosave NVRAM: Toggle NVRAM autosaving. Automatically save the
 NVRAM when entering the menu.
* Autosave Settings: This will save settings when leaving menu if any
 changes are made.
* Autopause Game: Toggle if the game should pause when opening the menu.
* EWRAM Overclock: Changes the waitstates on EWRAM between 2 and 1, uses more
 power, around 10% speedgain. Doesn't work on Gameboy Micro, might damage your
 GBA. Use at your own risk!
* Autosleep: Change the autosleep time, also see Sleep.

### Debug

* Debug Output: Toggle fps meter & more.
* Disable Background: Turn on/off background rendering.
* Disable Sprites: Turn on/off sprite rendering.
* Step Frame: Emulate one frame.

### About

Some dumb info...

### Sleep

Put the GBA into sleepmode. START+SELECT wakes up from sleep mode (activated
 from this menu or from 5/10/30 minutes of inactivity).

### Power On/Off

Turn the power on or off on the console.

### Reset Console

Reset the console.

### Quit Emulator

Tries to reset the Flashcart and reboots the GBA.

## Controls

### Master System

```text
Dpad is mapped to up, down, left & right.
B is mapped to Button 1.
A is mapped to Button 2.
Start is mapped to Pause on console.
Select can be mapped to Reset on console.
```

### Game Gear

```text
Start is mapped to Start on console.
```

## Credits

```text
Thanks to:
Reesy for help with the Z80 emu core.
Some MAME people + Maxim for the SN76496 info.
Charles MacDonald (http://cgfm2.emuviews.com/) for VDP info.
Omar Cornut (http://www.smspower.org/) for help with various SMS stuff.
The crew at PocketHeaven for their support.
```

Fredrik Ahlström

<https://bsky.app/profile/therealflubba.bsky.social>

<https://www.github.com/FluBBaOfWard>

X/Twitter @TheRealFluBBa
