import { useEffect, useState } from "react";
import "./index.scss";

const RcxdHud = () => {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || d.type !== "SET_RCXD") return;
      setVisible(!!(d.payload && (d.payload as { visible?: boolean }).visible));
    };
    window.addEventListener("message", onMsg);
    return () => window.removeEventListener("message", onMsg);
  }, []);

  if (!visible) return null;
  return (
    <div className="rc">
      <div className="rc__scanlines" />
      <div className="rc__frame" />

      <div className="rc__feed">
        <span className="rc__rec" />
        <span className="rc__feed-label">RC-XD · Remote Feed</span>
      </div>

      <div className="rc__hints">
        <span className="rc__hint">
          <b>W / S</b> Throttle
        </span>
        <span className="rc__hint">
          <b>A / D</b> Steer
        </span>
        <span className="rc__hint rc__hint--det">
          <b>E</b> Detonate
        </span>
      </div>
    </div>
  );
};

export default RcxdHud;
