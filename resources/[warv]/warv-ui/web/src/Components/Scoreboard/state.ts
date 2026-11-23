import { createStateObject } from "../../Utils";
import { ScoreboardData } from "../../types";

export const scoreboard = createStateObject<ScoreboardData>("SET_SCOREBOARD", {
  visible: false,
  mode: "teams",
  myTeam: 0,
  gamemode: "",
  map: "",
  team1Score: 0,
  team2Score: 0,
  team1: [],
  team2: [],
});
