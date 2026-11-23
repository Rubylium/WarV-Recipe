import { useState } from "react";
import { useSelector } from "../..";
import "./index.scss";

const loadingBg = `${process.env.PUBLIC_URL}/assets/images/loading/match_loading_background.jpg`;

const clamp = (n: number) => Math.max(0, Math.min(100, Math.floor(n || 0)));

const LoadingScreen = ({ closing }: { closing?: boolean }) => {
  const loading = useSelector((s) => s.loading);
  const [bgOk, setBgOk] = useState(true);
  const pct = clamp(loading.progress);

  return (
    <div className={`ls${closing ? " ls--closing" : ""}`}>
      {bgOk ? (
        <img
          className="ls__bg"
          src={loadingBg}
          alt=""
          draggable={false}
          onError={() => setBgOk(false)}
        />
      ) : (
        <div className="ls__bg ls__bg--placeholder" />
      )}
      <div className="ls__scrim" />
      <div className="ls__frame" />

      <div className="ls__center">
        <div className="ls__kicker">work in progress &bull; Pre-Alpha</div>
        <div className="ls__title">WARV</div>
        <div className="ls__subtitle">NEW PVP EXPERIENCE</div>

        <div className="ls__rule">
          <span />
          <i />
          <span />
        </div>

        <div className="ls__loader">
          <div className="ls__status">
            {loading.status || "Loading game assets"}
          </div>
          <div className="ls__bar">
            <div className="ls__bar-track">
              <div className="ls__bar-fill" style={{ width: `${pct}%` }} />
            </div>
            <div className="ls__pct">
              {pct}
              <span>%</span>
            </div>
          </div>
        </div>
      </div>

      <div className="ls__shutter ls__shutter--top" />
      <div className="ls__shutter ls__shutter--bottom" />
      <div className="ls__sweep" />
    </div>
  );
};

export default LoadingScreen;
