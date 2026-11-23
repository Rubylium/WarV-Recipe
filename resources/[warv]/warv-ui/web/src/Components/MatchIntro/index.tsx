import { useSelector } from "../..";
import "./index.scss";

const MatchIntro = () => {
  const d = useSelector((s) => s.matchIntro);
  if (!d.visible || (!d.map && !d.gamemode)) return null;

  return (
    <div className={`mi mi--${d.teamColor}`}>
      <div className="mi__header">
        <span className="mi__bar" />
        <div className="mi__lines">
          {d.gamemode && <span className="mi__gm">{d.gamemode}</span>}
          {d.map && <span className="mi__map">{d.map}</span>}
        </div>
      </div>
    </div>
  );
};

export default MatchIntro;
