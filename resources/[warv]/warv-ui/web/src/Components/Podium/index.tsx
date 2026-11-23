import { useEffect, useState } from "react";
import CallingCard from "../CallingCard";
import "./index.scss";

interface PodiumPlayer {
  place: number;
  name: string;
  score: number;
  kills: number;
  deaths: number;
  ratio: number | string;
  id?: number | string;
  level?: number;
  team?: number;
  me?: boolean;
  card?: string;
}

interface PodiumSlot {
  place: number;
  name: string;
  id?: number | string;
  team?: number;
  me?: boolean;
  score?: number;
}

const toNum = (v: unknown, fallback = 0) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
};

const teamClass = (team?: number) => (team === 1 ? "pd--t1" : team === 2 ? "pd--t2" : "");

const pad = (n: number) => String(n).padStart(2, "0");

const Podium = () => {
  const [visible, setVisible] = useState(false);
  const [summary, setSummary] = useState(false);
  const [player, setPlayer] = useState<PodiumPlayer | null>(null);
  const [roster, setRoster] = useState<Record<number, PodiumSlot>>({});
  const [total, setTotal] = useState(0);
  const [gen, setGen] = useState(0);

  useEffect(() => {
    const onMsg = (ev: MessageEvent) => {
      const d = ev.data;
      if (!d || d.type !== "SET_PODIUM") return;
      const p = d.payload || {};

      if (p.visible === false) {
        setVisible(false);
        setSummary(false);
        setPlayer(null);
        setRoster({});
        setTotal(0);
        return;
      }

      setVisible(true);
      if (toNum(p.total) > 0) setTotal(toNum(p.total));

      if (Array.isArray(p.players)) {
        const next: Record<number, PodiumSlot> = {};
        p.players.forEach((slot: PodiumSlot, i: number) => {
          const place = toNum(slot.place, i + 1);
          next[place] = {
            place,
            name: String(slot.name || ""),
            id: slot.id,
            team: toNum(slot.team) || undefined,
            me: slot.me === true,
          };
        });
        setRoster(next);
        setTotal((t) => Math.max(t, p.players.length));
      }

      if (p.player) {
        const place = toNum(p.player.place, 1);
        const entry: PodiumPlayer = {
          place,
          name: String(p.player.name || ""),
          score: toNum(p.player.score),
          kills: toNum(p.player.kills),
          deaths: toNum(p.player.deaths),
          ratio: p.player.ratio ?? 0,
          id: p.player.id,
          level: toNum(p.player.level) || undefined,
          team: toNum(p.player.team) || undefined,
          me: p.player.me === true,
          card: p.player.card ? String(p.player.card) : undefined,
        };
        setSummary(false);
        setPlayer(entry);
        setRoster((r) => ({
          ...r,
          [place]: {
            ...r[place],
            place,
            name: entry.name,
            id: entry.id,
            team: entry.team,
            me: entry.me,
            score: entry.score,
          },
        }));
        setTotal((t) => Math.max(t, place));
        setGen((g) => g + 1);
      }

      if (p.summary) setSummary(true);
    };

    window.addEventListener("message", onMsg);
    return () => window.removeEventListener("message", onMsg);
  }, []);

  if (!visible) return null;

  const revealed = player?.place ?? 0;
  const places = Array.from({ length: Math.max(total, revealed) }, (_, i) => i + 1);
  const finalPlaces = Object.keys(roster).map(Number).sort((a, b) => a - b);
  const lit = summary ? places.length : revealed;

  return (
    <div className={`pd ${summary ? "pd--summary" : ""}`}>
      <div className="pd__fade pd__fade--top" />
      <div className="pd__fade pd__fade--bottom" />
      <div className="pd__fade pd__fade--left" />
      <div className="pd__fade pd__fade--right" />

      <div className="pd__head">
        <span className="pd__eyebrow">Match complete</span>
        <h1 className="pd__title">Best players</h1>
        <span className="pd__sub">Top operators of the match</span>
      </div>

      {summary && (
        <div className="pd__final">
          <span className="pd__final-label">Final standings</span>
          <div className="pd__final-rule" />
          <div className="pd__final-row">
            {finalPlaces.map((place, i) => {
              const slot = roster[place];
              return (
                <div
                  key={place}
                  className={`pd__col ${slot.me ? "pd__col--me" : ""}`}
                  style={{ animationDelay: `${1 + i * 0.07}s` }}
                >
                  <span className={`pd__col-edge ${teamClass(slot.team)}`} />
                  <span className="pd__col-place">{pad(place)}</span>
                  <span className="pd__col-name">{slot.name}</span>
                  <span className="pd__col-score">{slot.score}</span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {places.length > 0 && (
        <div className={`pd__side ${summary ? "pd__side--out" : ""}`}>
          <span className="pd__rail-label">Top operators</span>
          <div className="pd__rail-rule" />

          <div className="pd__rail">
            {places.map((place) => {
              const slot = roster[place];
              const shown = place <= revealed;
              return (
                <div
                  key={place}
                  className={[
                    "pd__row",
                    shown ? "pd__row--revealed" : "",
                    place === revealed ? "pd__row--current" : "",
                  ]
                    .filter(Boolean)
                    .join(" ")}
                >
                  <span className={`pd__row-team ${teamClass(slot?.team)}`} />
                  <span className="pd__row-place">{pad(place)}</span>
                  <span className="pd__row-name">{slot?.name || "—"}</span>
                  <span className="pd__row-score">{shown ? slot?.score : "—"}</span>
                </div>
              );
            })}
          </div>

          {player && (
            <>
              <div className="pd__divider" />
              <div key={`stats-${gen}`} className="pd__stats">
                <div className="pd__stat pd__stat--lead">
                  <span className="pd__stat-k">Score</span>
                  <span className="pd__stat-v">{player.score}</span>
                </div>
                <div className="pd__stat">
                  <span className="pd__stat-k">Elims</span>
                  <span className="pd__stat-v">{player.kills}</span>
                </div>
                <div className="pd__stat">
                  <span className="pd__stat-k">Deaths</span>
                  <span className="pd__stat-v">{player.deaths}</span>
                </div>
                <div className="pd__stat">
                  <span className="pd__stat-k">K/D</span>
                  <span className="pd__stat-v">{player.ratio}</span>
                </div>
              </div>
            </>
          )}
        </div>
      )}

      {player && (
        <div key={gen} className={`pd__feature ${summary ? "pd__feature--out" : ""}`}>
          <span className="pd__place-k">Place</span>
          <span
            className={[
              "pd__place",
              player.place === 1 ? "pd__place--first" : "",
              player.place >= 4 ? "pd__place--tail" : "",
            ]
              .filter(Boolean)
              .join(" ")}
          >
            {pad(player.place)}
          </span>

          <div className="pd__plate">
            {player.card && (
              <span className="pd__card">
                <CallingCard sprite={player.card} className="pd__card-img" />
              </span>
            )}
            <span className={`pd__plate-edge ${teamClass(player.team)}`} />
            <span className="pd__name">{player.name}</span>
            <span className="pd__meta">
              {player.id != null && (
                <span className={player.me ? "pd__meta-you" : ""}>
                  #{player.id}
                  {player.me ? " / You" : ""}
                </span>
              )}
              {player.level != null && <span>Level {player.level}</span>}
            </span>
          </div>
        </div>
      )}

      {places.length > 1 && (
        <div className="pd__foot">
          <span className="pd__step">
            {summary ? "Complete" : `Reveal ${revealed || 1} of ${places.length}`}
          </span>
          <div className="pd__segs">
            {places.map((place) => (
              <span key={place} className={`pd__seg ${place <= lit ? "pd__seg--on" : ""}`} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default Podium;
