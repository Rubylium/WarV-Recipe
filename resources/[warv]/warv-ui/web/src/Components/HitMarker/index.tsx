import { useEffect, useRef, useState } from "react";
import { useSelector } from "../..";
import { IMG } from "../../images";
import "./index.scss";

const mask = `url(${IMG("hud/hitmarker_mask.png")})`;

const HitMarker = () => {
  const d = useSelector((s) => s.hitMarker);
  const [hit, setHit] = useState<{ n: number; kill: boolean } | null>(null);
  const timer = useRef<number>(0);

  useEffect(() => {
    if (d.n <= 0) return;
    setHit({ n: d.n, kill: d.kill });
    clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setHit(null), d.kill ? 300 : 220);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [d.n]);

  if (!hit) return null;

  return (
    <div className={`hm${hit.kill ? " hm--kill" : ""}`}>
      <div
        className="hm__icon"
        key={hit.n}
        style={{ WebkitMaskImage: mask, maskImage: mask }}
      />
    </div>
  );
};

export default HitMarker;
