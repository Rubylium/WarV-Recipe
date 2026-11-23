import { PointerEvent, useEffect, useRef, useState } from "react";
import { useSelector } from "../..";
import Nui from "../../FiveM";
import {
  ClothingAppearance,
  ClothingComponent,
  ClothingOutfit,
  ClothingProp,
  HeadOverlay,
} from "../../types";
import { act, actSilent, hover } from "../../ui";
import "./index.scss";

type EditorTab = "model" | "face" | "clothing" | "props" | "overlays";

const tabs: { id: EditorTab; label: string }[] = [
  { id: "model", label: "Model" },
  { id: "face", label: "Face" },
  { id: "clothing", label: "Clothing" },
  { id: "props", label: "Props" },
  { id: "overlays", label: "Details" },
];

const faceLabels = [
  "Nose width", "Nose peak height", "Nose peak length", "Nose bone height",
  "Nose peak lowering", "Nose bone twist", "Eyebrow height", "Eyebrow depth",
  "Cheekbone height", "Cheekbone width", "Cheek width", "Eye opening",
  "Lip thickness", "Jaw width", "Jaw height", "Chin length",
  "Chin position", "Chin width", "Chin shape", "Neck width",
];

const overlayLabels = [
  "Blemishes", "Facial hair", "Eyebrows", "Ageing", "Makeup", "Blush",
  "Complexion", "Sun damage", "Lipstick", "Moles & freckles", "Chest hair",
  "Body blemishes", "Extra blemishes",
];

const blendLabels: Record<string, string> = {
  shapeFirst: "Shape A",
  shapeSecond: "Shape B",
  shapeThird: "Shape C",
  skinFirst: "Skin A",
  skinSecond: "Skin B",
  skinThird: "Skin C",
  shapeMix: "Shape mix",
  skinMix: "Skin mix",
  thirdMix: "Third mix",
};

const poses = [
  { label: "Idle", pose: "idle" },
  { label: "Top", pose: "top" },
  { label: "Legs", pose: "legs" },
  { label: "Shoes", pose: "shoes" },
  { label: "Arms", pose: "arms" },
];

const clone = <T,>(value: T): T => JSON.parse(JSON.stringify(value));
const clamp = (value: number, min: number, max: number) => Math.max(min, Math.min(max, value));

const Step = ({
  label,
  value,
  min,
  max,
  onSet,
}: {
  label?: string;
  value: number;
  min: number;
  max: number;
  onSet: (next: number) => void;
}) => (
  <div className="cc__step">
    {label && <span className="cc__step-cap">{label}</span>}
    <button className="cc__nudge" onMouseEnter={hover} onClick={() => onSet(clamp(value - 1, min, max))}>
      ‹
    </button>
    <span className="cc__step-val">{value}</span>
    <button className="cc__nudge" onMouseEnter={hover} onClick={() => onSet(clamp(value + 1, min, max))}>
      ›
    </button>
    <span className="cc__step-max">{max}</span>
  </div>
);

const Slide = ({
  label,
  value,
  min,
  max,
  step,
  onSet,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  step: number;
  onSet: (next: number) => void;
}) => (
  <label className="cc__slide">
    <span className="cc__slide-cap">{label}</span>
    <input
      className="cc__range"
      type="range"
      min={min}
      max={max}
      step={step}
      value={clamp(value, min, max)}
      onChange={(event) => onSet(Number(event.target.value))}
    />
    <span className="cc__slide-val">{step < 1 ? value.toFixed(2) : value}</span>
  </label>
);

