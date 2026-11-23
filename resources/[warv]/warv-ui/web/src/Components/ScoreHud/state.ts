import { createStateObject } from "../../Utils";
import { ScoreHudData } from "../../types";

export const scoreHud = createStateObject<ScoreHudData>("SET_SCORE_HUD", {
  visible: false,
  teamMode: true,
  gamemode: "",
  gmIcon: "",
  timer: 0,
  maxScore: 0,
  left: { score: 0, label: "", logo: "", color: "blue" },
  right: { score: 0, label: "", logo: "", color: "red" },
});
