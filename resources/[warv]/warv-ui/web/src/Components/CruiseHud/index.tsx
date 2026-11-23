import { useEffect, useRef, useState } from "react";
import { IMG } from "../../images";
import SensorOverlay from "../SensorOverlay";
import TargetMarker from "../TargetMarker";
import "./index.scss";

interface CruiseMarker {
  x: number;
  y: number;
  size: number;
  kind: "target" | "self";
}
interface CruiseData {
  phase: "off" | "cinematic" | "control";
  fuelMs?: number;
  alt?: number;
  spd?: number;
  hdg?: number;
  pitch?: number;
  roll?: number;
  markers?: CruiseMarker[];
}

const CruiseHud = () => {
  const [phase, setPhase] = useState<CruiseData["phase"]>("off");
  const [markers, setMarkers] = useState<CruiseMarker[]>([]);
  const [alt, setAlt] = useState(0);
  const [spd, setSpd] = useState(0);
  const [hdg, setHdg] = useState(0);
  const [pitch, setPitch] = useState(0);
  const [roll, setRoll] = useState(0);
  const [fuelMs, setFuelMs] = useState(0);
  const [fuelStarted, setFuelStarted] = useState(false);
  const phaseRef = useRef<CruiseData["phase"]>("off");

  useEffect(() => {
    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || d.type !== "SET_CRUISE") return;
      const p = (d.payload || {}) as CruiseData;
      if (p.phase && p.phase !== phaseRef.current) {
        phaseRef.current = p.phase;
        setPhase(p.phase);
        setFuelStarted(false);
        setMarkers([]);
        if (p.phase === "control" && p.fuelMs) {
          setFuelMs(p.fuelMs);
          requestAnimationFrame(() => requestAnimationFrame(() => setFuelStarted(true)));
        }
      }
      if (p.markers) setMarkers(p.markers);
      if (p.alt !== undefined) setAlt(p.alt);
      if (p.spd !== undefined) setSpd(p.spd);
      if (p.hdg !== undefined) setHdg(p.hdg);
      if (p.pitch !== undefined) setPitch(p.pitch);
      if (p.roll !== undefined) setRoll(p.roll);
    };
    window.addEventListener("message", onMsg);
    return () => window.removeEventListener("message", onMsg);
  }, []);

  if (phase === "off") return null;

  if (phase === "cinematic") {
    return (
      <div className="cr">
        <div className="cr__bar cr__bar--top" />
        <div className="cr__bar cr__bar--bot" />
      </div>
    );
  }

  return (
    <div className="cr">
      <img className="cr__vignette" src={IMG("hud/targeting/vignette.png")} alt="" draggable={false} />
      <div className="cr__scanlines" />

      <SensorOverlay
        platform="CRUISE EO"
        weapon="UNITARY HE"
        status="TERMINAL GUIDANCE"
        heading={hdg}
        pitch={pitch}
        roll={roll}
        altitude={alt}
        speed={spd}
        time="TGT AUTO"
      />

      <div className="cr__feed">
        <span className="cr__rec" />
        <span className="cr__feed-label">Cruise Missile · Live Feed</span>
      </div>

      <div className="cr__tele">
        <div className="cr__tele-row">
          <span className="cr__tele-k">Alt</span>
          <span className="cr__tele-v">{Math.max(0, Math.round(alt))}m</span>
        </div>
        <div className="cr__tele-row">
          <span className="cr__tele-k">Spd</span>
          <span className="cr__tele-v">{Math.max(0, Math.round(spd))}m/s</span>
        </div>
      </div>

      {markers.map((m, i) =>
        m.kind === "self" ? (
          <div key={i} className="cr__self" style={{ left: `${m.x * 100}%`, top: `${m.y * 100}%`, height: `${m.size}vh` }}>
            <span
              className="cr__self-ico"
              style={{
                WebkitMaskImage: `url(${IMG("hud/targeting/target_reticle.png")})`,
                maskImage: `url(${IMG("hud/targeting/target_reticle.png")})`,
              }}
            />
            <span className="cr__self-label">You</span>
          </div>
        ) : (
          <TargetMarker
            key={i}
            x={m.x}
            y={m.y}
            label="TARGET"
          />
        )
      )}

      <div className="cr__fuel" style={{ backgroundImage: `url(${IMG("hud/targeting/fuel_button_background.png")})` }}>
        <span className="cr__fuel-k">Fuel</span>
        <span className="cr__fuel-track">
          <span
            className="cr__fuel-fill"
            style={{ width: fuelStarted ? "0%" : "100%", transitionDuration: `${fuelMs}ms` }}
          />
        </span>
      </div>
      <span className="cr__hint">Proximity detonation armed</span>
    </div>
  );
};

export default CruiseHud;
