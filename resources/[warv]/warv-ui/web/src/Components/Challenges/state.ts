import { createStateObject } from "../../Utils";
import { ChallengesData } from "../../types";

export const challenges = createStateObject<ChallengesData>("SET_CHALLENGES", {
  items: [],
  resetsIn: 0,
});
