import { useEffect, useRef, useState } from "react";
import RankBadge from "../RankBadge";
import { hideImg, IMG } from "../../images";
import { uiSound } from "../../ui";
import KillstreakCard from "./KillstreakCard";
import MedalCard from "./MedalCard";
import NoticeCard from "./NoticeCard";
import "./index.scss";

interface Notif {
  id: number;
  kind: string;
  data: Record<string, unknown>;
}

const medalFastShow = 520;
const weaponMasterShow = 4000;

const timing: Record<string, { show: number; leave: number }> = {
  weapon_level: { show: 2600, leave: 380 },
  rank_up: { show: 3600, leave: 460 },
  killstreak: { show: 2800, leave: 420 },
  medal: { show: 1350, leave: 260 },
  notice: { show: 3200, leave: 320 },
};
const cfg = (kind: string) => timing[kind] || timing.medal;

const sounds: Record<string, string> = {
  weapon_level: "notify_weapon_level",
  rank_up: "notify_rank_up",
  medal: "notify_medal",
  notice: "deny",
};

const soundFor = (item: Notif) => {
  if (item.kind === "killstreak") {
    const tier = Math.max(1, Math.min(3, Number(item.data.tier) || 1));
    return `notify_killstreak_${tier}`;
  }
  return sounds[item.kind];
};

const medalKey = (data: Record<string, unknown>) =>
  `${String(data.image || "")}:${String(data.label || "")}`;

const medalCount = (data: Record<string, unknown>) =>
  Math.max(1, Number(data.count) || 1);

const rays = [-70, -45, -20, 20, 45, 70];
const masterRays = [-75, -62, -49, -36, -23, -10, 10, 23, 36, 49, 62, 75];

const WeaponLevelCard = ({ d, leaving }: { d: Record<string, unknown>; leaving: boolean }) => {
  const max = !!d.max;
  const level = Number(d.level || 1);
  const weapon = String(d.weapon || "");
  const image = String(d.image || "");
  const head = max ? "Weapon Mastered" : "Weapon Level Up";
  return (
    <div className={`ntf-lvl${max ? " ntf-lvl--max" : ""}${leaving ? " ntf-lvl--leaving" : ""}`}>
      <div className="ntf-lvl__stage">
        <span className="ntf-lvl__ground" />
        <span className="ntf-lvl__glow" />
        {image && (
          <img className="ntf-lvl__emblem" src={IMG(`weapons/${image}.png`)} alt="" draggable={false} onError={hideImg} />
        )}
        <span className="ntf-lvl__rays">
          {(max ? masterRays : rays).map((deg, i) => (
            <i
              key={deg}
              className="ntf-lvl__ray"
              style={{ "--deg": `${deg}deg`, animationDelay: `${0.72 + i * 0.03}s` } as React.CSSProperties}
            />
          ))}
        </span>
        <span className="ntf-lvl__shock" />
        <span className="ntf-lvl__rule ntf-lvl__rule--l" />
        <span className="ntf-lvl__rule ntf-lvl__rule--r" />
        <span className="ntf-lvl__chev" />
        <span className="ntf-lvl__head">
          {head}
          <span className="ntf-lvl__shine">{head}</span>
        </span>
        <span className="ntf-lvl__weapon">{weapon}</span>
        <span className="ntf-lvl__level">{max ? "MAX" : level}</span>
        <span className="ntf-lvl__flash" />
      </div>
    </div>
  );
};

const RankUpCard = ({ d, leaving }: { d: Record<string, unknown>; leaving: boolean }) => {
  const level = Number(d.level || 1);
  const prestige = Number(d.prestige || 0);
  const isPrestige = prestige > 0 && level <= 1;
  return (
    <div className={`ntf-rankup${leaving ? " ntf-rankup--leaving" : ""}`}>
      <span className="ntf-rankup__streak" />
      <span className="ntf-rankup__ring" />
      <span className="ntf-rankup__ring ntf-rankup__ring--2" />
      <span className="ntf-rankup__glow" />
      <RankBadge icon={`rank_${Math.min(level, 55)}`} prestige={prestige} className="ntf-rankup__icon" />
      <span className="ntf-rankup__eyebrow">{isPrestige ? "Prestige" : "Rank Up"}</span>
      <span className="ntf-rankup__title">
        {isPrestige ? "Prestige" : "Level"} <b>{isPrestige ? prestige : level}</b>
      </span>
    </div>
  );
};

