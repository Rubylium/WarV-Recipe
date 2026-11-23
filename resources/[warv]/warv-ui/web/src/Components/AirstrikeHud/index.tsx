import { useEffect, useRef, useState } from "react";
import { pad } from "../../Utils";
import "./index.scss";

interface Pt {
  x: number;
  y: number;
}
interface Target extends Pt {
  gx?: number;
  gy?: number;
}
interface AirstrikeData {
  visible: boolean;
  cursor?: Pt;
  targets?: Target[];
  pings?: Pt[];
  alt?: number;
  grid?: Pt;
}

const rounds = 3;

const AirstrikeHud = () => {
  const [data, setData] = useState<AirstrikeData>({ visible: false });
  const [, setTick] = useState(0);
  const t0 = useRef(0);

  useEffect(() => {
    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || d.type !== "SET_AIRSTRIKE") return;
      const p = d.payload as AirstrikeData;
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
  const targets = data.targets || [];
  const pings = data.pings || [];
  const remaining = Math.max(0, rounds - targets.length);
  const elapsed = Math.floor((Date.now() - t0.current) / 1000);
  const mm = pad(Math.floor(elapsed / 60), 2);
  const ss = pad(elapsed % 60, 2);
  const cx = data.cursor ? data.cursor.x : 0.5;
  const cy = data.cursor ? data.cursor.y : 0.5;

  return (
    <div className="as">
      <div className="as__grain" />
      <div className="as__frame" />
      <div className="as__ticks as__ticks--top" />
      <div className="as__ticks as__ticks--bottom" />
      <div className="as__ticks as__ticks--left" />
      <div className="as__ticks as__ticks--right" />

      <div className="as__xline" style={{ top: `${cy * 100}%` }} />
      <div className="as__yline" style={{ left: `${cx * 100}%` }} />
      <div className="as__gate" style={{ left: `${cx * 100}%`, top: `${cy * 100}%` }} />

      <div className="as__blk as__blk--tl">
        <span>LTNG STRIKE 105MM</span>
        <span>IR-WHT FLTR 2</span>
        <span>T+{mm}:{ss}</span>
      </div>
      <div className="as__blk as__blk--tr">
        <span>ALT {pad(Math.round(data.alt || 0), 4)}M AGL</span>
        <span>
          GRID {pad(Math.round(data.grid?.x ?? 0), 5)} {pad(Math.round(data.grid?.y ?? 0), 5)}
        </span>
        <span>SLANT 0.0 GS 00</span>
      </div>
      <div className="as__blk as__blk--bl">
        <span className={remaining > 0 ? "as__armed" : ""}>{remaining > 0 ? "LASER ARMED" : "LASER SAFE"}</span>
        <span>RNDS {pad(remaining, 2)}/03</span>
      </div>
      <div className="as__blk as__blk--br">
        {targets.map((t, i) => (
          <span key={i}>
            TGT {pad(i + 1, 2)} {pad(Math.round(t.gx ?? 0), 5)} {pad(Math.round(t.gy ?? 0), 5)}
          </span>
        ))}
        {targets.length === 0 && <span>NO TGT DATA</span>}
      </div>

      {pings.map((p, i) => (
        <div key={`p${i}`} className="as__mover" style={{ left: `${p.x * 100}%`, top: `${p.y * 100}%` }}>
          <span className="as__mover-box" />
          <span className="as__mover-tag">MOVER</span>
        </div>
      ))}

      {targets.map((t, i) => (
        <div key={`t${i}`} className="as__tgt" style={{ left: `${t.x * 100}%`, top: `${t.y * 100}%` }}>
          <span className="as__tgt-flash" />
          <span className="as__tgt-box" />
          <span className="as__tgt-cross" />
          <span className="as__tgt-tag">TGT {pad(i + 1, 2)}</span>
        </div>
      ))}

      <div className="as__status">
        {remaining > 0 ? (
          <span>CLEARED HOT · {remaining} RND{remaining > 1 ? "S" : ""}</span>
        ) : (
          <span className="as__status-away">RIFLE · ROUNDS AWAY</span>
        )}
      </div>
    </div>
  );
};

export default AirstrikeHud;
