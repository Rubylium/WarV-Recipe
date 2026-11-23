import { createStateObject } from "../../Utils";
import { HitMarkerData } from "../../types";

export const hitMarker = createStateObject<HitMarkerData>("HIT_MARKER", { n: 0, kill: false });
