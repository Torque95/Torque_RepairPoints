# Torque Repair Points

A QBCore vehicle repair script with NUI overlay, xSound audio, and server-side payment validation.

## Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)

## Installation

1. Drop the `Torque_repairpoints` folder into your server's `resources` directory
2. Add `ensure Torque_repairpoints` to your `server.cfg` — make sure it starts **after** `qb-core`, and `ox_lib`
4. Restart your server

## Configuration

All tunable values are at the top of `client.lua`:

| Variable | Default | Description |
|---|---|---|
| `REPAIR_COST` | `1000` | Cost in dollars — also update the display string in `ui.html` |
| `REPAIR_DURATION` | `8000` | Repair time in milliseconds |
| `DRAW_DISTANCE` | `30.0` | Distance at which the marker becomes visible |
| `INTERACT_RANGE` | `9.0` | Distance at which the text UI and E prompt appear |

The repair cost on the server side is set at the top of `server.lua` and must match `client.lua`:

```lua
local REPAIR_COST = 1000
```

## Adding or Removing Repair Locations

Edit the `repairPoints` table in `client.lua`:

```lua
local repairPoints = {
    { coords = vector3(345.61, -1109.11, 29.41), label = "Mission Row" },
    -- add or remove entries here
}
```

Each entry needs a `coords` vector3 and a `label` string. The label appears on the map blip.

## Features

- Server-side payment validation — cost is never sent from the client
- Pays from cash first, falls back to bank automatically
- Repair dialog shows current cash and bank balance before charging
- Skips the dialog entirely if the vehicle doesn't need repairs
- Hood opens during repair and closes on completion
- NUI overlay shows live progress percentage and which account was charged
- Controls are locked during repair — cannot exit vehicle, shoot, accelerate, or brake
- Per-player cooldown prevents event spam
- Map blips for every repair location
- UI safety watcher clears the text prompt if the player dies or exits the vehicle

## File Structure

```
Torque_repairpoints/
├── client.lua          -- Proximity loop, UI, repair handler
├── server.lua          -- Payment validation, balance callback
├── fxmanifest.lua      -- Resource manifest
└── html/
    └── ui.html         -- NUI overlay (progress bar card)
```

## Notes

- The `REPAIR_COST` variable in `ui.html` is a display-only hardcoded string — if you change the cost, update the dollar amount in `ui.html` to match
- Repair locations commented out in the original script (Bennys, WCG) can be re-added by uncommenting them in the `repairPoints` table

