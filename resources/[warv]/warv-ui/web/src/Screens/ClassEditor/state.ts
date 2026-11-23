import { createStateObject } from "../../Utils";
import { ClassSelectData } from "../../types";

export const classSelect = createStateObject<ClassSelectData>("SET_CLASS_SELECT", {
  classes: [],
  lockedSlots: 5,
  warvPlus: false,
  selected: 1,
  scorestreaks: [],
});
