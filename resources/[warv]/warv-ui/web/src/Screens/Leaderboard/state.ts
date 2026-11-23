import { createStateObject } from "../../Utils";
import { LeaderboardData } from "../../types";

export const leaderboard = createStateObject<LeaderboardData>("SET_LEADERBOARD", {
  category: "kills",
  categories: [],
  items: [],
});
