import { createStateObject } from "../../Utils";
import { SelectData } from "../../types";

export const cardSelect = createStateObject<SelectData>("SET_CARD_SELECT", {
  items: [],
  selected: 0,
});
