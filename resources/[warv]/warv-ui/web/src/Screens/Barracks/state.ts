import { createStateObject } from "../../Utils";
import { defaultPlayer } from "../../defaults";
import { BarracksData } from "../../types";

export const barracks = createStateObject<BarracksData>("SET_BARRACKS", {
  player: defaultPlayer,
  stats: {
    kills: 0,
    deaths: 0,
    assists: 0,
    kda: "0.00",
    wins: 0,
    draws: 0,
    losses: 0,
    wlr: "0.00",
    score: 0,
    winStreak: 0,
    bestWinStreak: 0,
    headshots: 0,
    headshotRatio: "0.0%",
    playtimeText: "0h",
    canPrestige: false,
  },
});
