import { useEffect, useState } from "react";
import { useSelector } from "../..";
import { IMG } from "../../images";
import { nf } from "../../ui";
import { ChallengeEntry } from "../../types";
import "./index.scss";

const perPage = 3;
const rotateMs = 8200;

const countdown = (seconds: number) => {
  if (seconds <= 0) return "";
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (d > 0) return `${d}D ${h}H`;
  if (h > 0) return `${h}H ${m}M`;
  return `${m}M`;
};

const WeekMeter = ({ left }: { left: number }) => {
  const days = Math.max(1, Math.min(7, Math.ceil(left / 86400)));
  return (
    <span className="ch__meter">
      {Array.from({ length: 7 }).map((_, i) => (
        <span key={i} className={`ch__seg${i < days ? " ch__seg--on" : ""}`} />
      ))}
    </span>
  );
};

const Card = ({ c, index }: { c: ChallengeEntry; index: number }) => {
  const [iconOk, setIconOk] = useState(true);
  const [fill, setFill] = useState(0);
  const pct = Math.max(0, Math.min(100, (c.progress / (c.target || 1)) * 100));

  useEffect(() => {
    const t = setTimeout(() => setFill(pct), 120 + index * 90);
    return () => clearTimeout(t);
  }, [pct, index]);

  return (
    <div className={`ch__card${c.completed ? " ch__card--done" : ""}`} style={{ animationDelay: `${index * 80}ms` }}>
      <span className="ch__tint" style={{ width: `${fill}%` }} />

      <span className="ch__icon">
        {c.icon && iconOk && (
          <img src={IMG(c.icon)} alt="" draggable={false} onError={() => setIconOk(false)} />
        )}
      </span>

      <span className="ch__body">
        <span className="ch__top">
          <span className="ch__name">{c.label}</span>
          <span className="ch__count">
            {c.completed ? "DONE" : nf(c.progress)}
            {!c.completed && <b>/{nf(c.target)}</b>}
          </span>
        </span>
        <span className="ch__desc">{c.desc}</span>
        <span className="ch__reward">{c.completed ? "Claimed" : `+${nf(c.credit)} CR`}</span>
      </span>

      <span className="ch__edge" style={{ width: `${fill}%` }} />
    </div>
  );
};

const Challenges = () => {
  const data = useSelector((s) => s.challenges);
  const [page, setPage] = useState(0);
  const [left, setLeft] = useState(0);

  const items = data.items;
  const pages = Math.max(1, Math.ceil(items.length / perPage));

  useEffect(() => {
    setPage(0);
    if (pages <= 1) return;
    const t = setInterval(() => setPage((p) => (p + 1) % pages), rotateMs);
    return () => clearInterval(t);
  }, [pages]);

  useEffect(() => {
    setLeft(data.resetsIn > 0 ? data.resetsIn : 0);
  }, [data.resetsIn]);

  useEffect(() => {
    const t = setInterval(() => setLeft((s) => (s > 1 ? s - 1 : 0)), 1000);
    return () => clearInterval(t);
  }, []);

  if (items.length === 0) return null;

  const slice = items.slice(page * perPage, page * perPage + perPage);
  const done = items.filter((c) => c.completed).length;
  const resets = countdown(left);

  return (
    <section className="ch">
      <div className="ch__head">
        <span className="ch__title">Weekly Challenges</span>
        <span className="ch__line" />
        <span className="ch__meta">
          {done}/{items.length} complete
        </span>
        {left > 0 && (
          <span className="ch__timer">
            <WeekMeter left={left} />
            <b>{resets}</b>
          </span>
        )}
        {pages > 1 && (
          <span className="ch__dots">
            {Array.from({ length: pages }).map((_, i) => (
              <span key={i} className={`ch__dot${i === page ? " ch__dot--on" : ""}`} />
            ))}
          </span>
        )}
      </div>

      <div className="ch__row" key={page}>
        {slice.map((c, i) => (
          <Card key={c.id} c={c} index={i} />
        ))}
      </div>
    </section>
  );
};

export default Challenges;