const ClothingCreator = () => {
  const data = useSelector((state) => state.clothingCreator);
  const [draft, setDraft] = useState<ClothingOutfit>(() => clone(data.draft));
  const [tab, setTab] = useState<EditorTab>("clothing");
  const [query, setQuery] = useState("");
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [armed, setArmed] = useState<string | null>(null);
  const [modelInput, setModelInput] = useState(() => String(data.draft.appearance.model));
  const drag = useRef({ active: false, x: 0, y: 0 });

  useEffect(() => {
    setDraft(clone(data.draft));
    setModelInput(String(data.draft.appearance.model));
    setConfirmDelete(false);
    setArmed(null);
  }, [data.draft]);

  const needle = query.trim().toLowerCase();
  const outfits = data.outfits.filter((outfit) => !needle || outfit.name.toLowerCase().includes(needle));

  const pushDraft = (next: ClothingOutfit) => {
    setDraft(next);
    actSilent("clothing_apply", { name: next.name, appearance: next.appearance });
  };

  const toggleTeam = (team: number) => {
    const next = clone(draft);
    next.teams = next.teams.includes(team)
      ? next.teams.filter((value) => value !== team)
      : [...next.teams, team].sort();
    setDraft(next);
    act("clothing_teams", { teams: next.teams });
  };

  const mutate = (apply: (appearance: ClothingAppearance) => void) => {
    const next = clone(draft);
    apply(next.appearance);
    pushDraft(next);
  };

  const selectModel = (model: string | number) => {
    setModelInput(String(model));
    mutate((appearance) => {
      appearance.model = model;
    });
  };

  const commitModel = () => {
    const raw = modelInput.trim();
    if (!raw) {
      setModelInput(String(draft.appearance.model));
      return;
    }
    selectModel(/^\d+$/.test(raw) ? Number(raw) : raw);
  };

  const component = (id: number): ClothingComponent =>
    draft.appearance.components[String(id)] || { drawable: 0, texture: 0, palette: 0 };
  const prop = (id: number): ClothingProp =>
    draft.appearance.props[String(id)] || { drawable: -1, texture: -1 };
  const overlay = (id: number): HeadOverlay =>
    draft.appearance.headOverlays[String(id)] || {
      value: 255,
      opacity: 1,
      colorType: 0,
      color: 0,
      secondColor: 0,
    };

  const setComponent = (id: number, patch: Partial<ClothingComponent>) =>
    mutate((appearance) => {
      appearance.components[String(id)] = { ...component(id), ...patch };
      if (patch.drawable !== undefined) {
        appearance.components[String(id)].texture = 0;
        appearance.components[String(id)].palette = 0;
      }
    });

  const setProp = (id: number, patch: Partial<ClothingProp>) =>
    mutate((appearance) => {
      appearance.props[String(id)] = { ...prop(id), ...patch };
      if (patch.drawable !== undefined) {
        appearance.props[String(id)].texture = patch.drawable < 0 ? -1 : 0;
      }
    });

  const setOverlay = (id: number, patch: Partial<HeadOverlay>) =>
    mutate((appearance) => {
      appearance.headOverlays[String(id)] = { ...overlay(id), ...patch };
    });

  const onPointerDown = (event: PointerEvent<HTMLDivElement>) => {
    drag.current = { active: true, x: event.clientX, y: event.clientY };
    event.currentTarget.setPointerCapture(event.pointerId);
  };

  const onPointerMove = (event: PointerEvent<HTMLDivElement>) => {
    if (!drag.current.active) return;
    Nui.post("CLOTHING_CAMERA", {
      dx: event.clientX - drag.current.x,
      dy: event.clientY - drag.current.y,
    });
    drag.current.x = event.clientX;
    drag.current.y = event.clientY;
  };

  const release = () => (drag.current.active = false);

  const model = String(draft.appearance.model);

  return (
    <main className="cc">
      <aside className="cc__catalog">
        <div className="cc__head">
          <span className="cc__cap">Outfits</span>
          <span className="cc__spacer" />
          <button className="cc__btn cc__btn--go" onMouseEnter={hover} onClick={() => act("clothing_new")}>
            New
          </button>
        </div>
        <input
          className="cc__input"
          placeholder="SEARCH"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
        />
        <div className="cc__list">
          {outfits.map((outfit) => (
            <div key={outfit.id} className={`cc__outfit${data.selectedId === outfit.id ? " cc__outfit--on" : ""}`}>
              <button
                className="cc__outfit-go"
                onMouseEnter={hover}
                onClick={() => act("clothing_select", { id: outfit.id })}
              >
                <span className="cc__outfit-name">{outfit.name}</span>
                <span className="cc__outfit-sub">
                  <span className="cc__outfit-model">{String(outfit.appearance.model)}</span>
                  {outfit.teams.map((team) => (
                    <span className="cc__pool" key={team}>
                      T{team}
                    </span>
                  ))}
                </span>
              </button>
              <button
                className={`cc__mini${armed === outfit.id ? " cc__mini--armed" : ""}`}
                disabled={data.saving}
                onMouseEnter={hover}
                onClick={() => (armed === outfit.id ? act("clothing_delete", { id: outfit.id }) : setArmed(outfit.id))}
              >
                {armed === outfit.id ? "OK" : "×"}
              </button>
            </div>
          ))}
          {outfits.length === 0 && <span className="cc__empty">No outfit saved</span>}
        </div>
      </aside>

      <div
        className="cc__viewport"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={release}
        onPointerCancel={release}
        onWheel={(event) => Nui.post("CLOTHING_CAMERA", { wheel: event.deltaY })}
      >
        <div className="cc__poses" onPointerDown={(event) => event.stopPropagation()}>
          {poses.map((item) => (
            <button
              key={item.pose}
              className="cc__btn"
              onMouseEnter={hover}
              onClick={() => act("clothing_pose", { pose: item.pose })}
            >
              {item.label}
            </button>
          ))}
          <span className="cc__spacer" />
          <button className="cc__btn" onMouseEnter={hover} onClick={() => act("clothing_pose", { pose: "turnLeft" })}>
            ⟲
          </button>
          <button className="cc__btn" onMouseEnter={hover} onClick={() => act("clothing_pose", { pose: "turnRight" })}>
            ⟳
          </button>
        </div>
        <span className="cc__hint">Drag to orbit · wheel to zoom</span>
      </div>

      <aside className="cc__editor">
        <div className="cc__head">
          <input
            className="cc__name"
            value={draft.name}
            maxLength={48}
            onChange={(event) => {
              const next = clone(draft);
              next.name = event.target.value;
              pushDraft(next);
            }}
          />
          <button className="cc__mini" onMouseEnter={hover} onClick={() => act("clothing_close", {}, "back")}>
            ×
          </button>
        </div>

        <div className="cc__head">
          <span className="cc__cap">Team pools</span>
          {[1, 2].map((team) => (
            <button
              key={team}
              className={`cc__btn${draft.teams.includes(team) ? " cc__btn--go" : ""}`}
              onMouseEnter={hover}
              onClick={() => toggleTeam(team)}
            >
              Team {team}
            </button>
          ))}
          <span className="cc__spacer" />
          <span className="cc__hint">{draft.teams.length === 0 ? "Off rotation" : "In rotation"}</span>
        </div>

        <nav className="cc__tabs">
          {tabs.map((item) => (
            <button
              key={item.id}
              className={`cc__tab${tab === item.id ? " cc__tab--on" : ""}`}
              onMouseEnter={hover}
              onClick={() => setTab(item.id)}
            >
              {item.label}
            </button>
          ))}
        </nav>

        <div className="cc__scroll">
          {tab === "model" && (
            <>
              <div className="cc__block">
                <span className="cc__cap">Base ped</span>
                <div className="cc__row">
                  <button
                    className={`cc__btn${model === "mp_m_freemode_01" ? " cc__btn--go" : ""}`}
                    onMouseEnter={hover}
                    onClick={() => selectModel("mp_m_freemode_01")}
                  >
                    Male
                  </button>
                  <button
                    className={`cc__btn${model === "mp_f_freemode_01" ? " cc__btn--go" : ""}`}
                    onMouseEnter={hover}
                    onClick={() => selectModel("mp_f_freemode_01")}
                  >
                    Female
                  </button>
                </div>
                <input
                  className="cc__input"
                  value={modelInput}
                  onChange={(event) => setModelInput(event.target.value)}
                  onBlur={commitModel}
                  onKeyDown={(event) => event.key === "Enter" && event.currentTarget.blur()}
                />
              </div>

              <div className="cc__block">
                <span className="cc__cap">Hair & eyes</span>
                <Step label="Hair color" value={draft.appearance.hair.color} min={0} max={data.limits.hairColorMax} onSet={(v) => mutate((a) => { a.hair.color = v; })} />
                <Step label="Highlight" value={draft.appearance.hair.highlight} min={0} max={data.limits.hairColorMax} onSet={(v) => mutate((a) => { a.hair.highlight = v; })} />
                <Step label="Eye color" value={draft.appearance.eyeColor} min={0} max={31} onSet={(v) => mutate((a) => { a.eyeColor = v; })} />
              </div>

              <div className="cc__block">
                <span className="cc__cap">Heritage</span>
                {(["shapeFirst", "shapeSecond", "shapeThird", "skinFirst", "skinSecond", "skinThird"] as const).map((key) => (
                  <Step key={key} label={blendLabels[key]} value={draft.appearance.headBlend[key]} min={0} max={45} onSet={(v) => mutate((a) => { a.headBlend[key] = v; })} />
                ))}
                {(["shapeMix", "skinMix", "thirdMix"] as const).map((key) => (
                  <Slide key={key} label={blendLabels[key]} value={draft.appearance.headBlend[key]} min={0} max={1} step={0.01} onSet={(v) => mutate((a) => { a.headBlend[key] = v; })} />
                ))}
              </div>
            </>
          )}

          {tab === "face" && (
            <div className="cc__block">
              <span className="cc__cap">Sculpt</span>
              {faceLabels.map((label, id) => (
                <Slide
                  key={label}
                  label={label}
                  value={draft.appearance.faceFeatures[String(id)] || 0}
                  min={-1}
                  max={1}
                  step={0.01}
                  onSet={(v) => mutate((a) => { a.faceFeatures[String(id)] = v; })}
                />
              ))}
            </div>
          )}

          {tab === "clothing" && (
            <>
              <div className="cc__slothead">
                <span />
                <span>Slot</span>
                <span>Item</span>
                <span>Texture</span>
                <span>Palette</span>
              </div>
              {data.limits.components.map((limit) => {
                const current = component(limit.id);
                return (
                  <div className="cc__slot" key={limit.id}>
                    <span className="cc__slot-id">{String(limit.id).padStart(2, "0")}</span>
                    <span className="cc__slot-name">{limit.label}</span>
                    <Step value={current.drawable} min={0} max={limit.drawableMax} onSet={(v) => setComponent(limit.id, { drawable: v })} />
                    <Step value={current.texture} min={0} max={limit.textureMax} onSet={(v) => setComponent(limit.id, { texture: v })} />
                    <Step value={current.palette} min={0} max={3} onSet={(v) => setComponent(limit.id, { palette: v })} />
                  </div>
                );
              })}
            </>
          )}

          {tab === "props" && (
            <>
              <div className="cc__slothead">
                <span />
                <span>Slot</span>
                <span>Item</span>
                <span>Texture</span>
                <span />
              </div>
              {data.limits.props.map((limit) => {
                const current = prop(limit.id);
                return (
                  <div className="cc__slot" key={limit.id}>
                    <span className="cc__slot-id">{String(limit.id).padStart(2, "0")}</span>
                    <span className="cc__slot-name">{limit.label}</span>
                    <Step value={current.drawable} min={-1} max={limit.drawableMax} onSet={(v) => setProp(limit.id, { drawable: v })} />
                    {current.drawable >= 0 ? (
                      <Step value={current.texture} min={0} max={limit.textureMax} onSet={(v) => setProp(limit.id, { texture: v })} />
                    ) : (
                      <span className="cc__off">None</span>
                    )}
                    <span />
                  </div>
                );
              })}
            </>
          )}

          {tab === "overlays" &&
            overlayLabels.map((label, id) => {
              const current = overlay(id);
              const on = current.value !== 255;
              return (
                <div className={`cc__block${on ? " cc__block--on" : ""}`} key={label}>
                  <div className="cc__step">
                    <span className="cc__step-cap">{label}</span>
                    {on ? (
                      <>
                        <Step value={current.value} min={0} max={255} onSet={(v) => setOverlay(id, { value: v })} />
                        <button className="cc__mini" onMouseEnter={hover} onClick={() => setOverlay(id, { value: 255 })}>
                          ×
                        </button>
                      </>
                    ) : (
                      <button className="cc__btn" onMouseEnter={hover} onClick={() => setOverlay(id, { value: 0 })}>
                        Enable
                      </button>
                    )}
                  </div>
                  {on && (
                    <>
                      <Slide label="Opacity" value={current.opacity} min={0} max={1} step={0.01} onSet={(v) => setOverlay(id, { opacity: v })} />
                      <Step label="Color" value={current.color} min={0} max={data.limits.hairColorMax} onSet={(v) => setOverlay(id, { color: v })} />
                      <Step label="Second" value={current.secondColor} min={0} max={data.limits.hairColorMax} onSet={(v) => setOverlay(id, { secondColor: v })} />
                      <Step label="Blend" value={current.colorType} min={0} max={2} onSet={(v) => setOverlay(id, { colorType: v })} />
                    </>
                  )}
                </div>
              );
            })}
        </div>

        {data.notice !== "" && (
          <span className={`cc__notice${data.notice.toLowerCase().includes("saved") ? " cc__notice--ok" : ""}`}>
            {data.notice}
          </span>
        )}

        <div className="cc__actions">
          <button className="cc__btn" disabled={!data.selectedId || data.saving} onMouseEnter={hover} onClick={() => act("clothing_revert")}>
            Revert
          </button>
          <button
            className="cc__btn cc__btn--bad"
            disabled={!data.selectedId || data.saving}
            onMouseEnter={hover}
            onClick={() => (confirmDelete ? act("clothing_delete") : setConfirmDelete(true))}
          >
            {confirmDelete ? "Confirm" : "Delete"}
          </button>
          <span className="cc__spacer" />
          <button
            className="cc__btn cc__btn--go"
            disabled={data.saving || draft.name.trim() === ""}
            onMouseEnter={hover}
            onClick={() => act("clothing_save", { outfit: draft })}
          >
            {data.saving ? "Saving" : data.selectedId ? "Save" : "Create"}
          </button>
        </div>
      </aside>
    </main>
  );
};

export default ClothingCreator;
