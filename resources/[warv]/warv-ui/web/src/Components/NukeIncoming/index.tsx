import { useEffect, useRef, useState } from "react";
import "./index.scss";

const NukeIncoming = () => {
  const [state, setState] = useState<"" | "in" | "out">("");
  const timers = useRef<number[]>([]);

  useEffect(() => {
    const clear = () => {
      timers.current.forEach((t) => window.clearTimeout(t));
      timers.current = [];
    };

    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || d.type !== "NUKE_INCOMING") return;
      const total = Math.max(0, Number(d.payload?.ms) || 0);
      if (!total) return;

      clear();
      setState("in");
      timers.current.push(window.setTimeout(() => setState("out"), total - 600));
      timers.current.push(window.setTimeout(() => setState(""), total));
    };

    window.addEventListener("message", onMsg);
    return () => {
      window.removeEventListener("message", onMsg);
      clear();
    };
  }, []);

  if (!state) return null;

  return (
    <div className={`nk nk--${state}`}>
      <i className="nk__gem" />
      <span className="nk__text">Tactical Nuke Incoming</span>
      <i className="nk__gem" />
    </div>
  );
};

export default NukeIncoming;
