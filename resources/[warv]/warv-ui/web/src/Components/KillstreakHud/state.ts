import { createStateObject } from "../../Utils";
import { KillstreakHudData } from "../../types";

export const killstreaks = createStateObject<KillstreakHudData>("SET_KILLSTREAKS", {
  visible: false,
  streaks: [],
});
