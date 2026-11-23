import { createStateObject } from "../../Utils";
import { PlayerMarker } from "../../types";

export const playerMarkers = createStateObject<PlayerMarker[]>("SET_PLAYER_MARKERS", []);
