# re7-mac-controller-fix

![Resident Evil 7 logo](assets/re7-logo.png)

If `Resident Evil 7.app` opens on your Mac but your wired controller does nothing in-game, this toolkit may fix it.

It was made for unofficial Wine-wrapped macOS builds of RE7 that launch the Windows game inside a Mac app bundle. It is not meant for the official native Mac release.

## Disclaimer

This repo was tested against an unofficial third-party RE7 app bundle, not an official Mac release from Capcom. I do not provide, host, or link to game files here.

Use this only if you have the legal right to use the game software involved. Unofficial or modified app bundles can be unstable, tampered with, or unsafe, so use them at your own risk.

## What this fixes

Some wrapped RE7 builds can see a controller as a basic joystick, but not as a proper game controller. When that happens, the game starts, but controller input never reaches RE7 correctly.

This repo gives you:

- a quick test to see how the game bundle detects your controller
- a patch that adds the right SDL controller setup for the wrapper
- a revert script if you want to undo everything

## Before you start

Use this if all of these are true:

- the game already launches on your Mac
- macOS itself can see your controller
- the controller does not work properly inside RE7
- your `Resident Evil 7.app` is a wrapped Windows build, not a native Mac port

You will need:

- macOS
- Terminal
- Homebrew

Install the required tools once:

```bash
brew install sdl2 pkg-config
```

## Files in this repo

- `scripts/probe-controller.sh` checks how the game bundle currently sees your controller
- `scripts/patch-re7.sh` applies the controller fix
- `scripts/revert-re7.sh` restores the original launcher setup

## Step 1: Check your controller

Run:

```bash
./scripts/probe-controller.sh "/Applications/Resident Evil 7.app"
```

You are looking for this part of the output:

- `isGameController=0` means the wrapper sees your pad incorrectly, and this fix is likely relevant
- `isGameController=1` means the wrapper already sees it as a game controller

## Step 2: Apply the fix

Run:

```bash
./scripts/patch-re7.sh "/Applications/Resident Evil 7.app"
```

Then do this:

1. Fully quit the game.
2. Unplug the controller.
3. Plug it back in.
4. Launch `Resident Evil 7.app` normally.
5. Test the controller in-game.

## What the patch changes

The patch:

- adds a short SDL warm-up helper that runs before the wrapper starts Wine
- adds SDL environment settings to the app launcher
- adds a controller mapping so the wrapper treats the pad as a proper game controller
- keeps a backup so you can undo the change later

## If your controller has a different GUID

Most people can skip this section.

If your controller is different, you can pass your own SDL mapping as the second argument:

```bash
./scripts/patch-re7.sh "/Applications/Resident Evil 7.app" 'GUID,name,a:b0,b:b1,...'
```

You can also test a mapping first:

```bash
./scripts/probe-controller.sh "/Applications/Resident Evil 7.app" 'GUID,name,a:b0,b:b1,...'
```

## Undo the patch

If you want to restore the original app launcher:

```bash
./scripts/revert-re7.sh "/Applications/Resident Evil 7.app"
```

## Notes

- This modifies the app bundle directly.
- The backup is stored inside `Contents/Resources/re7-mac-controller-fix/`.
- The fix only helps the wrapper detect the controller correctly. It does not change your in-game button layout.
- The helper binaries are built as `x86_64` because that matches the wrapper runtime used by these builds.

## Tested wrapper layout

This repo was built around a wrapper with files like these inside `Resident Evil 7.app`:

- `Contents/MacOS/Sikarugir`
- `Contents/Frameworks/libSDL2-2.0.0.dylib`
- `Contents/SharedSupport/wine/bin/wine`

If your app bundle looks similar, this repo is likely aimed at the right target.

## Logo credit

README logo source: [Wikimedia Commons, "Logo Resident Evil VII.svg"](https://commons.wikimedia.org/wiki/File:Logo_Resident_Evil_VII.svg). Trademark belongs to Capcom.
