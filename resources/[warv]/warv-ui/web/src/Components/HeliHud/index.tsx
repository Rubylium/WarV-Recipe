import { useEffect, useRef, useState } from "react";
import { IMG } from "../../images";
import SensorOverlay from "../SensorOverlay";
import TargetMarker from "../TargetMarker";
import { pad } from "../../Utils";
import "./index.scss";

interface HeliMarker {
  x: number;
  y: number;
  kind: "target" | "self";
}
interface HeliData {
  visible: boolean;
  markers?: HeliMarker[];
  time?: number;
  gun?: "ready" | "firing";
  alt?: number;
  spd?: number;
  hdg?: number;
  pitch?: number;
  roll?: number;
  hp?: number;
}

const HeliHud = () => {
  const [data, setData] = useState<HeliData>({ visible: false });
  const [, setTick] = useState(0);
  const t0 = useRef(0);

  useEffect(() => {
    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || d.type !== "SET_HELI") return;
      const p = d.payload as HeliData;
      setData((prev) => {
        if (p.visible && !prev.visible) t0.current = Date.now();
        return { ...prev, ...p };
      });
    };
    window.addEventListener("message", onMsg);
    const iv = window.setInterval(() => setTick((t) => t + 1), 1000);
    return () => {
      window.removeEventListener("message", onMsg);
      window.clearInterval(iv);
    };
  }, []);

  if (!data.visible) return null;
  const markers = data.markers || [];
  const time = Math.max(0, Math.round(data.time || 0));
  const firing = data.gun === "firing";
  const hp = Math.max(0, Math.round(data.hp ?? 100));
  const elapsed = Math.floor((Date.now() - t0.current) / 1000);
  const clock = `T+${pad(Math.floor(elapsed / 60), 2)}:${pad(elapsed % 60, 2)}`;

  return (
    <div className="hh">
      <img
        className="hh__vignette"
        src={IMG("hud/targeting/vignette.png")}
        alt=""
        draggable={false}
      />
      <div className="hh__grain" />
      <div className="hh__frame" />
      <div className="hh__ticks hh__ticks--top" />
      <div className="hh__ticks hh__ticks--bottom" />
      <div className="hh__ticks hh__ticks--left" />
      <div className="hh__ticks hh__ticks--right" />

      <SensorOverlay
        platform="AKULA EO/IR"
        weapon="30MM HEI"
        status={firing ? "GUN ACTIVE" : "WPN LIMIT"}
        heading={data.hdg}
        pitch={data.pitch}
        roll={data.roll}
        altitude={data.alt}
        speed={data.spd}
        time={clock}
      />

      <div className="hh__blk hh__blk--tl">
        <span>AKULA 30MM GUN</span>
        <span>TV-WHT FLTR 1</span>
        <span>{clock}</span>
      </div>
      <div className="hh__blk hh__blk--tr">
        <span>ALT {pad(Math.round(data.alt || 0), 4)}M AGL</span>
        <span>GS {pad(Math.round(data.spd || 0), 3)} M/S</span>
        <span>HDG {pad(Math.round(data.hdg || 0) % 360, 3)}</span>
        <span className={hp <= 35 ? "hh__warn" : ""}>AIRFRAME {pad(hp, 3)}%</span>
      </div>
      <div className="hh__blk hh__blk--bl">
        <span className={firing ? "hh__warn" : "hh__armed"}>{firing ? "GUN HOT" : "GUN ARMED"}</span>
        <span className={time <= 10 ? "hh__warn" : ""}>
          ON STATION 0:{pad(time, 2)}
        </span>
      </div>
      <div className="hh__blk hh__blk--br">
        <span>RNG AUTO</span>
        <span>LINK OK</span>
      </div>

      {markers.map((m, i) => (
        <TargetMarker key={i} x={m.x} y={m.y} label={m.kind === "self" ? "OWN" : "TARGET"} />
      ))}

      <div className="hh__status">
        {firing ? <span className="hh__status-hot">GUNS GUNS GUNS</span> : <span>CLEARED TO ENGAGE</span>}
      </div>
    </div>
  );
};

export default HeliHud;
