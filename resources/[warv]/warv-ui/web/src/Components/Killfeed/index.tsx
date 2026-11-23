import { useEffect, useRef, useState } from "react";
import { hideImg, IMG } from "../../images";
import { KillfeedEntry } from "../../types";
import "./index.scss";

interface Row extends KillfeedEntry {
  id: number;
  leaving: boolean;
}

const maxRows = 6;
const lifeMs = 4500;
const leaveMs = 420;

const Name = ({ name, friendly, dim }: { name: string; friendly: boolean; dim?: boolean }) => (
  <span
    className={`kf__name${friendly ? " kf__name--friendly" : " kf__name--enemy"}${dim ? " kf__name--dim" : ""}`}
  >
    {name}
  </span>
);

const KillIcon = ({ e }: { e: Row }) => {
  if (e.suicide) {
    return (
      <img className="kf__ico kf__ico--suicide" src={IMG("hud/suicide.png")} alt="" draggable={false} />
    );
  }
  return (
    <span className="kf__weapon">
      {e.weapon ? (
        <img
          className="kf__ico kf__ico--weapon"
          src={IMG(`weapons/${e.weapon}.png`)}
          alt=""
          draggable={false}
          onError={hideImg}
        />
      ) : e.special ? (
        <img
          className="kf__ico kf__ico--killstreak"
          src={IMG(`hud/killstreaks/${e.special}.png`)}
          alt=""
          draggable={false}
          onError={hideImg}
        />
      ) : (
        <span className="kf__ico kf__ico--generic" />
      )}
      {e.headshot && (
        <img className="kf__hs" src={IMG("hud/headshot.png")} alt="" draggable={false} />
      )}
    </span>
  );
};

const StreakBadge = ({ n }: { n: number }) => (
  <span className={`kf__streak kf__streak--t${Math.min(n, 6)}`}>
    <span className="kf__streak-chevron" />
    <span className="kf__streak-num">{n}</span>
  </span>
);

const KillRow = ({ e }: { e: Row }) => {
  const cls = [
    "kf__row",
    e.leaving ? "kf__row--leaving" : "kf__row--enter",
    e.mine ? "kf__row--mine" : "",
    e.headshot ? "kf__row--headshot" : "",
    e.suicide ? "kf__row--suicide" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={cls}>
      <div className="kf__inner">
        {e.mine && e.streak >= 2 && <StreakBadge n={e.streak} />}
        <Name name={e.killer} friendly={e.killerFriendly} dim={e.suicide} />
        <KillIcon e={e} />
        {!e.suicide && <Name name={e.victim} friendly={e.victimFriendly} />}
      </div>
    </div>
  );
};

const Killfeed = () => {
  const [rows, setRows] = useState<Row[]>([]);
  const idRef = useRef(0);

  useEffect(() => {
    const startLeave = (id: number) => {
      setRows((list) => list.map((r) => (r.id === id ? { ...r, leaving: true } : r)));
      window.setTimeout(() => {
        setRows((list) => list.filter((r) => r.id !== id));
      }, leaveMs);
    };

    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || !d.type) return;
      if (d.type === "HUD_KILL") {
        const id = ++idRef.current;
        const row: Row = { ...(d.payload as KillfeedEntry), id, leaving: false };
        setRows((list) => [row, ...list].slice(0, maxRows));
        window.setTimeout(() => startLeave(id), lifeMs);
      } else if (d.type === "HUD_CLEAR") {
        setRows([]);
      }
    };

    window.addEventListener("message", onMsg);
    return () => window.removeEventListener("message", onMsg);
  }, []);

  return (
    <div className="kf">
      {rows.map((e) => (
        <KillRow key={e.id} e={e} />
      ))}
    </div>
  );
};

export default Killfeed;
