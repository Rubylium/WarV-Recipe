import { useSelector } from "../..";
import { IMG } from "../../images";
import { PlayerMarkerKind } from "../../types";
import "./index.scss";

const icons: Record<PlayerMarkerKind, string> = {
  enemy: IMG("hud/markers/enemy_player.png"),
  friendly: IMG("hud/markers/friendly_player.png"),
  dead: IMG("hud/markers/dead_player.png"),
  drone: IMG("hud/markers/drone.png"),
};

const PlayerMarkers = () => {
  const markers = useSelector((s) => s.playerMarkers);
  if (!markers || markers.length === 0) return null;

  return (
    <div className="pm">
      {markers.map((m, i) => (
        <img
          key={i}
          className="pm__icon"
          src={icons[m.kind]}
          alt=""
          draggable={false}
          style={{ left: `${m.x * 100}%`, top: `${m.y * 100}%`, height: `${m.size}vh` }}
        />
      ))}
    </div>
  );
};

export default PlayerMarkers;
