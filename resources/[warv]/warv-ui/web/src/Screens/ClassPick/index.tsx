import { useState } from "react";
import { useSelector } from "../..";
import { ClassPickEntry, ClassPickWeapon } from "../../types";
import { act, hover } from "../../ui";
import WeaponArt from "../../Components/WeaponArt";
import "./index.scss";

const slots: { key: "primary" | "secondary" | "extra"; label: string }[] = [
  { key: "primary", label: "Primary" },
  { key: "secondary", label: "Secondary" },
  { key: "extra", label: "Lethal" },
];

const LoadoutRow = ({ label, w, maxLevel }: { label: string; w: ClassPickWeapon; maxLevel: number }) => (
  <div className={`cp__slot${w.empty ? " cp__slot--empty" : ""}`}>
    <WeaponArt image={w.empty ? "" : w.image} cls="cp__wart" />
    <div className="cp__slot-info">
      <span className="cp__slot-label">{label}</span>
      <span className="cp__slot-name">{w.empty ? "None" : w.label}</span>
    </div>
    {!w.empty && w.level > 0 && (
      <span className={`cp__slot-lvl${w.level >= maxLevel ? " cp__slot-lvl--max" : ""}`}>
        {w.level >= maxLevel ? "MAX" : `Lv ${w.level}`}
      </span>
    )}
  </div>
);

const ClassPick = () => {
  const d = useSelector((s) => s.classPick);
  const [hov, setHov] = useState("");
  const sel = d.classes.some((c) => c.key === hov) ? hov : d.selected || d.classes[0]?.key;
  const current: ClassPickEntry | undefined = d.classes.find((c) => c.key === sel) || d.classes[0];

  const deploy = (key: string) => act("pick_spawn_class", { key });

  return (
    <div className="cp">
      <div className="cp__head">
        <span className="cp__eyebrow">Deploy</span>
        <h1 className="cp__title">Select Class</h1>
      </div>

      <div className="cp__body">
        <nav className="cp__list">
          {d.classes.map((c) => (
            <button
              key={c.key}
              className={`cp__item${c.key === sel ? " cp__item--active" : ""}${c.premade ? " cp__item--preset" : ""}`}
              onMouseEnter={() => {
                setHov(c.key);
                hover();
              }}
              onClick={() => deploy(c.key)}
            >
              <span className="cp__item-name">{c.name}</span>
              {c.premade ? (
                <span className="cp__item-tag">Preset</span>
              ) : (
                d.selected === c.key && <span className="cp__item-tag cp__item-tag--eq">Equipped</span>
              )}
            </button>
          ))}
        </nav>

        {current && (
          <section className="cp__loadout" key={current.key}>
            <div className="cp__loadout-head">
              <span className="cp__loadout-eyebrow">{current.premade ? "Preset Class" : "Custom Class"}</span>
              <h2 className="cp__loadout-name">{current.name}</h2>
            </div>
            <div className="cp__slots">
              {slots.map((s) => (
                <LoadoutRow key={s.key} label={s.label} w={current[s.key]} maxLevel={d.maxWeaponLevel} />
              ))}
            </div>
            <button className="cp__deploy" onMouseEnter={hover} onClick={() => deploy(current.key)}>
              Deploy
            </button>
          </section>
        )}
      </div>

      <span className="cp__hint">Select a class to deploy</span>
    </div>
  );
};

export default ClassPick;
