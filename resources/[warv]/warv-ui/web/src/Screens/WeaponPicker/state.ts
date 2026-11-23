import { createStateObject } from "../../Utils";
import { WeaponPickerData } from "../../types";

export const weaponPicker = createStateObject<WeaponPickerData>("SET_WEAPON_PICKER", {
  slot: "primary",
  playerLevel: 1,
  maxWeaponLevel: 30,
  categories: [],
});
