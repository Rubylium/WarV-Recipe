import { useSelector } from "../..";
import PlayerCard from "../../Components/PlayerCard";
import { act, hover, nf } from "../../ui";
import "./index.scss";

const Stat = ({ label, value, big }: { label: string; value: string | number; big?: boolean }) => (
  <div className={`br__stat${big ? " br__stat--big" : ""}`}>
    <span className="br__stat-value">{value}</span>
    <span className="br__stat-label">{label}</span>
  </div>
);

const Barracks = () => {
  const data = useSelector((s) => s.barracks);
  const p = data.player;
  const s = data.stats;
  const xpPct = Math.max(0, Math.min(100, (p.xp / (p.xpMax || 1)) * 100));

  return (
    <div className="br">
      <aside className="br__left">
        <PlayerCard p={p} />
        <div className="br__actions">
          <button className="br__action" onMouseEnter={hover} onClick={() => act("open_callingcards")}>
            <span className="br__action-label">Calling Cards</span>
            <span className="br__action-sub">Change your banner</span>
          </button>
          <button className="br__action" onMouseEnter={hover} onClick={() => act("open_emblems")}>
            <span className="br__action-label">Emblems</span>
            <span className="br__action-sub">Change your emblem</span>
          </button>
          <button
            className={`br__action br__action--prestige${s.canPrestige ? "" : " br__action--locked"}`}
            onMouseEnter={() => s.canPrestige && hover()}
            onClick={() => s.canPrestige && act("prestige")}
          >
            <span className="br__action-label">Prestige Mode</span>
            <span className="br__action-sub">{s.canPrestige ? "Available now" : "Reach level 55"}</span>
          </button>
        </div>
      </aside>

      <section className="br__stats">
        <div className="br__hero">
          <Stat label="K / D / A Ratio" value={s.kda} big />
          <div className="br__hero-div" />
          <Stat label="Win / Loss Ratio" value={s.wlr} big />
        </div>

        <div className="br__grid">
          <Stat label="Kills" value={nf(s.kills)} />
          <Stat label="Deaths" value={nf(s.deaths)} />
          <Stat label="Assists" value={nf(s.assists)} />
          <Stat label="Wins" value={nf(s.wins)} />
          <Stat label="Draws" value={nf(s.draws)} />
          <Stat label="Losses" value={nf(s.losses)} />
          <Stat label="Best Win Streak" value={nf(s.bestWinStreak)} />
          <Stat label="Headshot Ratio" value={s.headshotRatio} />
          <Stat label="Score" value={nf(s.score)} />
          <Stat label="Playtime" value={s.playtimeText || "0h"} />
        </div>

        <div className="br__level">
          <div className="br__level-head">
            <span>
              Level {p.level}
              {p.prestige > 0 ? ` · Prestige ${p.prestige}` : ""}
            </span>
            <span>{Math.round(xpPct)}%</span>
          </div>
          <div className="br__xp">
            <div className="br__xp-fill" style={{ width: `${xpPct}%` }} />
          </div>
        </div>
      </section>
    </div>
  );
};

export default Barracks;
