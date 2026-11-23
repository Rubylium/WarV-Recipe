import { ComponentType, SVGProps, useEffect, useRef, useState } from "react";
import { FiClock } from "react-icons/fi";
import { useSelector } from "../..";
import { IMG } from "../../images";
import { KillstreakEntry } from "../../types";
import "./index.scss";

const monogramOf = (label: string) => {
  const words = label.trim().split(/\s+/);
  const base = words.length > 1 ? words.map((w) => w[0]).join("") : label;
  return base.slice(0, 3).toUpperCase();
};

const ClockIcon = FiClock as ComponentType<SVGProps<SVGSVGElement>>;

const radius = 16;
const circ = 2 * Math.PI * radius;

const Card = ({ e }: { e: KillstreakEntry }) => {
  const [imgOk, setImgOk] = useState(true);
  const cooldownPct =
    e.cooldownTotal > 0
      ? Math.max(0, Math.min(100, (e.cooldownRemaining / e.cooldownTotal) * 100))
      : 0;
  const pct =
    e.state === "ready"
      ? 100
      : e.state === "spent"
        ? 0
        : e.state === "cooldown"
          ? cooldownPct
          : Math.max(0, Math.min(100, e.pct));
  const offset = circ * (1 - pct / 100);

  return (
    <div className={`ks__card ks__card--${e.state}`}>
      {e.state === "cooldown" && (
        <span className="ks__cooldown">
          <span className="ks__cooldown-label">
            <ClockIcon />
            Cooldown
          </span>
          <span className="ks__cooldown-time">{e.cooldownRemaining}s</span>
        </span>
      )}

      {e.state === "ready" && (
        <span className="ks__ready">
          <span className="ks__ready-txt">Ready</span>
          <span className="ks__ready-key">{e.key}</span>
        </span>
      )}

      <span className="ks__disc">
        <svg className="ks__ring" viewBox="0 0 36 36">
          <circle className="ks__ring-track" cx="18" cy="18" r={radius} />
          <circle
            className="ks__ring-fill"
            cx="18"
            cy="18"
            r={radius}
            style={{ strokeDasharray: circ, strokeDashoffset: offset }}
          />
        </svg>
        <span className="ks__icon">
          {imgOk ? (
            <img
              src={IMG(`hud/killstreaks/${e.icon}.png`)}
              alt=""
              draggable={false}
              onError={() => setImgOk(false)}
            />
          ) : (
            <span className="ks__mono">{monogramOf(e.label)}</span>
          )}
        </span>
      </span>
    </div>
  );
};

const KillstreakHud = () => {
  const d = useSelector((s) => s.killstreaks);
  const screen = useSelector((s) => s.screen);
  const show = d.visible && screen === "none" && d.streaks.length > 0;

  const prev = useRef<Record<string, string>>({});
  const [flash, setFlash] = useState(0);
  useEffect(() => {
    let newlyReady = false;
    for (const s of d.streaks) {
      const was = prev.current[s.key];
      if (s.state === "ready" && was !== undefined && was !== "ready") newlyReady = true;
      prev.current[s.key] = s.state;
    }
    if (newlyReady) setFlash((f) => f + 1);
  }, [d.streaks]);

  return (
    <>
      {show && flash > 0 && <div key={flash} className="ks-flash" />}

      <div className={`ks${show ? " ks--show" : ""}`}>
        {d.streaks.map((e) => (
          <Card key={e.key} e={e} />
        ))}
      </div>
    </>
  );
};

export default KillstreakHud;
