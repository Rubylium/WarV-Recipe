import { useSelector } from "../..";
import "./index.scss";

const Countdown = () => {
  const d = useSelector((s) => s.countdown);
  if (!d.visible || d.seconds <= 0) return null;

  return (
    <div className="cd">
      {d.label && <div className="cd__label">{d.label}</div>}
      <div className={`cd__num${d.seconds <= 5 ? " cd__num--hot" : ""}`} key={d.seconds}>
        {d.seconds}
      </div>
      <div className="cd__rule">
        <span />
        <i />
        <span />
      </div>
    </div>
  );
};

export default Countdown;
