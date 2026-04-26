# S8GBA V1.1.8

This is a SEGA 8Bit emulator for the Nintendo GBA, it supports the following systems:

	SEGA SG-1000 / SG-1000 II
	SEGA SC-3000
	SEGA Mark III
	SEGA Master System J, 1 & 2
	SEGA Game Gear

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
On other platforms you can use the [HTML Builder](https://flubbaofward.github.io/S8GBA/Builder.html).

The header is defined in Emubase.h, it's 64 bytes long, the size field is in
little endian, the 32bit id is 0x1A534D53 (LE).
The name field can be 31 bytes plus a terminating zero.
There is an example header file included, "sms.header".

When the emulator starts, you press L+R to open up the menu.
Now you can use the cross to navigate the menus, A to select an option, B to
 go back a step.

## Menu

### File

* Load Game: Select a game to load.
* Load NVRAM: Load non volatile ram (EEPROM/SRAM) for the currently running game.
* Save NVRAM: Save non volatile ram (EEPROM/SRAM) for the currently running game.
* Save Settings: Save the current settings.
* Reset Game: Reset the currently running game.

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
* Perfect Sprites: Uses a bit more cpu but is worth it.
* 3D Display: Terminator vs Robocop needs this off.

### Machine

* Region: Change the region of the SMS and video standard.
* Machine: Here you can select the hardware, Auto should work for most games.
* Bios Settings:
  * Use Bios: Here you can select if you want to use the selected BIOSes.
  * Select Export Bios: Browse for export bios.
  * Select Japanese Bios: Browse for japanese bios.
  * Select GameGear Bios: Browse for GameGear bios.

### Settings

* Speed: Switch between speed modes, can also be toggled with L+START.
  * Normal: Game runs at its normal speed.
  * 200%: Game can run up to double speed.
  * Max: Games can run up to 4 times normal speed.
  * 50%: Game runs at half speed.
* Autoload State: Toggle Savestate autoloading. Automagicaly load the
 savestate associated with the selected game.
* Autosave Settings: This will save settings when leaving menu if any
 changes are made.
* Autopause Game: Toggle if the game should pause when opening the menu.
* Powersave 2nd Screen: If graphics/light should be turned off for the GUI
 screen when menu is not active.
* Emulator on Bottom: Select if top or bottom screen should be used for
 emulator, when menu is active emulator screen is allways on top.
* Autosleep: Change the autosleep time, also see Sleep. !!!DoesntWork!!!

### Debug

* Debug Output: Toggle fps meter & more.
* Disable Background: Turn on/off background rendering.
* Disable Sprites: Turn on/off sprite rendering.
* Step Frame: Emulate one frame.

### About

Some dumb info...

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
