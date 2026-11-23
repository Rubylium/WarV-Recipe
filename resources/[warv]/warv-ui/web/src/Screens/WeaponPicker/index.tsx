import { useEffect, useState } from "react";
import { useSelector } from "../..";
import { PickerWeapon } from "../../types";
import { act, hover, uiSound } from "../../ui";
import WeaponArt, { LockIcon } from "../../Components/WeaponArt";
import "./index.scss";

const stats: { key: keyof PickerWeapon; label: string }[] = [
  { key: "damage", label: "Damage" },
  { key: "accuracy", label: "Accuracy" },
  { key: "range", label: "Range" },
  { key: "fireRate", label: "Fire Rate" },
];

const WeaponPicker = () => {
  const d = useSelector((s) => s.weaponPicker);
  const [cat, setCat] = useState(0);
  const [sel, setSel] = useState(0);

  useEffect(() => {
    for (let ci = 0; ci < d.categories.length; ci++) {
      const wi = d.categories[ci].weapons.findIndex((w) => w.equipped);
      if (wi >= 0) {
        setCat(ci);
        setSel(wi);
        return;
      }
    }
    setCat(0);
    setSel(0);
  }, [d.slot, d.categories]);

  const category = d.categories[cat];
  const weapons = category?.weapons ?? [];
  const current = weapons[sel] || weapons[0];

  const chooseCat = (i: number) => {
    setCat(i);
    setSel(0);
  };

  return (
    <div className="wp">
      {d.categories.length > 1 && (
        <div className="wp__cats">
          {d.categories.map((c, i) => (
            <button
              key={c.label}
              className={`wp__cat${i === cat ? " wp__cat--active" : ""}`}
              onMouseEnter={hover}
              onClick={() => chooseCat(i)}
            >
              {c.label}
            </button>
          ))}
        </div>
      )}

      <div className="wp__body">
        <nav className="wp__list">
          {weapons.map((w, i) => (
            <button
              key={w.weapon}
              className={`wp__row${i === sel ? " wp__row--active" : ""}${w.locked ? " wp__row--locked" : ""}${
                w.equipped ? " wp__row--equipped" : ""
              }`}
              onMouseEnter={hover}
              onClick={() => setSel(i)}
              onDoubleClick={() => (w.locked ? uiSound("error") : act("weapon_pick", { weapon: w.weapon }))}
            >
              <span className="wp__row-art">
                <WeaponArt image={w.image} cls="wp__row-img" />
              </span>
              <span className="wp__row-main">
                <span className="wp__row-name">{w.label}</span>
                <span className="wp__row-meta">
                  {w.equipped ? (
                    <span className="wp__row-eq">Equipped</span>
                  ) : w.locked ? (
                    <span className="wp__row-locktxt">
                      <LockIcon />
                      Unlocks at level {w.level}
                    </span>
                  ) : (
                    <span className="wp__row-unlocked">Unlocked</span>
                  )}
                </span>
              </span>
              {w.locked ? (
                <span className="wp__row-lvl wp__row-lvl--locked">{String(w.level).padStart(2, "0")}</span>
              ) : (
                <span className={`wp__row-wlvl${w.weaponLevel >= d.maxWeaponLevel ? " wp__row-wlvl--max" : ""}`}>
                  <small>{w.weaponLevel >= d.maxWeaponLevel ? "" : "LVL"}</small>
                  {w.weaponLevel >= d.maxWeaponLevel ? "MAX" : w.weaponLevel}
                </span>
              )}
            </button>
          ))}
        </nav>

        {current && (
          <section className="wp__preview" key={current.weapon}>
            <div className="wp__preview-art">
              <WeaponArt image={current.image} cls="wp__big" />
            </div>
            <h2 className="wp__preview-name">
              {current.label}
              {!current.locked && (
                <span className={`wp__preview-lvl${current.weaponLevel >= d.maxWeaponLevel ? " wp__preview-lvl--max" : ""}`}>
                  {current.weaponLevel >= d.maxWeaponLevel ? "MAX" : `LVL ${current.weaponLevel}`}
                </span>
              )}
            </h2>

            <div className="wp__stats">
              {stats.map((s) => (
                <div key={s.key} className="wp__stat">
                  <span className="wp__stat-label">{s.label}</span>
                  <span className="wp__stat-bar">
                    <span className="wp__stat-fill" style={{ width: `${Math.max(0, Math.min(100, current[s.key] as number))}%` }} />
                  </span>
                </div>
              ))}
              <div className="wp__stat wp__stat--clip">
                <span className="wp__stat-label">Clip Size</span>
                <span className="wp__stat-num">{current.clip}</span>
              </div>
            </div>

            {current.locked ? (
              <div className="wp__locked-note">
                <LockIcon />
                Unlocks at level {current.level}
              </div>
            ) : (
              <button className="wp__equip" onMouseEnter={hover} onClick={() => act("weapon_pick", { weapon: current.weapon })}>
                Equip
              </button>
            )}
          </section>
        )}
      </div>
    </div>
  );
};

export default WeaponPicker;
