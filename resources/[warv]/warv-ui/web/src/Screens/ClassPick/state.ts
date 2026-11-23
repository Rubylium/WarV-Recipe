import { createStateObject } from "../../Utils";
import { ClassPickData } from "../../types";

export const classPick = createStateObject<ClassPickData>("SET_CLASS_PICK", {
  classes: [],
  maxWeaponLevel: 30,
  selected: "",
});
