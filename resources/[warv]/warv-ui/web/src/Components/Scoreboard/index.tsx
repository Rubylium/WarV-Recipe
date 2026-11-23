import { CSSProperties } from "react";
import { useSelector } from "../..";
import { Roster, TeamColumn, ffaIcon } from "./Roster";
import { activeRows, personalStanding } from "./stats";
import "./index.scss";
import "./roster.scss";

const Scoreboard = () => {
  const data = useSelector((state) => state.scoreboard);
  if (!data.visible) return null;
  const ffa = data.mode === "ffa";
  const standing = personalStanding(data.team1);
  const rowCount = Math.max(1, activeRows(data.team1).length, ffa ? 0 : activeRows(data.team2).length);
  const score1 = Math.max(0, Number(data.team1Score) || 0);
  const score2 = Math.max(0, Number(data.team2Score) || 0);
  const scoreShare = score1 + score2 ? score1 / (score1 + score2) * 100 : 50;
  return <div className={`scb${ffa ? " scb--ffa" : ""}`} style={{ "--rowCount": rowCount } as CSSProperties}>
    <div className="scb__panel">
      <header className="scb__top">
        {ffa && <><img className="scb__modeIcon" src={ffaIcon} alt="" /><img className="scb__modeWatermark" src={ffaIcon} alt="" /></>}
        <div className="scb__context"><small>SCOREBOARD</small><h2>{data.gamemode || (ffa ? "Free For All" : "Team Match")}</h2></div>
        {!ffa && <div className="scb__balance"><span>{data.team1Score} : {data.team2Score}</span>
          <div className="scb__balanceTrack"><i style={{ width: `${scoreShare}%` }} /></div></div>}
        <div className="scb__map"><small>MAP</small><span>{data.map}</span></div>
      </header>
      <div className="scb__cols">
        {ffa ? <Roster rows={data.team1} ffa /> : <>
          <TeamColumn rows={data.team1} team={1} score={data.team1Score} myTeam={data.myTeam} />
          <TeamColumn rows={data.team2} team={2} score={data.team2Score} myTeam={data.myTeam} />
        </>}
      </div>
      {ffa && <footer className="scb__standing">
        {standing.position !== null && <><span>YOUR POSITION</span><strong>{standing.position} / {standing.count}</strong><span>{standing.gap}</span></>}
        <span className="scb__playerCount">{standing.count} {standing.count === 1 ? "PLAYER" : "PLAYERS"}</span>
      </footer>}
    </div>
  </div>;
};
export default Scoreboard;
