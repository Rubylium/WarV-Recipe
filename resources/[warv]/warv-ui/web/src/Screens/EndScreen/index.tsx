import { useEffect, useState } from "react";
import { useSelector } from "../..";
import { IMG, hideImg } from "../../images";
import RankBadge from "../../Components/RankBadge";
import { EndScreenRow, EndScreenSide } from "../../types";
import "./index.scss";

const resultLabel: Record<string, string> = {
  victory: "Victory",
  defeat: "Defeat",
  draw: "Draw",
};

const useCountUp = (target: number, ms: number, delay: number) => {
  const [val, setVal] = useState(0);
  useEffect(() => {
    let raf = 0;
    let start = 0;
    const to = window.setTimeout(() => {
      const tick = (t: number) => {
        if (!start) start = t;
        const p = Math.min(1, (t - start) / ms);
        const eased = 1 - Math.pow(1 - p, 3);
        setVal(Math.round(target * eased));
        if (p < 1) raf = requestAnimationFrame(tick);
      };
      raf = requestAnimationFrame(tick);
    }, delay);
    return () => {
      window.clearTimeout(to);
      cancelAnimationFrame(raf);
    };
  }, [target, ms, delay]);
  return val;
};

const BoardRow = ({ row }: { row: EndScreenRow }) => {
  const kills = useCountUp(row.score, 1400, 1000);
  return (
    <div className={`es__row${row.me ? " es__row--me" : ""}${row.pos === 1 ? " es__row--top" : ""}`}>
      <span className="es__row-pos">{row.pos}</span>
      <RankBadge icon={row.rankIcon} prestige={row.prestige} className="es__row-badge" />
      <span className="es__row-name">{row.name}</span>
      <span className="es__row-kills">
        {kills}
        <i>KILLS</i>
      </span>
    </div>
  );
};

const Head = ({ side, pos }: { side: EndScreenSide; pos: "left" | "right" }) => (
  <div className={`es__head es__head--${pos} es__head--${side.color}`}>
    {side.logo && (
      <img
        className="es__head-logo"
        src={IMG(`teams/${side.logo}.png`)}
        alt=""
        draggable={false}
        onError={hideImg}
      />
    )}
    <span className="es__head-name">{side.name}</span>
  </div>
);

const EndScreen = ({ closing }: { closing?: boolean }) => {
  const d = useSelector((s) => s.endScreen);

  const leftScore = useCountUp(d.left.score, 1800, 900);
  const rightScore = useCountUp(d.right.score, 1800, 900);

  const isDraw = d.result === "draw";
  const leftWins = !isDraw && d.left.score > d.right.score;
  const rightWins = !isDraw && d.right.score > d.left.score;
  const total = d.left.score + d.right.score;
  const leftPct = total > 0 ? (d.left.score / total) * 100 : 50;
  const label = resultLabel[d.result] || "Match Over";

  return (
    <div className={`es es--${d.result}${closing ? " es--closing" : ""}`}>
      <div className="es__bg" />
      <div className="es__whoosh">
        <span />
        <span />
        <span />
        <span />
      </div>
      <div className="es__scrim" />

      {d.left.logo && (
        <img
          className="es__side es__side--left"
          src={IMG(`teams/${d.left.logo}.png`)}
          alt=""
          draggable={false}
          onError={hideImg}
        />
      )}
      {d.right.logo && (
        <img
          className="es__side es__side--right"
          src={IMG(`teams/${d.right.logo}.png`)}
          alt=""
          draggable={false}
          onError={hideImg}
        />
      )}

      <div className="es__flash" />

      <div className="es__content">
        <svg className="es__ring" viewBox="0 0 100 100" aria-hidden>
          <circle cx="50" cy="50" r="30" />
        </svg>

        <div className="es__title">
          <span className="es__title-line es__title-line--l" />
          <span className="es__result">{label}</span>
          <span className="es__title-line es__title-line--r" />
        </div>
        {d.subtitle && <div className="es__subtitle">{d.subtitle}</div>}

        {d.teamMode === false ? (
          <div className="es__board">
            {d.board.map((row, i) => (
              <BoardRow key={i} row={row} />
            ))}
          </div>
        ) : (
          <div className="es__scores">
            <Head side={d.left} pos="left" />
            <Head side={d.right} pos="right" />

            <span className={`es__num es__num--left es__num--${d.left.color}${leftWins ? " es__num--win" : ""}`}>
              {leftScore}
            </span>
            <span className="es__vs">VS</span>
            <span className={`es__num es__num--right es__num--${d.right.color}${rightWins ? " es__num--win" : ""}`}>
              {rightScore}
            </span>

            {leftWins && <span className="es__wintag es__wintag--left">Winner</span>}
            {rightWins && <span className="es__wintag es__wintag--right">Winner</span>}

            <div className="es__momentum">
              <div
                className={`es__momentum-fill es__momentum-fill--${d.left.color}`}
                style={{ width: `${leftPct}%` }}
              />
              <div
                className={`es__momentum-fill es__momentum-fill--${d.right.color}`}
                style={{ width: `${100 - leftPct}%` }}
              />
              <div className="es__momentum-split" style={{ left: `${leftPct}%` }} />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default EndScreen;
