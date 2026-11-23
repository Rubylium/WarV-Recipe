import { useEffect, useState } from "react";
import { useSelector } from "../..";
import { IMG } from "../../images";
import { ClassEntry, ClassWeaponSlot, KillstreakSlot } from "../../types";
import { act, hover } from "../../ui";
import WeaponArt, { LockIcon } from "../../Components/WeaponArt";
import "./index.scss";

const EditIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="square">
    <path d="M4 20v-4L15 5l4 4L8 20z" />
    <line x1="13.5" y1="6.5" x2="17.5" y2="10.5" />
  </svg>
);
const SwapIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="square">
    <path d="M4 8h13l-3-3" />
    <path d="M20 16H7l3 3" />
  </svg>
);
const slots: { key: "primary" | "secondary" | "extra"; label: string; customize: boolean }[] = [
  { key: "primary", label: "Primary", customize: true },
  { key: "secondary", label: "Secondary", customize: true },
  { key: "extra", label: "Lethal", customize: false },
];

const WeaponSlot = ({ slot, data }: { slot: (typeof slots)[number]; data: ClassWeaponSlot }) => (
  <div className={`ce__slot${data.empty ? " ce__slot--empty" : ""}`}>
    <button className="ce__slot-art-btn" onMouseEnter={hover} onClick={() => act("class_change_weapon", { slot: slot.key })}>
      <WeaponArt key={data.image} image={data.image} cls="ce__art" />
    </button>
    <div className="ce__slot-info">
      <span className="ce__slot-label">
        {slot.label}
        {!data.empty && data.level > 0 && (
          <span className={`ce__slot-lvl${data.level >= data.maxLevel ? " ce__slot-lvl--max" : ""}`}>
            {data.level >= data.maxLevel ? "MAX" : `Lv ${data.level}`}
          </span>
        )}
      </span>
      <span className="ce__slot-name">{data.empty ? "None" : data.label}</span>
      {!data.empty && data.attachTotal > 0 && (
        <span className="ce__dots" title={`${data.attachOn} / ${data.attachTotal} attachments`}>
          {Array.from({ length: data.attachTotal }).map((_, i) => (
            <span key={i} className={`ce__dot${i < data.attachOn ? " ce__dot--on" : ""}`} />
          ))}
        </span>
      )}
    </div>
    <div className="ce__slot-actions">
      {slot.customize && !data.empty && (
        <button className="ce__slot-btn" onMouseEnter={hover} onClick={() => act("class_customize", { slot: slot.key })}>
          <EditIcon />
        </button>
      )}
      <button
        className="ce__slot-btn ce__slot-btn--text"
        onMouseEnter={hover}
        onClick={() => act("class_change_weapon", { slot: slot.key })}
      >
        <SwapIcon />
        <span>Change</span>
      </button>
    </div>
  </div>
);

const ScorestreakPanel = ({ streaks }: { streaks: KillstreakSlot[] }) => (
  <aside className="ce__scorestreaks">
    <div className="ce__scorestreak-head">
      <span className="ce__scorestreak-icon">
        <img src={IMG("icons/streaks_icon.png")} alt="" draggable={false} />
      </span>
      <span>
        <small>Combat Support</small>
        <strong>Scorestreaks</strong>
      </span>
    </div>

    <div className="ce__scorestreak-list">
      {streaks.map((streak) => (
        <div className="ce__scorestreak-row" key={`${streak.index}-${streak.type}`}>
          <span className="ce__scorestreak-slot">{String(streak.index).padStart(2, "0")}</span>
          <img
            className="ce__scorestreak-art"
            src={IMG(`hud/killstreaks/${streak.icon}.png`)}
            alt=""
            draggable={false}
            onError={(e) => (e.currentTarget.style.visibility = "hidden")}
          />
          <span className="ce__scorestreak-info">
            <strong>{streak.label}</strong>
            <small>{streak.kill} points</small>
          </span>
        </div>
      ))}
    </div>

    <button className="ce__scorestreak-open" onMouseEnter={hover} onClick={() => act("class_scorestreaks")}>
      <span>Edit scorestreaks</span>
      <span aria-hidden="true">›</span>
    </button>
  </aside>
);

const ClassEditor = () => {
  const d = useSelector((s) => s.classSelect);
  const [sel, setSel] = useState(d.selected || 1);
  const [renaming, setRenaming] = useState(false);
  const [nameInput, setNameInput] = useState("");

  useEffect(() => {
    setSel(d.selected || 1);
  }, [d.selected]);

  const current: ClassEntry | undefined = d.classes.find((c) => c.index === sel) || d.classes[0];

  const pick = (i: number) => {
    setSel(i);
    setRenaming(false);
    act("select_class", { index: i });
  };

  const startRename = () => {
    if (!current) return;
    setNameInput(current.name);
    setRenaming(true);
  };
  const submitRename = () => {
    setRenaming(false);
    const name = nameInput.trim();
    if (current && name && name !== current.name) {
      act("rename_class", { index: current.index, name });
    }
  };

  return (
    <div className="ce">
      <nav className="ce__list">
        <span className="ce__list-title">Classes</span>
        {d.classes.map((c) => (
          <button
            key={c.index}
            className={`ce__citem${c.index === sel ? " ce__citem--active" : ""}`}
            onMouseEnter={hover}
            onClick={() => pick(c.index)}
          >
            <span className="ce__citem-idx">{String(c.index).padStart(2, "0")}</span>
            <span className="ce__citem-name">{c.name}</span>
          </button>
        ))}

        {Array.from({ length: d.warvPlus ? 0 : d.lockedSlots }).map((_, i) => (
          <div key={`lock-${i}`} className="ce__citem ce__citem--locked">
            <span className="ce__citem-idx">{String(d.classes.length + i + 1).padStart(2, "0")}</span>
            <span className="ce__citem-name">Locked</span>
            <span className="ce__citem-plus">
              <LockIcon />
              WarV+
            </span>
          </div>
        ))}
      </nav>

      <section className="ce__loadout">
        {current ? (
          <>
            <div className="ce__loadout-head">
              <span className="ce__loadout-eyebrow">Editing Class</span>
              {renaming ? (
                <input
                  className="ce__rename"
                  value={nameInput}
                  autoFocus
                  maxLength={24}
                  spellCheck={false}
                  onChange={(e) => setNameInput(e.target.value)}
                  onBlur={submitRename}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") submitRename();
                    else if (e.key === "Escape") setRenaming(false);
                  }}
                />
              ) : (
                <h2 className="ce__loadout-name">
                  {current.name}
                  <button className="ce__rename-btn" onMouseEnter={hover} onClick={startRename} title="Rename class">
                    <EditIcon />
                  </button>
                </h2>
              )}
            </div>
            <div className="ce__slots">
              {slots.map((s) => (
                <WeaponSlot key={s.key} slot={s} data={current[s.key]} />
              ))}
            </div>
          </>
        ) : (
          <div className="ce__loading">Loading classes…</div>
        )}
      </section>

      <ScorestreakPanel streaks={d.scorestreaks} />
    </div>
  );
};

export default ClassEditor;
