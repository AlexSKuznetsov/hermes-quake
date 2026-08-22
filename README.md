# hermes-quake

A Quake-style drop-down console for Windows that runs [Hermes Agent](https://github.com/NousResearch/hermes-agent).

Press **Alt + \`** anywhere: a translucent terminal slides down from the top of
your screen with a live Hermes session. Press it again and it disappears,
keeping its state. Your agent stays warm between drops.

> Built and tested against Windows Terminal 1.24 on Windows 11. Uses only
> native Windows Terminal features - no AutoHotkey, no extra processes.

## What you get

| Piece | What it does |
|---|---|
| `Hermes Console` profile | Runs `hermes.exe` directly in Windows Terminal: dark navy background at 85% opacity, hidden scrollbar, starts in `%USERPROFILE%` |
| `globalSummon` action | The Quake behavior: slide-down window named `_quake`, 200 ms animation, follows your mouse across monitors, stays on your current virtual desktop |
| Logon seeder | At every sign-in, pre-creates the drop-down with the Hermes profile (bypassing Terminal's "new windows use the default profile" behavior) and minimizes it |

The installer merges these into your existing `settings.json`. It backs up
your settings first, skips anything already present, and never touches your
default profile.

## Requirements

- Windows 10/11 with [Windows Terminal](https://aka.ms/terminal) (the Store app)
- [Hermes Agent](https://hermes-agent.nousresearch.com/docs/) installed at the
  standard location: `%LOCALAPPDATA%\hermes\hermes-agent\venv\Scripts\hermes.exe`

## Install

1. Close every Windows Terminal window first. A running instance can overwrite
   external edits to `settings.json`.
2. Then:

```powershell
git clone https://github.com/AlexSKuznetsov/hermes-quake.git
cd hermes-quake
powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 -AutoStart
```

Prefer not to clone? Download the zip from
[Releases](https://github.com/AlexSKuznetsov/hermes-quake/releases), extract,
and run the same `install.ps1` command.

3. Start Windows Terminal and press **Alt + \`**.

Without `-AutoStart`, the hotkey still works, but the first summon after a
fresh login creates the window with your default terminal profile instead of
Hermes. You can also seed manually any time:

```
wt -w _quake nt --profile "Hermes Console"
```

## Uninstall

1. Restore a `.bak-hermes-quake-*` backup of your settings, or remove the
   `Hermes Console` profile, the `User.HermesQuakeToggle` action, and its
   keybinding (Terminal settings -> Open JSON file).
2. Delete `%USERPROFILE%\bin\seed-hermes-quake.ps1` and the
   `Hermes Quake Seeder` shortcut in your Startup folder (`shell:startup`).

## Customizing

All knobs live in Windows Terminal settings (`Ctrl+,`, then Open JSON file):

- Different key: change `"keys": "alt+\`"` on the `User.HermesQuakeToggle`
  action (for example `"f12"`).
- No slide animation: remove `"dropdownDuration"`.
- Stay on one monitor: set `"monitor": "any"`.
- Virtual desktop behavior: `"desktop": "onCurrent"` or `"toCurrent"`.
- Console look and feel: edit the `Hermes Console` profile (`background`,
  `opacity`, `font`, `padding`).

## Known caveats

- If an elevated (Run as Administrator) app has focus, the hotkey cannot reach
  an unelevated Terminal. Run Terminal elevated too if you need it there.
- Alt+\` is registered system-wide while Terminal runs: other apps cannot
  claim it.
- The seeder waits about 4 seconds after login before minimizing the window;
  summoning faster than that may briefly show a default-profile tab.

## Files

- `install.ps1` - idempotent installer (merge profile + action + keybinding, optional logon seeder)
- `seed-hermes-quake.ps1` - logon seeder (create + minimize the quake window)
- `settings-snippet.json` - human-readable reference of everything that gets added

## License

[MIT](LICENSE)