const cards: Record<string, (p: { d: Record<string, unknown>; leaving: boolean }) => JSX.Element> = {
  weapon_level: WeaponLevelCard,
  rank_up: RankUpCard,
  killstreak: KillstreakCard,
  medal: MedalCard,
  notice: NoticeCard,
};

const Notifications = () => {
  const [item, setItem] = useState<Notif | null>(null);
  const [leaving, setLeaving] = useState(false);
  const queue = useRef<Notif[]>([]);
  const idRef = useRef(0);
  const itemRef = useRef<Notif | null>(null);
  const showingRef = useRef(false);
  const leavingRef = useRef(false);
  const curKind = useRef("");
  const shownAtRef = useRef(0);
  const timers = useRef<number[]>([]);

  useEffect(() => {
    const clearT = () => {
      timers.current.forEach((t) => window.clearTimeout(t));
      timers.current = [];
    };

    const hasQueuedMedal = () => queue.current.some((queued) => queued.kind === "medal");

    function scheduleLeave(delay: number) {
      clearT();
      timers.current.push(window.setTimeout(startLeave, Math.max(0, delay)));
    }

    function showNext() {
      clearT();
      const next = queue.current.shift();
      if (!next) {
        itemRef.current = null;
        showingRef.current = false;
        leavingRef.current = false;
        setItem(null);
        return;
      }
      showingRef.current = true;
      leavingRef.current = false;
      curKind.current = next.kind;
      shownAtRef.current = Date.now();
      setLeaving(false);
      itemRef.current = next;
      setItem(next);
      const sound = soundFor(next);
      if (sound) uiSound(sound);
      const hold = next.kind === "weapon_level" && next.data.max ? weaponMasterShow : cfg(next.kind).show;
      const showTime = next.kind === "medal" && hasQueuedMedal() ? medalFastShow : hold;
      scheduleLeave(showTime);
    }

    function startLeave() {
      if (leavingRef.current) return;
      leavingRef.current = true;
      clearT();
      setLeaving(true);
      timers.current.push(window.setTimeout(showNext, cfg(curKind.current).leave));
    }

    const onMsg = (ev: MessageEvent) => {
      const dm = ev.data;
      if (!dm) return;

      if (dm.type === "HUD_NOTIFY_CLEAR") {
        const clearKind = String(dm.payload?.kind || "");
        queue.current = queue.current.filter((queued) => queued.kind !== clearKind);
        if (curKind.current === clearKind && !leavingRef.current) {
          startLeave();
        }
        return;
      }

      if (dm.type !== "HUD_NOTIFY") return;
      const p = { ...(dm.payload || {}) } as Record<string, unknown>;
      const kind = String(p.kind || "");
      if (!cards[kind]) return;

      if (kind === "medal") {
        p.count = medalCount(p);
        const key = medalKey(p);
        const current = itemRef.current;

        if (
          current?.kind === "medal" &&
          !leavingRef.current &&
          medalKey(current.data) === key
        ) {
          const updated = {
            ...current,
            data: {
              ...current.data,
              count: medalCount(current.data) + medalCount(p),
            },
          };
          itemRef.current = updated;
          setItem(updated);
          shownAtRef.current = Date.now();
          scheduleLeave(hasQueuedMedal() ? medalFastShow : cfg(kind).show);
          return;
        }

        const queued = queue.current.find(
          (candidate) => candidate.kind === "medal" && medalKey(candidate.data) === key
        );
        if (queued) {
          queued.data = {
            ...queued.data,
            count: medalCount(queued.data) + medalCount(p),
          };
          return;
        }
      }

      queue.current.push({ id: ++idRef.current, kind, data: p });
      if (!showingRef.current) {
        showNext();
      } else if (kind === "medal" && curKind.current === "medal" && !leavingRef.current) {
        const elapsed = Date.now() - shownAtRef.current;
        scheduleLeave(medalFastShow - elapsed);
      }
    };

    window.addEventListener("message", onMsg);
    return () => {
      window.removeEventListener("message", onMsg);
      clearT();
    };
  }, []);

  if (!item) return null;
  const Renderer = cards[item.kind];
  return <Renderer key={item.id} d={item.data} leaving={leaving} />;
};

export default Notifications;
