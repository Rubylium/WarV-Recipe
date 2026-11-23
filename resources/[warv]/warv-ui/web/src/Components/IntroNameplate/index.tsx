import { useSelector } from "../..";
import "./index.scss";

const IntroNameplate = () => {
  const d = useSelector((s) => s.introTag);
  if (!d.visible || !d.name) return null;

  return (
    <div
      className={`inp inp--${d.teamColor}`}
      style={{ left: `${d.x * 100}%`, top: `${d.y * 100}%` }}
    >
      <div className="inp__plate" key={d.key}>
        <span className="inp__tick" />
        <span className="inp__name">{d.name}</span>
      </div>
    </div>
  );
};

export default IntroNameplate;
