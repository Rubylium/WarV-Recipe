import { ScoreboardRow } from "../../types";

export const activeRows = (rows: ScoreboardRow[]) => rows.filter((row) => !row.empty);

export const teamTotals = (rows: ScoreboardRow[]) => {
  const totals = activeRows(rows).reduce((sum, row) => ({
    score: sum.score + row.score, kill: sum.kill + row.kill,
    assist: sum.assist + row.assist, death: sum.death + row.death,
  }), { score: 0, kill: 0, assist: 0, death: 0 });
  return { ...totals, kd: (totals.kill / Math.max(1, totals.death)).toFixed(2) };
};

export const personalStanding = (rows: ScoreboardRow[]) => {
  const players = activeRows(rows);
  const index = players.findIndex((row) => row.isMe);
  if (index < 0) return { count: players.length, position: null, gap: "" };
  const player = players[index];
  const rival = players[index === 0 ? 1 : index - 1];
  const gap = rival ? Math.abs(player.score - rival.score) : 0;
  return {
    count: players.length,
    position: player.rank || index + 1,
    gap: !rival ? "" : gap === 0 ? "TIED ON SCORE" : index === 0
      ? `${gap.toLocaleString("en-US")} SCORE AHEAD OF 2ND`
      : `${gap.toLocaleString("en-US")} SCORE TO NEXT POSITION`,
  };
};
