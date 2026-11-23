import { createStateObject } from "../../Utils";
import { WeaponHudData } from "../../types";

export const weaponHud = createStateObject<WeaponHudData>("SET_WEAPON_HUD", {
  visible: false,
  name: "",
  image: "",
  clip: 0,
  clipMax: 0,
  reserve: 0,
  grenade: -1,
});
