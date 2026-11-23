import { createStateObject } from "../../Utils";
import { SelectData } from "../../types";

export const emblemSelect = createStateObject<SelectData>("SET_EMBLEM_SELECT", {
  items: [],
  selected: 0,
});
