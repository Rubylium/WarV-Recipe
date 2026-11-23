import { ComponentType, SVGProps, useEffect, useLayoutEffect, useRef, useState } from "react";
import { PiCaretDoubleLeftBold, PiCaretDoubleRightBold, PiCubeFocusBold } from "react-icons/pi";
import { useSelector } from "../..";
import TopBar from "../../Components/TopBar";
import SubHeader from "../../Components/SubHeader";
import Spinner from "../../Components/Spinner";
import Nui from "../../FiveM";
import { AttachEffect, AttachStat } from "../../types";
import { act, actSilent, hover, uiSound } from "../../ui";
import { LockIcon } from "../../Components/WeaponArt";
import "./index.scss";

type Icon = ComponentType<SVGProps<SVGSVGElement>>;
const RotateLeftIcon = PiCaretDoubleLeftBold as Icon;
const RotateRightIcon = PiCaretDoubleRightBold as Icon;
const ResetViewIcon = PiCubeFocusBold as Icon;

const XIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="square">
    <line x1="6" y1="6" x2="18" y2="18" />
    <line x1="18" y1="6" x2="6" y2="18" />
  </svg>
);
const clamp = (v: number) => Math.max(0.05, Math.min(0.95, v));
const signed = (v: number, suffix = "%") => `${v > 0 ? "+" : ""}${v}${suffix}`;

const EffectChips = ({ effects }: { effects: AttachEffect[] }) => {
  const shown = effects.slice(0, 3);
  const more = effects.length - shown.length;
  const title = effects.map((e) => (e.value ? `${e.label} ${e.value}` : e.label)).join(" · ");

  return (
    <span className="ae__effects" title={title}>
      {shown.map((e, i) => (
        <span className={`ae__effect ae__effect--${e.tone}`} key={i}>
          <span>{e.label}</span>
          {e.value && <strong>{e.value}</strong>}
        </span>
      ))}
      {more > 0 && <span className="ae__effect-more">+{more}</span>}
    </span>
  );
};

const markerTransform = (side: string) => {
  if (side === "top") return "translate(-50%, -100%)";
  if (side === "bottom") return "translate(-50%, 0)";
  if (side === "left") return "translate(-100%, -50%)";
  if (side === "right") return "translate(0, -50%)";
  return "translate(-50%, -50%)";
};

