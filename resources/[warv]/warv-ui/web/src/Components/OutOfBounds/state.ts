import { createStateObject } from "../../Utils";
import { OobData } from "../../types";

export const oob = createStateObject<OobData>("SET_OOB", {
  visible: false,
  seconds: 0,
  total: 0,
});
