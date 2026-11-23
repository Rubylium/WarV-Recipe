import { useState } from "react";
import { useSelector } from "../..";
import { IMG, hideImg } from "../../images";
import { Playlist } from "../../types";
import { act, hover } from "../../ui";
import "./index.scss";

const PlayArrow = () => (
  <svg viewBox="0 0 24 24" fill="currentColor">
    <path d="M7 5v14l11-7z" />
  </svg>
);
const UsersIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="square">
    <circle cx="9" cy="8" r="3" />
    <path d="M3.5 19v-1.5C3.5 15 6 14 9 14s5.5 1 5.5 3.5V19" />
    <path d="M16 5.2A3 3 0 0 1 16 11M17 14c2.4.3 4 1.4 4 3.5V19" />
  </svg>
);
const RankIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="square" strokeLinejoin="miter">
    <path d="M5 11l7-6 7 6" />
    <path d="M5 17l7-6 7 6" />
  </svg>
);
const ShieldIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="square" strokeLinejoin="miter">
    <path d="M12 3l7 3v5c0 4.4-3 7.6-7 9-4-1.4-7-4.6-7-9V6z" />
    <path d="M9 12l2 2 4-4" />
  </svg>
);

const GamemodeSelect = () => {
  const list = useSelector((s) => s.gamemodeSelect.playlists);
  const [pick, setPick] = useState(0);
  const sel = pick < list.length ? pick : 0;
  const current: Playlist | undefined = list[sel];

  return (
    <div className="gm">
      <div className="gm__body">
        <nav className="gm__list">
          {list.map((p, i) => (
            <button
              key={p.name}
              className={`gm__row${i === sel ? " gm__row--active" : ""}`}
              onMouseEnter={hover}
              onClick={() => setPick(i)}
              onDoubleClick={() => act("join_gamemode", { name: p.name })}
            >
              <span className="gm__row-ico">
                <img src={IMG(`gamemode/icons/${p.sprite}.png`)} alt="" draggable={false} onError={hideImg} />
              </span>
              <span className="gm__row-main">
                <span className="gm__row-label">{p.label}</span>
                <span className="gm__row-players">
                  <span className="gm__dot" />
                  {p.players} {p.players === 1 ? "Player" : "Players"}
                </span>
              </span>
              {p.ranked && <span className="gm__row-ranked">Ranked</span>}
            </button>
          ))}
        </nav>

        {current && (
          <section className={`gm__preview${current.ranked ? " gm__preview--ranked" : ""}`} key={current.name}>
            <div className="gm__art">
              <div className="gm__art-glow" />
              <img className="gm__art-img" src={IMG(`gamemode/icons/${current.sprite}.png`)} alt="" draggable={false} onError={hideImg} />
            </div>

            <div className="gm__info">
              {current.ranked ? (
                <span className="gm__tag gm__tag--ranked">
                  <RankIcon />
                  Ranked Playlist
                </span>
              ) : (
                <span className="gm__tag">Casual Playlist</span>
              )}
              <h2 className="gm__name">{current.label}</h2>

              <div className="gm__meta">
                <span className="gm__meta-item">
                  <span className="gm__dot" />
                  {current.players} {current.players === 1 ? "Player online" : "Players online"}
                </span>
                {current.maxPlayers > 0 && (
                  <span className="gm__meta-item">
                    <UsersIcon />
                    {current.maxPlayers}-Player lobby
                  </span>
                )}
              </div>

              <p className="gm__desc">
                {current.description.split("\n").map((line, i) => (
                  <span key={i}>{line}</span>
                ))}
              </p>

              {current.ranked && (
                <div className="gm__feats">
                  <span className="gm__feat">
                    <RankIcon />
                    Skill-based matchmaking
                  </span>
                  <span className="gm__feat">
                    <ShieldIcon />
                    Competitive ranks &amp; rewards
                  </span>
                </div>
              )}

              <button className="gm__play" onMouseEnter={hover} onClick={() => act("join_gamemode", { name: current.name })}>
                <PlayArrow />
                <span>{current.ranked ? "Find Ranked Match" : "Find Match"}</span>
              </button>
            </div>
          </section>
        )}
      </div>
    </div>
  );
};

export default GamemodeSelect;
