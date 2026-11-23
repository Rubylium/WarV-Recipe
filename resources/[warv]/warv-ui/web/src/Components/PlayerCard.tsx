import CallingCard from "./CallingCard";
import Emblem from "./Emblem";
import RankBadge from "./RankBadge";
import { nf } from "../ui";
import { MenuPlayer } from "../types";
import "./PlayerCard.scss";

const PlayerCard = ({ p }: { p: MenuPlayer }) => {
  const xpPct = Math.max(0, Math.min(100, (p.xp / (p.xpMax || 1)) * 100));
  return (
    <div className="pc">
      <CallingCard sprite={p.callingCard} className="pc__cc" />
      <div className="pc__scrim" />
      <Emblem sprite={p.emblem} className="pc__emblem" />
      <div className="pc__content">
        <RankBadge icon={p.rankIcon} prestige={p.prestige} className="pc__rank" />
        <div className="pc__info">
          <div className="pc__top">
            <span className="pc__name">{p.name}</span>
            <span className="pc__uid">#{p.uid}</span>
          </div>
          <div className="pc__meta">
            {p.prestige > 0 && <span className="pc__prestige">P{p.prestige}</span>}
            <span className="pc__level">LVL {p.level}</span>
            <span className="pc__credit">
              <b>{nf(p.credit)}</b> CR
            </span>
          </div>
        </div>
      </div>
      <div className="pc__xp">
        <div className="pc__xp-fill" style={{ width: `${xpPct}%` }} />
      </div>
    </div>
  );
};

export default PlayerCard;
