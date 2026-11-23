# WarV

Call of Duty style multiplayer for FiveM.

## Install

txAdmin → **Remote URL Template**:

```
https://raw.githubusercontent.com/Rubylium/WarV-Recipe/main/recipe.yaml
```

FXServer 25770+, OneSync, MySQL/MariaDB. Game build 3788.

## Modes

- Team Deathmatch
- Free for All
- Gun Game

## Features

- Lobbies, matchmaking, squads, friends, server browser
- Custom classes and gunsmith
- Weapon levels and mastery
- 10 killstreaks, from UAV to Nuke
- Ranks, prestige, medals, challenges, leaderboards
- Calling cards and emblems
- Bots
- Spectating and end of match podium
- Team voice chat

## Permissions

From the server console:

```
setpermission <uid> <level>
```

| Level | Rank | Access |
| --- | --- | --- |
| 1 | Moderator | `/ban` `/kick` `/search` |
| 2 | Admin | Clothing creator |
| 3 | Owner | Map, prop and attachment editors, `/setwinstreak` |

## Commands

| Command | |
| --- | --- |
| `/ban <uid> <30m\|12h\|7d\|2w\|perm> <reason>` | Ban |
| `/kick <uid> <reason>` | Kick |
| `/search <name>` | Find a UID |
| `/setwinstreak <value> [uid]` | Set win streak |
| `/mapeditor [map]` | Map editor |
| `/propeditor [map]` | Prop and lobby editor |
| `off` | Console only, kicks everyone before a restart |

## Maps

A map needs spawns, both team starts, an end screen spot, a map center and bounds. Modes are enabled per map in the editor, and a mode is playable once 3 maps support it.

Editor data is saved in `warv/data/`.

## Discord

Optional logs and status message, convars listed in `server.cfg`.

## Credits

- [oxmysql](https://github.com/overextended/oxmysql) by overextended
- [PolyZone](https://github.com/mkafrin/PolyZone) by mkafrin
- `warv-ipls` based on [bob74_ipl](https://github.com/Bob74/bob74_ipl) by Bob74
- `object_gizmo` based on [object_gizmo](https://github.com/DemiAutomatic/object_gizmo) by DemiAutomatic, GPL-3.0
