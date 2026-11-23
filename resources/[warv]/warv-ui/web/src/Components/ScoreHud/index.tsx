import { useSelector } from "../..";
import { hideImg, IMG } from "../../images";
import "./index.scss";

const fmt = (s: number) => {
  s = Math.max(0, Math.floor(s || 0));
  const m = Math.floor(s / 60);
  const ss = s % 60;
  return `${m}:${ss < 10 ? "0" : ""}${ss}`;
};

const pct = (score: number, max: number) => Math.max(0, Math.min(100, (score / Math.max(1, max)) * 100));

const ScoreHud = () => {
  const d = useSelector((s) => s.scoreHud);
  const screen = useSelector((s) => s.screen);
  const show = d.visible && screen === "none";
  const low = d.timer > 0 && d.timer <= 10;

  const max = Math.max(d.maxScore, d.left.score, d.right.score, 1);
  const state = d.left.score > d.right.score ? "win" : d.left.score < d.right.score ? "lose" : "tie";
  const statusText = state === "win" ? "WINNING" : state === "lose" ? "LOSING" : "TIED";
  const statusColor = state === "win" ? d.left.color : state === "lose" ? d.right.color : "";

  return (
    <div className={`sh${show ? " sh--show" : ""}`}>
      {d.gmIcon && (
        <div className="sh__icon">
          <img
            className="sh__icon-img"
            src={IMG(`gamemode/icons/${d.gmIcon}.png`)}
            alt=""
            draggable={false}
            onError={hideImg}
          />
        </div>
      )}

      <div className="sh__main">
        <div className="sh__row sh__row--top">
          <span className="sh__num" key={`l${d.left.score}`}>
            {d.left.label && <em className="sh__tag">{d.left.label}</em>}
            {d.left.score}
          </span>
          <span className={`sh__status${statusColor ? ` sh__status--${statusColor}` : " sh__status--tie"}`}>
            {statusText}
          </span>
        </div>

        <div className="sh__bars">
          <span className={`sh__bar sh__bar--top sh__bar--${d.left.color}`}>
            <span className="sh__bar-fill" style={{ width: `${pct(d.left.score, max)}%` }} />
          </span>
          <span className={`sh__bar sh__bar--bot sh__bar--${d.right.color}`}>
            <span className="sh__bar-fill" style={{ width: `${pct(d.right.score, max)}%` }} />
          </span>
        </div>

        <div className="sh__row sh__row--bot">
          <span className="sh__num" key={`r${d.right.score}`}>
            {d.right.label && <em className="sh__tag">{d.right.label}</em>}
            {d.right.score}
          </span>
          <span className={`sh__timer${low ? " sh__timer--low" : ""}`}>{fmt(d.timer)}</span>
        </div>
      </div>
    </div>
  );
};

export default ScoreHud;
