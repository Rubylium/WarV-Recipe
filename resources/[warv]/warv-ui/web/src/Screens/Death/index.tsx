import { useEffect, useState } from "react";
import { useSelector } from "../..";
import RankBadge from "../../Components/RankBadge";
import { IMG, hideImg } from "../../images";
import { act, hover } from "../../ui";
import "./index.scss";

const DeathScreen = ({ closing = false }: { closing?: boolean }) => {
  const d = useSelector((s) => s.death);
  const [remain, setRemain] = useState(d.respawnMs);
  const [glitch, setGlitch] = useState(false);

  useEffect(() => {
    const deadline = performance.now() + d.respawnMs;
    setRemain(d.respawnMs);
    const id = window.setInterval(() => setRemain(Math.max(0, deadline - performance.now())), 60);
    return () => window.clearInterval(id);
  }, [d.respawnMs, d.killer]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.code === "Space") {
        e.preventDefault();
        act("death_respawn", {}, false);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  useEffect(() => {
    if (d.specSeq === 0) return;
    setGlitch(true);
    const t = window.setTimeout(() => setGlitch(false), 240);
    return () => window.clearTimeout(t);
  }, [d.specSeq]);

  const secs = Math.ceil(remain / 1000);
  const pct = d.respawnMs > 0 ? Math.min(100, (1 - remain / d.respawnMs) * 100) : 100;
  const respawning = secs <= 0;

  return (
    <div className={`dth${closing ? " dth--closing" : ""}`}>
      <div className="dth__fade dth__fade--top" />
      <div className="dth__fade dth__fade--bottom" />

      {glitch && (
        <div className="dth__glitch">
          <span className="dth__glitch-scan" />
          <span className="dth__glitch-flash" />
        </div>
      )}

      {!d.spectating && (
        <span
          key={respawning ? "respawning" : "eliminated"}
          className={`dth__state${respawning ? " dth__state--respawning" : ""}`}
        >
          {respawning ? "Respawning" : "Eliminated"}
        </span>
      )}

      {d.spectating && (
        <div key={d.specSeq} className="dth__spec">
          <span className="dth__spec-accent" />
          <span className="dth__spec-label">Spectating</span>
          <span className="dth__spec-name">{d.spectating}</span>
          <span className="dth__spec-arrow dth__spec-arrow--l">&larr;</span>
          <span className="dth__spec-arrow dth__spec-arrow--r">&rarr;</span>
        </div>
      )}

      {d.damage.length > 0 && (
        <div className="dth__dmg">
          <div className="dth__dmg-head">
            <span className="dth__dmg-count">Attackers · {d.damage.length}</span>
            <span className="dth__dmg-col">Damage</span>
            <span className="dth__dmg-col">Hits</span>
          </div>
          <div className="dth__dmg-rule" />
          {d.damage.map((r, i) => (
            <div
              key={`${r.name}-${i}`}
              className={`dth__dmg-row${r.final ? " dth__dmg-row--final" : ""}`}
              style={{ animationDelay: `${0.16 + i * 0.06}s` }}
            >
              <span className="dth__dmg-name">{r.name}</span>
              <span className="dth__dmg-icons">
                {r.weaponImage && (
                  <img
                    className="dth__dmg-wpn"
                    src={IMG(`weapons/${r.weaponImage}.png`)}
                    alt=""
                    draggable={false}
                    onError={hideImg}
                  />
                )}
                {r.headshot && <img className="dth__dmg-hs" src={IMG("hud/headshot.png")} alt="" draggable={false} />}
              </span>
              <span className="dth__dmg-val">{r.damage}</span>
              <span className="dth__dmg-hits">{r.hits}</span>
            </div>
          ))}
        </div>
      )}

      <div className="dth__recap">
        <span className="dth__recap-accent" />
        <span className="dth__eyebrow">Killed by</span>

        <div className="dth__id">
          {(d.rankIcon || d.prestige > 0) && (
            <RankBadge icon={d.rankIcon} prestige={d.prestige} className="dth__rank" />
          )}
          <span className="dth__killer">{d.killer || "Enemy"}</span>
        </div>

        {d.weaponName && <span className="dth__weapon-name">{d.weaponName}</span>}

        {(d.headshot || d.distance > 0) && (
          <div className="dth__tags">
            {d.headshot && (
              <span className="dth__tag">
                <img className="dth__tag-icon" src={IMG("hud/headshot.png")} alt="" draggable={false} />
                Headshot
              </span>
            )}
            {d.distance > 0 && <span className="dth__tag dth__tag--dim">{d.distance} m</span>}
          </div>
        )}

        {d.weaponImage && (
          <img
            className="dth__weapon"
            src={IMG(`weapons/${d.weaponImage}.png`)}
            alt=""
            draggable={false}
            onError={hideImg}
          />
        )}
      </div>

      <div className="dth__respawn">
        <div key={respawning ? "head-r" : "head-e"} className="dth__respawn-head">
          <span className="dth__respawn-label">{respawning ? "Respawning" : "Respawn in"}</span>
          {!respawning && <span className="dth__respawn-secs">{secs}</span>}
        </div>

        <span className="dth__respawn-track">
          <span className="dth__respawn-fill" style={{ width: `${pct}%` }} />
        </span>

        <div key={respawning ? "act-r" : "act-e"} className="dth__actions">
          {!respawning && (
            <span className="dth__action">
              <b className="dth__key">Space</b>
              <span className="dth__action-label">Deploy</span>
            </span>
          )}
          {!respawning && d.canChangeClass && <span className="dth__actions-sep" />}
          {d.canChangeClass && (
            <button className="dth__action dth__action--btn" onMouseEnter={hover} onClick={() => act("death_change_class")}>
              <span className="dth__action-label">Change class</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default DeathScreen;
