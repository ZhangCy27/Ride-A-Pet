# Ride A Pet Hub

A Roblox script hub for the *Ride A Pet* simulator, built to run through a script executor. The UI is a separate module (`GUI/RideAPetGUI.lua`) loaded at runtime, so the logic script and the interface can be updated independently.

## Features

- **Select Egg Luck** — quick preset buttons (`All` / `High`) plus a logarithmic-scale slider (5 → 50T) to set the minimum egg luck the script will collect.
- **Auto Egg** — walks to a matching egg on the map, picks it up, and returns to your plot.
- **Auto Place Egg** — automatically equips and places newly obtained eggs. Eggs already sitting in your backpack when the toggle is turned on are left alone.
- **Auto Rebirth** — fires the rebirth remote on a 5-second cooldown.
- **Tween Speed** — adjusts how fast your character moves during Auto Egg (50–750 studs/s).

All toggles stop immediately when turned off — in-progress movement is cancelled rather than finishing its current step.

## Usage

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZhangCy27/Ride-A-Pet/refs/heads/main/Main.lua"))()
```

Run this from your executor while inside the game. `Main.lua` will automatically fetch `GUI/RideAPetGUI.lua` from this repo to build the interface — you don't need to load the GUI file separately.

## File structure

```
Ride-A-Pet-main/
├── Main.lua              -- all gameplay logic (state, remotes, loops, menu wiring)
├── GUI/
│   └── RideAPetGUI.lua   -- UI module (window, toggle/dropdown/slider components)
├── LICENSE
└── README.md
```

`RideAPetGUI.lua` exposes a small API so it can be reused by other scripts:

```lua
local UIModule = loadstring(game:HttpGet(GUI_URL))()
local Hub = UIModule.CreateWindow("Title", "Subtitle")

Hub:CreateToggle("LABEL", "description", function(value) ... end)
Hub:CreateDropdown("LABEL", { "A", "B" }, "A", function(option) ... end)
Hub:CreateSlider("LABEL", min, max, default, function(value) ... end, formatter)
Hub:CreateLuckPicker("LABEL", presets, min, max, default, function(value) ... end, formatter)
```

## Configuration

A few names are guessed and may need adjusting if the game updates or if something stops firing correctly, all near the top of `Main.lua`:

- `GameRemotes` / `EggPlacedRemote` / `RebirthRemote` / `RequestPlotEggsRemote` — looked up by name under `ReplicatedStorage.Remotes.Game`.
- Egg models are read from `workspace.RenderedEggs`, and luck text from a `TextLabel` named `Luck` (or under an `EggLuck` container).
- Your own plot is found via `workspace.Plots`, matching a `Data/Owner` value against your username.

If a feature silently does nothing, it's usually because one of these names doesn't match what the game currently uses — check the console for `warn(...)` output, which points at what wasn't found.

## Disclaimer

This project automates gameplay via a third-party script executor. Using it can violate Roblox's Terms of Service and the target game's rules, and may result in your account being moderated or banned. Use at your own risk. This project is not affiliated with Roblox Corporation or the developers of *Ride A Pet*.

## License

MIT — see [LICENSE](LICENSE).
