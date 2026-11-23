import { createStateObject } from "../../Utils";
import { DeathData } from "../../types";

export const death = createStateObject<DeathData>("SET_DEATH", {
  killer: "",
  respawnMs: 3000,
  canChangeClass: true,
  weaponImage: "",
  weaponName: "",
  distance: 0,
  headshot: false,
  rankIcon: "",
  level: 0,
  prestige: 0,
  spectating: "",
  specSeq: 0,
  damage: [],
});
