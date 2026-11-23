import { useEffect, useRef, useState } from "react";
import "./index.scss";

const labelHold = 1000;
const labelLeave = 420;
const totalIdle = 1500;
const totalFade = 420;
const maxLabels = 5;

interface Label {
  id: number;
  text: string;
  leaving: boolean;
}

const ScorePopup = () => {
  const [total, setTotal] = useState(0);
  const [visible, setVisible] = useState(false);
  const [pump, setPump] = useState(0);
  const [feed, setFeed] = useState<Label[]>([]);
  const idRef = useRef(0);
  const idleRef = useRef<number | undefined>(undefined);
  const resetRef = useRef<number | undefined>(undefined);

  useEffect(() => {
    const addLabel = (text: string) => {
      const id = ++idRef.current;
      setFeed((f) => [{ id, text, leaving: false }, ...f].slice(0, maxLabels));
      window.setTimeout(() => {
        setFeed((f) => f.map((r) => (r.id === id ? { ...r, leaving: true } : r)));
        window.setTimeout(() => setFeed((f) => f.filter((r) => r.id !== id)), labelLeave);
      }, labelHold);
    };

    const clear = () => {
      window.clearTimeout(idleRef.current);
      window.clearTimeout(resetRef.current);
    };

    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || !d.type) return;
      if (d.type === "HUD_SCORE") {
        const p = d.payload || {};
        const points = Number(p.points) || 0;
        setTotal((t) => t + points);
        setVisible(true);
        setPump((x) => x + 1);
        if (p.label) addLabel(String(p.label).toUpperCase());
        clear();
        idleRef.current = window.setTimeout(() => {
          setVisible(false);
          resetRef.current = window.setTimeout(() => setTotal(0), totalFade);
        }, totalIdle);
      } else if (d.type === "HUD_SCORE_RESET") {
        clear();
        setVisible(false);
        setTotal(0);
        setFeed([]);
      }
    };

    window.addEventListener("message", onMsg);
    return () => window.removeEventListener("message", onMsg);
  }, []);

  if (total <= 0 && feed.length === 0) return null;

  return (
    <div className="sp">
      {total > 0 && (
        <div className={`sp__total${visible ? "" : " sp__total--out"}`}>
          <span className="sp__num" key={pump}>
            <b className="sp__plus">+</b>
            {total}
          </span>
          <span className="sp__xp">XP</span>
        </div>
      )}
      <div className="sp__feed">
        {feed.map((r) => (
          <div key={r.id} className={`sp__label${r.leaving ? " sp__label--leave" : " sp__label--in"}`}>
            <span className="sp__tick" />
            {r.text}
          </div>
        ))}
      </div>
    </div>
  );
};

export default ScorePopup;