const AttachEditor = () => {
  const d = useSelector((s) => s.attachEditor);
  const markers = useSelector((s) => s.attachMarkers);
  const [open, setOpen] = useState<string | null>(null);
  const markersRef = useRef<HTMLDivElement>(null);
  const dragging = useRef(false);
  const anchorSlot = useRef<string | null>(null);
  const movingGun = useRef(false);

  useEffect(() => {
    if (open !== null || markers.length > 0 || d.types.length === 0 || d.editing) return;
    const t = setTimeout(() => setOpen(d.types[0].type), 1600);
    return () => clearTimeout(t);
  }, [markers.length, d.types, open, d.editing]);

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      if (anchorSlot.current) {
        Nui.post("GUNSMITH_ANCHOR_DRAG", {
          slot: anchorSlot.current,
          dx: e.movementX / window.innerWidth,
          dy: e.movementY / window.innerHeight,
        });
        return;
      }
      if (movingGun.current) {
        Nui.post("GUNSMITH_MOVE", { dx: e.movementX / window.innerWidth, dy: e.movementY / window.innerHeight });
        return;
      }
      if (!dragging.current) return;
      Nui.post("GUNSMITH_DRAG", { dx: e.movementX / window.innerWidth, dy: e.movementY / window.innerHeight });
    };
    const onUp = () => {
      dragging.current = false;
      anchorSlot.current = null;
      movingGun.current = false;
      document.body.classList.remove("ae-grabbing");
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, []);

  const startDrag = () => {
    if (d.editing) movingGun.current = true;
    else dragging.current = true;
    document.body.classList.add("ae-grabbing");
  };

  useLayoutEffect(() => {
    const cont = markersRef.current;
    if (!cont) return;
    const els = Array.from(cont.querySelectorAll<HTMLElement>(".ae__marker"));
    if (els.length === 0) return;
    const vw = window.innerWidth;
    const vh = window.innerHeight;
    const padX = Math.max(14, vw * 0.012);
    const padY = Math.max(14, vh * 0.02);
    els.forEach((el) => {
      el.style.marginLeft = "0px";
      el.style.marginTop = "0px";
    });
    const rects = els.map((el) => el.getBoundingClientRect());
    els.forEach((el, i) => {
      const r = rects[i];
      let dx = 0;
      let dy = 0;
      if (r.left < padX) dx = padX - r.left;
      else if (r.right > vw - padX) dx = vw - padX - r.right;
      if (r.top < padY) dy = padY - r.top;
      else if (r.bottom > vh - padY) dy = vh - padY - r.bottom;
      if (dx) el.style.marginLeft = `${dx}px`;
      if (dy) el.style.marginTop = `${dy}px`;
    });
  }, [markers, open]);

  const openType = d.types.find((t) => t.type === open);
  const title = open === "tint" ? "Camo" : openType ? openType.label : "";

  const equip = (type: string, extra: object) => {
    uiSound(`gunsmith_${type}`);
    actSilent("attach_set", { type, ...extra });
  };
  const preview = (type: string, model: string) => {
    hover();
    actSilent("attach_preview", { type, model });
  };
  const clearPreview = () => actSilent("attach_preview_clear");
  const openPanel = (slot: string | null) => {
    uiSound("gunsmith_menu");
    clearPreview();
    setOpen(slot);
  };
  const grabAnchor = (slot: string) => {
    anchorSlot.current = slot;
    document.body.classList.add("ae-grabbing");
  };

  return (
    <>
      <TopBar active="" tabs={[]} subtitle="Gunsmith" />
      <div className="ae">
        <div
          className="ae__drag"
          onMouseDown={startDrag}
          onContextMenu={(e) => {
            e.preventDefault();
            if (d.editing) actSilent("attach_edit_reset");
          }}
        />

        <SubHeader
          title={d.weapon.label || "Gunsmith"}
          back="attach_back"
          right={
            <div className="ae__headright">
              <div className={`ae__slots${d.attachments.used >= d.attachments.limit ? " ae__slots--full" : ""}`}>
                <div className="ae__slots-head">
                  <span className="ae__slots-cap">Attachments</span>
                  <span className="ae__slots-n">
                    {d.attachments.used}/{d.attachments.limit}
                  </span>
                </div>
                <span className="ae__pips">
                  {Array.from({ length: d.attachments.limit }, (_, i) => (
                    <span key={i} className={`ae__pip${i < d.attachments.used ? " ae__pip--on" : ""}`} />
                  ))}
                </span>
              </div>
              <div className="ae__level">
                <span className="ae__level-badge">
                  <span className="ae__level-k">{d.level >= d.maxLevel ? "MAX" : "LVL"}</span>
                  <span className="ae__level-n">{d.level}</span>
                </span>
                <div className="ae__level-bar">
                  <div className="ae__level-bar-head">
                    <span className="ae__level-cap">Weapon Level</span>
                    <span className="ae__level-xp">
                      {d.level >= d.maxLevel ? "Mastered" : `${d.xpInto} / ${d.xpSpan} XP`}
                    </span>
                  </div>
                  <span className="ae__level-track">
                    <span
                      className="ae__level-fill"
                      style={{ width: `${d.level >= d.maxLevel ? 100 : Math.max(0, Math.min(100, (d.xpInto / Math.max(1, d.xpSpan)) * 100))}%` }}
                    />
                  </span>
                </div>
              </div>
            </div>
          }
        />

        {markers.length === 0 && (
          <div className="ae__loading">
            <Spinner className="ae__loading-spin" />
            <span className="ae__loading-txt">Preparing weapon</span>
          </div>
        )}

        <div className="ae__markers" ref={markersRef}>
          {markers.map((m) => (
            <button
              key={m.slot}
              className={`ae__marker ae__marker--${m.side}${m.slot === open ? " ae__marker--open" : ""}${m.installed ? " ae__marker--on" : ""}${m.internal ? " ae__marker--int" : ""}${d.editing ? " ae__marker--move" : ""}`}
              style={{ left: `${clamp(m.x) * 100}%`, top: `${clamp(m.y) * 100}%`, transform: markerTransform(m.side) }}
              onMouseEnter={hover}
              onMouseDown={() => d.editing && grabAnchor(m.slot)}
              onContextMenu={(e) => {
                e.preventDefault();
                if (d.editing) actSilent("attach_edit_reset", { slot: m.slot });
              }}
              onClick={() => !d.editing && openPanel(m.slot)}
            >
              <span className="ae__marker-dot" />
              <span className="ae__marker-info">
                <span className="ae__marker-slot">{m.label}</span>
                {m.installed && <span className="ae__marker-val">{m.installed}</span>}
              </span>
            </button>
          ))}
        </div>

        {d.canEdit && (
          <div className={`ae__anchor-edit${d.editing ? " ae__anchor-edit--on" : ""}`}>
            <button className="ae__anchor-btn" onMouseEnter={hover} onClick={() => act("attach_edit_toggle")}>
              {d.editing ? "Save layout" : "Edit"}
            </button>
            {d.editing && (
              <span className="ae__anchor-hint">
                Drag markers to place · drag gun to centre · right-click resets
              </span>
            )}
          </div>
        )}

        {open && !d.editing && (
          <aside className="ae__panel">
            <div className="ae__panel-head">
              <span className="ae__panel-title">{title}</span>
              <button className="ae__close" onMouseEnter={hover} onClick={() => openPanel(null)}>
                <XIcon />
              </button>
            </div>

            <div className="ae__list">
              {open === "tint" ? (
                d.tints.map((t) => (
                  <button
                    key={t.index}
                    className={`ae__row${t.installed ? " ae__row--active" : ""}${t.previewing ? " ae__row--preview" : ""}${t.locked ? " ae__row--locked" : ""}`}
                    onMouseEnter={() => !t.locked && hover()}
                    onClick={() => (t.locked ? uiSound("error") : equip("tint", { index: t.index }))}
                  >
                    <span className="ae__row-dot" />
                    <span className="ae__row-name">{t.label}</span>
                    {t.locked ? (
                      <span className="ae__row-lock">
                        <LockIcon />
                        Lvl {t.unlock}
                      </span>
                    ) : t.installed ? (
                      <span className="ae__row-eq">Equipped</span>
                    ) : t.previewing ? (
                      <span className="ae__row-pv">Preview</span>
                    ) : null}
                  </button>
                ))
              ) : openType ? (
                <>
                  {openType.installed && (
                    <button
                      className="ae__row ae__row--clear"
                      onMouseEnter={() => preview(openType.type, "")}
                      onMouseLeave={clearPreview}
                      onClick={() => equip(openType.type, { model: "" })}
                    >
                      <span className="ae__row-x">
                        <XIcon />
                      </span>
                      <span className="ae__row-name">Remove attachment</span>
                    </button>
                  )}
                  {openType.items.map((it) => {
                    const blocked = it.locked || (openType.capped && !it.installed);
                    return (
                    <button
                      key={it.model}
                      className={`ae__row${it.installed ? " ae__row--active" : ""}${it.previewing ? " ae__row--preview" : ""}${it.locked ? " ae__row--locked" : ""}${!it.locked && blocked ? " ae__row--capped" : ""}`}
                      onMouseEnter={() => !blocked && preview(openType.type, it.model)}
                      onMouseLeave={() => !blocked && clearPreview()}
                      onClick={() => (blocked ? uiSound("error") : equip(openType.type, { model: it.model }))}
                    >
                      <span className="ae__row-dot" />
                      <span className="ae__row-main">
                        <span className="ae__row-name">{it.name}</span>
                        {it.effects.length > 0 && <EffectChips effects={it.effects} />}
                      </span>
                      {it.locked ? (
                        <span className="ae__row-lock">
                          <LockIcon />
                          Lvl {it.level}
                        </span>
                      ) : it.installed ? (
                        <span className="ae__row-eq">Equipped</span>
                      ) : blocked ? (
                        <span className="ae__row-full">Full</span>
                      ) : it.previewing ? (
                        <span className="ae__row-pv">Preview</span>
                      ) : null}
                    </button>
                    );
                  })}
                  {openType.items.length === 0 && <div className="ae__empty">No attachments</div>}
                </>
              ) : null}
            </div>
          </aside>
        )}

        <div className="ae__statbox">
          {([
            ["Damage", d.stats.damage, 1],
            ["Recoil", d.stats.recoil, 3],
            ["Spread", d.stats.spread, 3],
            ["Range", d.stats.range, 1],
            ["Fire Rate", d.stats.fireRate, 1],
            ["Mobility", d.stats.mobility, 1],
          ] as [string, AttachStat, number][]).map(([label, stat, digits]) => {
            const left = Math.min(stat.bar, stat.referenceBar);
            const width = Math.abs(stat.bar - stat.referenceBar);
            const changed = Math.abs(stat.delta) >= 0.05;
            return (
            <div key={label} className="ae__statrow">
              <span className="ae__stat-k">{label}</span>
              <span className="ae__stat-track">
                <span className="ae__stat-fill" style={{ width: `${Math.max(0, Math.min(100, stat.referenceBar))}%` }} />
                {changed && width > 0 && (
                  <span
                    className={`ae__stat-change ae__stat-change--${stat.tone}`}
                    style={{ left: `${left}%`, width: `${width}%` }}
                  />
                )}
              </span>
              <span className={`ae__stat-v${changed ? ` ae__stat-v--${stat.tone}` : ""}`}>
                {changed && <small>{stat.referenceValue.toFixed(digits)} &gt; </small>}
                {stat.value.toFixed(digits)}
                {changed && <em>{signed(stat.delta)}</em>}
              </span>
            </div>
            );
          })}
          <div className="ae__statrow">
            <span className="ae__stat-k">Magazine</span>
            <span className="ae__stat-track" />
            <span className={`ae__stat-v${d.stats.clip.delta !== 0 ? ` ae__stat-v--${d.stats.clip.tone}` : ""}`}>
              {d.stats.clip.delta !== 0 && <small>{d.stats.clip.referenceValue} &gt; </small>}
              {d.stats.clip.value}
              {d.stats.clip.delta !== 0 && <em>{signed(d.stats.clip.delta, "")}</em>}
            </span>
          </div>
        </div>

        <div className="ae__controls">
          <button
            className="ae__ctrl"
            onMouseEnter={hover}
            onClick={() => act("gunsmith_spin", { dir: -1 })}
            title="Rotate left"
            aria-label="Rotate left"
          >
            <RotateLeftIcon />
          </button>
          <button
            className="ae__ctrl ae__ctrl--wide"
            onMouseEnter={hover}
            onClick={() => act("gunsmith_reset")}
            title="Reset view"
          >
            <ResetViewIcon />
            <span>Reset View</span>
          </button>
          <button
            className="ae__ctrl"
            onMouseEnter={hover}
            onClick={() => act("gunsmith_spin", { dir: 1 })}
            title="Rotate right"
            aria-label="Rotate right"
          >
            <RotateRightIcon />
          </button>
        </div>
        <span className="ae__drag-hint">Click &amp; drag to rotate</span>
      </div>
    </>
  );
};

export default AttachEditor;
