import { createStateObject } from "../../Utils";
import { CountdownData } from "../../types";

export const countdown = createStateObject<CountdownData>("SET_COUNTDOWN", {
  visible: false,
  seconds: 0,
  label: "",
});
