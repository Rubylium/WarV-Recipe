import { createStateObject } from "../../Utils";
import { MapEditorData } from "../../types";

export const mapEditor = createStateObject<MapEditorData>("SET_MAP_EDITOR", {
  mode: "pick",
  mapName: "",
  cards: [],
  layers: [],
  points: [],
  activeLabel: "",
  hidden: false,
  env: { hour: 12, minute: 0, weather: "EXTRASUNNY", set: false },
  weathers: [],
  boundsMaxZ: "",
  boundsMinZ: "",
  gamemodes: [],
  selection: null,
  dirty: false,
  missing: [],
  height: 120,
});
