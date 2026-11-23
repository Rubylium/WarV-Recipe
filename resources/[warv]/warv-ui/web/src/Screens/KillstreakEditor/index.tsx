import { useState } from "react";
import { useSelector } from "../..";
import { IMG, hideImg } from "../../images";
import { act, hover } from "../../ui";
import { KillstreakEditItem, KillstreakSlot } from "../../types";
import "./index.scss";

const SlotCard = ({
  s,
  editing,
  onEdit,
}: {
  s: KillstreakSlot;
  editing: boolean;
  onEdit: () => void;
}) => (
  <button
    className={`kse__slot${editing ? " kse__slot--editing" : ""}`}
    onMouseEnter={hover}
    onClick={onEdit}
  >
    <span className="kse__slot-tag">Slot {s.index}</span>
    <img
      className="kse__slot-ico"
      src={IMG(`hud/killstreaks/${s.icon}.png`)}
      alt=""
      draggable={false}
      onError={hideImg}
    />
    <span className="kse__slot-name">{s.label}</span>
    <span className="kse__slot-cost">{s.kill} pts</span>
    <span className="kse__slot-change">{editing ? "Choosing…" : "Change ›"}</span>
  </button>
);

const StreakCard = ({
  k,
  current,
  onEquip,
}: {
  k: KillstreakEditItem;
  current: boolean;
  onEquip: () => void;
}) => {
  const locked = k.equipped && !current;
  return (
    <button
      className={`kse__card${current ? " kse__card--current" : ""}${locked ? " kse__card--locked" : ""}`}
      onMouseEnter={() => !locked && hover()}
      onClick={() => !locked && onEquip()}
      disabled={locked}
    >
      <img
        className="kse__card-ico"
        src={IMG(`hud/killstreaks/${k.icon}.png`)}
        alt=""
        draggable={false}
        onError={hideImg}
      />
      <span className="kse__card-body">
        <span className="kse__card-top">
          <span className="kse__card-name">{k.label}</span>
          <span className="kse__card-cost">{k.kill}</span>
        </span>
        <span className="kse__card-desc">{k.desc}</span>
      </span>
      {current ? (
        <span className="kse__card-badge kse__card-badge--current">Equipped here</span>
      ) : locked ? (
        <span className="kse__card-badge">In another slot</span>
      ) : null}
    </button>
  );
};

const KillstreakEditor = () => {
  const d = useSelector((s) => s.killstreakEditor);
  const [editing, setEditing] = useState<number | null>(null);

  const slot = editing !== null ? d.slots[editing] : null;

  return (
    <div className="kse">
      <section className="kse__loadout">
        <span className="kse__label">
          Your Loadout
          <span className="kse__label-hint">Pick a slot to change it</span>
        </span>
        <div className="kse__slots">
          {d.slots.map((s, i) => (
            <SlotCard key={s.index} s={s} editing={editing === i} onEdit={() => setEditing(i)} />
          ))}
        </div>
      </section>

      <section className="kse__pick">
        {slot ? (
          <>
            <span className="kse__label">
              Choose a scorestreak
              <span className="kse__label-slot">for Slot {slot.index}</span>
            </span>
            <div className="kse__list">
              {d.streaks.map((k) => (
                <StreakCard
                  key={k.type}
                  k={k}
                  current={k.type === slot.type}
                  onEquip={() => act("equip_killstreak", { slot: slot.index, type: k.type })}
                />
              ))}
            </div>
          </>
        ) : (
          <div className="kse__empty">
            <span className="kse__empty-icon">›</span>
            Select a slot
          </div>
        )}
      </section>
    </div>
  );
};

export default KillstreakEditor;
