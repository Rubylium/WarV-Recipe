import { useEffect, useRef, useState } from "react";
import { uiSound } from "../../ui";
import "./index.scss";

interface Popup {
  id: string;
  text: string;
  x: number;
  y: number;
  align: "left" | "center" | "right";
  size: number;
  duration: number;
  sound: boolean;
  gen: number;
}

const charMs = 45;
const leaveMs = 400;

const TypeItem = ({ p, onDone }: { p: Popup; onDone: (id: string, gen: number) => void }) => {
  const [shown, setShown] = useState(0);
  const [leaving, setLeaving] = useState(false);

  useEffect(() => {
    let n = 0;
    setShown(0);
    setLeaving(false);
    const timers: number[] = [];
    const iv = window.setInterval(() => {
      n++;
      setShown(n);
      if (p.sound) uiSound("type_blip");
      if (n >= p.text.length) {
        window.clearInterval(iv);
        timers.push(
          window.setTimeout(() => {
            setLeaving(true);
            timers.push(window.setTimeout(() => onDone(p.id, p.gen), leaveMs));
          }, Math.max(0, p.duration))
        );
      }
    }, charMs);
    return () => {
      window.clearInterval(iv);
      timers.forEach((t) => window.clearTimeout(t));
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [p.gen]);

  const style: React.CSSProperties = {
    top: `${p.y * 100}%`,
    fontSize: `${p.size * 4}vh`,
  };
  if (p.align === "center") {
    style.left = `${p.x * 100}%`;
    style.transform = "translateX(-50%)";
  } else if (p.align === "right") {
    style.right = `${(1 - p.x) * 100}%`;
  } else {
    style.left = `${p.x * 100}%`;
  }

  return (
    <div className={`tt__item${leaving ? " tt__item--leaving" : ""}`} style={style}>
      {p.text.slice(0, shown)}
    </div>
  );
};

const TypeText = () => {
  const [items, setItems] = useState<Record<string, Popup>>({});
  const genRef = useRef(0);

  useEffect(() => {
    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || d.type !== "TYPE_TEXT") return;
      const p = (d.payload || {}) as Partial<Popup>;
      const id = String(p.id || "");
      if (!id) return;
      setItems((m) => {
        const next = { ...m };
        const text = String(p.text || "");
        if (!text) {
          delete next[id];
          return next;
        }
        next[id] = {
          id,
          text,
          x: Number(p.x ?? 0.5),
          y: Number(p.y ?? 0.5),
          align: (p.align as Popup["align"]) || "center",
          size: Number(p.size ?? 0.5),
          duration: Number(p.duration ?? 3000),
          sound: !!p.sound,
          gen: ++genRef.current,
        };
        return next;
      });
    };
    window.addEventListener("message", onMsg);
    return () => window.removeEventListener("message", onMsg);
  }, []);

  const remove = (id: string, gen: number) =>
    setItems((m) => {
      if (!m[id] || m[id].gen !== gen) return m;
      const next = { ...m };
      delete next[id];
      return next;
    });

  const list = Object.values(items);
  if (list.length === 0) return null;
  return (
    <div className="tt">
      {list.map((p) => (
        <TypeItem key={p.id} p={p} onDone={remove} />
      ))}
    </div>
  );
};

export default TypeText;
