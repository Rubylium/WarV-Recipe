import { createStateObject } from "../../Utils";
import { MatchIntroData } from "../../types";

export const matchIntro = createStateObject<MatchIntroData>("SET_MATCH_INTRO", {
  visible: false,
  map: "",
  gamemode: "",
  team: "",
  teamColor: "blue",
  name: "",
  nameKey: 0,
});
