import { createStateObject } from "../../Utils";
import { IntroTagData } from "../../types";

export const introTag = createStateObject<IntroTagData>("SET_INTRO_TAG", {
  visible: false,
  name: "",
  key: 0,
  x: 0.5,
  y: 0.5,
  teamColor: "blue",
});
