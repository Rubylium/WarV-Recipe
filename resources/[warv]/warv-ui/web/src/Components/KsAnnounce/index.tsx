import { useEffect, useRef, useState } from "react";
import CallingCard from "../CallingCard";
import "./index.scss";

interface Announce {
  id: number;
  name: string;
  message: string;
  card: string;
  friendly: boolean;
}

const showMs = 3000;
const leaveMs = 420;

const KsAnnounce = () => {
  const [item, setItem] = useState<Announce | null>(null);
  const [leaving, setLeaving] = useState(false);
  const queue = useRef<Announce[]>([]);
  const idRef = useRef(0);
  const showingRef = useRef(false);
  const timers = useRef<number[]>([]);

  useEffect(() => {
    const clearT = () => {
      timers.current.forEach((t) => window.clearTimeout(t));
      timers.current = [];
    };

    function showNext() {
      clearT();
      const next = queue.current.shift();
      if (!next) {
        showingRef.current = false;
        setItem(null);
        return;
      }
      showingRef.current = true;
      setLeaving(false);
      setItem(next);
      timers.current.push(
        window.setTimeout(() => {
          setLeaving(true);
          timers.current.push(window.setTimeout(showNext, leaveMs));
        }, showMs)
      );
    }

    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || d.type !== "KS_ANNOUNCE") return;
      const p = (d.payload || {}) as Partial<Announce>;
      queue.current.push({
        id: ++idRef.current,
        name: String(p.name || ""),
        message: String(p.message || ""),
        card: String(p.card || ""),
        friendly: !!p.friendly,
      });
      if (!showingRef.current) showNext();
    };

    window.addEventListener("message", onMsg);
    return () => {
      window.removeEventListener("message", onMsg);
      clearT();
    };
  }, []);

  if (!item) return null;
  const side = item.friendly ? "ally" : "enemy";
  return (
    <div key={item.id} className={`ksa ksa--${side}${leaving ? " ksa--leaving" : ""}`}>
      <CallingCard sprite={item.card} className="ksa__cc" />
      <div className="ksa__scrim" />
      <div className="ksa__body">
        <span className="ksa__eyebrow">{item.friendly ? "Ally Killstreak" : "Enemy Killstreak"}</span>
        <span className="ksa__name">{item.name}</span>
        <span className="ksa__msg">{item.message}</span>
      </div>
    </div>
  );
};

export default KsAnnounce;
