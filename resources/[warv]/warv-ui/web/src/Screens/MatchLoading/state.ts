import { createStateObject } from "../../Utils";
import { MatchLoadingData } from "../../types";

export const matchLoading = createStateObject<MatchLoadingData>(
  "SET_MATCH_LOADING",
  {
    map: { name: "", image: "" },
    gamemode: "",
    ranked: false,
    teamMode: true,
    phase: "loading",
    progress: 0,
    waitingText: "",
    tip: "",
  }
);
