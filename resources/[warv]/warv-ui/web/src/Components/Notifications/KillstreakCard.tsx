import { hideImg, IMG } from "../../images";
import "./killstreak.scss";

interface KillstreakCardProps {
  d: Record<string, unknown>;
  leaving: boolean;
}

const KillstreakCard = ({ d, leaving }: KillstreakCardProps) => {
  const icon = String(d.icon || "");
  const key = String(d.key || "F1");
  const label = String(d.label || d.type || "Killstreak");

  return (
    <div className={`ntf-killstreak${leaving ? " ntf-killstreak--leaving" : ""}`}>
      <span className="ntf-killstreak__flare" />
      <div className="ntf-killstreak__icon-wrap">
        <span className="ntf-killstreak__icon-glow" />
        {icon && (
          <img
            className="ntf-killstreak__icon"
            src={IMG(`hud/killstreaks/${icon}.png`)}
            alt=""
            draggable={false}
            onError={hideImg}
          />
        )}
      </div>
      <div className="ntf-killstreak__body">
        <span className="ntf-killstreak__eyebrow">Killstreak Ready</span>
        <span className="ntf-killstreak__name">{label}</span>
        <span className="ntf-killstreak__action">
          Press <b>{key}</b> to use
        </span>
      </div>
      <span className="ntf-killstreak__sweep" />
    </div>
  );
};

export default KillstreakCard;
