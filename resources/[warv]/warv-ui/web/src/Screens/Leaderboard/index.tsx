import { useSelector } from "../..";
import CallingCard from "../../Components/CallingCard";
import Emblem from "../../Components/Emblem";
import RankBadge from "../../Components/RankBadge";
import { act, hover, nf } from "../../ui";
import { LeaderboardRow } from "../../types";
import CategoryIcon from "./icons";
import "./index.scss";

const format = (value: number, decimals: number) =>
  decimals > 0 ? value.toFixed(decimals) : nf(value);

const Podium = ({ rows, label, decimals }: { rows: LeaderboardRow[]; label: string; decimals: number }) => (
  <div className="lb__podium">
    {rows.map((r) => (
      <div key={r.uid} className={`lb__pod lb__pod--${r.rank}`}>
        <div className="lb__pod-art">
          <CallingCard sprite={r.callingCard} className="lb__pod-cc" />
          <div className="lb__pod-scrim" />
          <span className="lb__pod-place">{r.rank}</span>
          <Emblem sprite={r.emblem} className="lb__pod-emblem" />
        </div>
        <div className="lb__pod-body">
          <RankBadge icon={r.rankIcon} prestige={r.prestige} className="lb__pod-rank" />
          <span className="lb__pod-meta">
            <span className="lb__pod-name">{r.name}</span>
            <span className="lb__pod-lvl">
              {r.prestige > 0 ? `P${r.prestige} · ` : ""}LVL {r.level}
            </span>
          </span>
        </div>
        <div className="lb__pod-value">
          <b>{format(r.value, decimals)}</b>
          <span>{label}</span>
        </div>
      </div>
    ))}
  </div>
);

const Row = ({ row, decimals, self }: { row: LeaderboardRow; decimals: number; self: boolean }) => (
  <div className={`lb__row${self ? " lb__row--self" : ""}`}>
    <span className="lb__rank">{row.rank}</span>
    <Emblem sprite={row.emblem} className="lb__row-emblem" />
    <RankBadge icon={row.rankIcon} prestige={row.prestige} className="lb__row-rank" />
    <span className="lb__name">
      {row.name}
      <b>#{row.uid}</b>
    </span>
    <span className="lb__lvl">
      {row.prestige > 0 && <b>P{row.prestige}</b>}
      LVL {row.level}
    </span>
    <span className="lb__value">{format(row.value, decimals)}</span>
  </div>
);

const Leaderboard = () => {
  const data = useSelector((s) => s.leaderboard);

  const rows = data.items;
  const active = data.categories.find((c) => c.id === data.category);
  const decimals = active?.decimals ?? 0;
  const label = active?.label || "";
  const podium = rows.slice(0, 3);
  const rest = rows.slice(3);
  const inList = data.self && rows.some((r) => r.uid === data.self.uid);

  return (
    <div className="lb">
      <nav className="lb__rail">
        {data.categories.map((c) => (
          <button
            key={c.id}
            className={`lb__cat${c.id === data.category ? " lb__cat--active" : ""}`}
            onMouseEnter={hover}
            onClick={() => c.id !== data.category && act("leaderboard_category", { id: c.id }, "tab")}
          >
            <span className="lb__cat-ico">
              <CategoryIcon category={c.id} />
            </span>
            {c.label}
          </button>
        ))}
      </nav>

      <section className="lb__board">
        {rows.length === 0 ? (
          <div className="lb__empty">No records yet</div>
        ) : (
          <>
            <Podium rows={podium} label={label} decimals={decimals} />

            <div className="lb__head">
              <span className="lb__rank">#</span>
              <span className="lb__name">Operator</span>
              <span className="lb__lvl">Rank</span>
              <span className="lb__value">{label}</span>
            </div>

            <div className="lb__list">
              {rest.map((r) => (
                <Row key={r.uid} row={r} decimals={decimals} self={r.uid === data.self?.uid} />
              ))}
            </div>
          </>
        )}

        {data.self && !inList && (
          <div className="lb__pinned">
            <Row row={data.self} decimals={decimals} self />
          </div>
        )}
      </section>
    </div>
  );
};

export default Leaderboard;
