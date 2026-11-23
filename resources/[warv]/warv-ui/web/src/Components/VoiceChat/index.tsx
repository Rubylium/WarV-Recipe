import { useSelector } from "../..";
import { IMG } from "../../images";
import "./index.scss";

const MIC = IMG("menu/voice/microphone_talking.png");

const VoiceChat = () => {
  const players = useSelector((s) => s.voiceChat);
  if (!players || players.length === 0) return null;

  return (
    <div className="vc">
      {players.map((p, i) => (
        <div key={i} className={`vc__row${p.talking ? " vc__row--talking" : ""}`}>
          <img className="vc__icon" src={MIC} alt="" draggable={false} />
          <span className="vc__name">{p.name}</span>
        </div>
      ))}
    </div>
  );
};

export default VoiceChat;
