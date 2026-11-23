import { IMG } from "../../images";
import "./medal.scss";

interface MedalCardProps {
  d: Record<string, unknown>;
  leaving: boolean;
}

const MedalCard = ({ d, leaving }: MedalCardProps) => {
  const count = Math.max(1, Number(d.count) || 1);
  const label = String(d.label || "Medal");

  return (
    <div className={`ntf-banner ntf-banner--medal${leaving ? " ntf-banner--leaving" : ""}`}>
      <div className="ntf-banner__sweep" />
      <div className="ntf-banner__badge ntf-medal__badge">
        <img
          className="ntf-medal__icon"
          src={IMG("hud/medals/skull_medal.png")}
          alt=""
          draggable={false}
        />
        {count > 1 && (
          <span className="ntf-medal__count" key={count}>
            {"\u00D7"}{count}
          </span>
        )}
      </div>
      <div className="ntf-banner__body">
        <span className="ntf-banner__name">{label}</span>
      </div>
    </div>
  );
};

export default MedalCard;
