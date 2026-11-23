import { useEffect, useState } from "react";
import { useSelector } from "../..";
import { act, actSilent, hover, uiSound } from "../../ui";
import { ChoiceSetting } from "../../types";
import "./index.scss";

const cats = [
  { id: "audio", label: "Audio" },
  { id: "rankup", label: "Rank-Up Sound" },
  { id: "music", label: "Lobby Music" },
];

const PlayIcon = () => (
  <svg viewBox="0 0 24 24" fill="currentColor">
    <path d="M8 5v14l11-7z" />
  </svg>
);

const ChoiceRow = ({ c, action, playing }: { c: ChoiceSetting; action: string; playing: string }) => (
  <button
    className={`st__row${c.selected ? " st__row--active" : ""}`}
    onMouseEnter={hover}
    onClick={() => act(action, { id: c.id })}
  >
    <span className="st__row-main">
      <span className="st__row-label">{c.label}</span>
      {c.desc && <span className="st__row-desc">{c.desc}</span>}
    </span>
    {c.selected && <span className="st__row-tag">{playing}</span>}
    <span className="st__row-play">
      <PlayIcon />
    </span>
  </button>
);

const Settings = () => {
  const data = useSelector((s) => s.settings);
  const [cat, setCat] = useState("audio");
  const [vols, setVols] = useState<Record<string, number>>({});

  useEffect(() => {
    setVols(Object.fromEntries(data.volumes.map((v) => [v.key, v.percent])));
  }, [data.volumes]);

  const onVol = (key: string, percent: number) => {
    setVols((p) => {
      if (p[key] !== percent) uiSound("adjust");
      return { ...p, [key]: percent };
    });
    actSilent("set_volume", { key, percent });
  };

  return (
    <div className="st">
      <nav className="st__nav">
        {cats.map((c) => (
          <button
            key={c.id}
            className={`st__cat${c.id === cat ? " st__cat--active" : ""}`}
            onMouseEnter={hover}
            onClick={() => {
              uiSound("tab");
              setCat(c.id);
            }}
          >
            {c.label}
          </button>
        ))}
      </nav>

      <section className="st__panel">
        {cat === "audio" && (
          <div className="st__sliders">
            {data.volumes.map((v) => {
              const pct = vols[v.key] ?? v.percent;
              return (
                <div key={v.key} className="st__slider">
                  <span className="st__slider-label">{v.label}</span>
                  <input
                    className="st__range"
                    type="range"
                    min={0}
                    max={100}
                    value={pct}
                    onChange={(e) => onVol(v.key, parseInt(e.target.value, 10))}
                    style={{
                      background: `linear-gradient(to right, var(--warv-orange) ${pct}%, rgba(255,255,255,0.14) ${pct}%)`,
                    }}
                  />
                  <span className="st__slider-val">
                    {pct}
                    <b>%</b>
                  </span>
                </div>
              );
            })}
          </div>
        )}

        {cat === "rankup" && (
          <div className="st__list">
            {data.rankup.map((c) => (
              <ChoiceRow key={c.id} c={c} action="set_rankup" playing="Selected" />
            ))}
          </div>
        )}

        {cat === "music" && (
          <div className="st__list">
            {data.music.map((c) => (
              <ChoiceRow key={c.id} c={c} action="set_music" playing="Playing" />
            ))}
          </div>
        )}
      </section>
    </div>
  );
};

export default Settings;
