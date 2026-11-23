import { useState } from "react";
import { useSelector } from "../..";
import { IMG, hideImg } from "../../images";
import "./index.scss";

const clamp = (n: number) => Math.max(0, Math.min(100, Math.floor(n || 0)));

const TeamBlock = ({ side, tag }: { side: 1 | 2; tag: string }) => (
  <div className={`ml__team ml__team--${side}`}>
    <img
      className="ml__team-img"
      src={IMG(`teams/team_${side}.png`)}
      alt=""
      draggable={false}
      onError={hideImg}
    />
    <span className="ml__team-tag">{tag}</span>
  </div>
);

const MatchLoading = ({ closing }: { closing?: boolean }) => {
  const d = useSelector((s) => s.matchLoading);
  const [bgOk, setBgOk] = useState(true);
  const waiting = d.phase === "waiting";
  const pct = clamp(d.progress);
  const label = waiting
    ? d.waitingText || "Waiting for players"
    : "Loading game assets";

  return (
    <div className={`ml${waiting ? " ml--waiting" : ""}${closing ? " ml--closing" : ""}${!d.teamMode ? " ml--ffa" : ""}`}>
      {bgOk && d.map.image ? (
        <img
          className="ml__bg"
          src={IMG(`maps/${d.map.image}.png`)}
          alt=""
          draggable={false}
          onError={() => setBgOk(false)}
        />
      ) : (
        <div className="ml__bg ml__bg--placeholder" />
      )}
      <div className="ml__scrim" />

      <img
        className="ml__side ml__side--left"
        src={IMG("teams/team_1.png")}
        alt=""
        draggable={false}
        onError={hideImg}
      />
      <img
        className="ml__side ml__side--right"
        src={IMG("teams/team_2.png")}
        alt=""
        draggable={false}
        onError={hideImg}
      />

      <div className="ml__bar ml__bar--top" />
      <div className="ml__bar ml__bar--bottom" />

      <div className="ml__center">
        <div className="ml__kicker">
          {d.ranked && <span className="ml__ranked">Ranked</span>}
          {d.gamemode || "Deploying"}
        </div>
        <div className="ml__map">{d.map.name || "Unknown"}</div>
        <div className="ml__ruler">
          <span />
          <i />
          <span />
        </div>
        {d.teamMode && (
          <div className="ml__teams">
            <TeamBlock side={1} tag="ISA" />
            <div className="ml__vs">
              <i className="ml__vs-diamond" />
              <span className="ml__vs-txt">VS</span>
            </div>
            <TeamBlock side={2} tag="MERCS" />
          </div>
        )}
      </div>

      <div className="ml__foot">
        {d.tip ? <div className="ml__tip">{d.tip}</div> : <span />}

        <div className="ml__progress">
          <div className="ml__progress-head">
            <span className="ml__progress-label">
              {label}
              <span className="ml__dots" />
            </span>
            {!waiting && (
              <span className="ml__pct">
                {pct}
                <span>%</span>
              </span>
            )}
          </div>
          <div className="ml__pbar">
            <span className="ml__pbar-cap" />
            <div className="ml__pbar-track">
              <div
                className={`ml__pbar-fill${waiting ? " ml__pbar-fill--indet" : ""}`}
                style={waiting ? undefined : { width: `${pct}%` }}
              />
            </div>
            <span className="ml__pbar-cap" />
          </div>
        </div>
      </div>
    </div>
  );
};

export default MatchLoading;
