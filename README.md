# re7-mac-controller-fix

Fixes wired controller detection for the Wine-wrapped macOS build of Resident Evil 7 by adding the correct SDL controller mapping and launch-time SDL environment setup.

## What this repo does

Some Wine-wrapped macOS builds of RE7 can see a controller as a raw joystick but fail to promote it to an SDL game controller. When that happens, Wine never exposes the pad as a proper XInput device, so the game ignores it.

This repo gives you:

- a probe script to print your controller GUID using the app bundle's own `x86_64` SDL runtime
- a patch script that injects:
  - an `x86_64` SDL warm-up helper
  - a custom launcher that exports SDL environment variables
  - an `SDL_GAMECONTROLLERCONFIG` mapping for your controller
- a revert script to restore the original launcher state

## Tested target

This was built around the Wine/Sikarugir-wrapped `Resident Evil 7.app` layout:

- `Contents/MacOS/Sikarugir`
- `Contents/Frameworks/libSDL2-2.0.0.dylib`
- `Contents/SharedSupport/wine/bin/wine`

## Quick start

Install SDL2 headers first if you do not already have them:

```bash
brew install sdl2 pkg-config
```

Probe your controller first:

```bash
./scripts/probe-controller.sh "/Applications/Resident Evil 7.app"
```

If the output shows `isGameController=0`, patch the app with a controller mapping:

```bash
./scripts/patch-re7.sh "/Applications/Resident Evil 7.app"
```

By default, `patch-re7.sh` uses the known-good mapping for this GUID:

```text
050000695e040000e002000000696d00
```

Then fully quit RE7, unplug/replug the controller, and launch the app normally from `Applications`.

## Custom mapping

If your controller has a different GUID, pass a full SDL mapping as the second argument:

```bash
./scripts/patch-re7.sh "/Applications/Resident Evil 7.app" 'GUID,name,a:b0,b:b1,...'
```

You can test a mapping before patching:

```bash
./scripts/probe-controller.sh "/Applications/Resident Evil 7.app" 'GUID,name,a:b0,b:b1,...'
```

## Revert

To restore the original launcher state:

```bash
./scripts/revert-re7.sh "/Applications/Resident Evil 7.app"
```

## Notes

- This modifies the app bundle directly.
- The patch script stores backups under:
  - `Contents/Resources/re7-mac-controller-fix/`
- The fix is aimed at controller detection only. It does not remap buttons inside the game.
- The helper binaries are compiled as `x86_64` to match the wrapper's Wine/SDL runtime.
