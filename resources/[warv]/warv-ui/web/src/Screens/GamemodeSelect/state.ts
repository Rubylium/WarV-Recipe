import { createStateObject } from "../../Utils";
import { GamemodeSelectData } from "../../types";

export const gamemodeSelect = createStateObject<GamemodeSelectData>("SET_GAMEMODE_DATA", {
  playlists: [],
});
