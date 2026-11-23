import { IMG } from "../../images";
import { ScoreboardRow } from "../../types";
import RankBadge from "../RankBadge";
import { activeRows, teamTotals } from "./stats";

const teamIcons = [IMG("teams/team_1.png"), IMG("teams/team_2.png")];
export const ffaIcon = IMG("gamemode/icons/free_for_all.png");

const PlayerRow = ({ row, ffa }: { row: ScoreboardRow; ffa: boolean }) => (
  <div className={`scb__row${row.isMe ? " scb__row--me" : ""}`}>
    {ffa && <span className="scb__pos">{String(row.rank).padStart(2, "0")}</span>}
    <span className="scb__badge"><RankBadge icon={row.rankIcon} prestige={row.prestige} className="scb__rank" /></span>
    <span className="scb__lvl">{row.level}</span>
    <span className="scb__identity">
      <span className="scb__name">{row.name}</span>
      <span className="scb__uid">#{row.uid}{row.isMe ? " / YOU" : ""}</span>
    </span>
    <span className="scb__voice">
      {row.voice !== "none" && <img className={`scb__mic scb__mic--${row.voice}`}
        src={IMG(`menu/voice/${row.voice === "muted" ? "microphone_muted" : "microphone_talking"}.png`)} alt={row.voice} draggable={false} />}
    </span>
    <span className="scb__stat scb__stat--score"><span>{row.score}</span></span>
    <span className="scb__stat">{row.kill}</span>
    <span className="scb__stat">{row.assist}</span>
    <span className="scb__stat">{row.death}</span>
    <span className="scb__stat">{row.kd}</span>
    <span className="scb__stat scb__stat--ping">{row.ping}</span>
  </div>
);

export const Roster = ({ rows, ffa = false }: { rows: ScoreboardRow[]; ffa?: boolean }) => (
  <div className="scb__table">
    <div className="scb__row scb__row--head">
      {(ffa ? ["#", "", "LVL", "PLAYER", "", "SCORE", "K", "A", "D", "K/D", "PING"]
        : ["", "LVL", "PLAYER", "", "SCORE", "K", "A", "D", "K/D", "PING"]).map((label, index) => (
        <span key={index} className={label === "PLAYER" ? "scb__playerLabel" : ""}>{label}</span>
      ))}
    </div>
    {activeRows(rows).map((row) => <PlayerRow key={`${row.bot ? "bot" : "player"}-${row.id}-${row.uid}`} row={row} ffa={ffa} />)}
  </div>
);

export const TeamColumn = ({ rows, team, score, myTeam }: {
  rows: ScoreboardRow[]; team: 1 | 2; score: number | string; myTeam: number;
}) => {
  const players = activeRows(rows);
  const totals = teamTotals(rows);
  const relation = myTeam === 0 ? "" : myTeam === team ? "ALLIES / " : "ENEMIES / ";
  return <section className={`scb__col scb__col--t${team}`}>
    <div className="scb__team">
      <img className="scb__watermark" src={teamIcons[team - 1]} alt="" />
      <img className="scb__teamIcon" src={teamIcons[team - 1]} alt="" />
      <div className="scb__teamIdentity"><span>{team === 1 ? "ISA" : "MERCs"}</span>
        <small>{relation}{players.length} {players.length === 1 ? "PLAYER" : "PLAYERS"}</small></div>
      <span className="scb__teamScore">{score}</span>
    </div>
    <Roster rows={rows} />
    <div className="scb__row scb__totals">
      <span className="scb__totalLabel">TEAM TOTAL</span>
      <span className="scb__stat scb__totalScore">{totals.score.toLocaleString("en-US")}</span>
      <span className="scb__stat">{totals.kill}</span><span className="scb__stat">{totals.assist}</span>
      <span className="scb__stat">{totals.death}</span><span className="scb__stat">{totals.kd}</span><span />
    </div>
  </section>;
};
