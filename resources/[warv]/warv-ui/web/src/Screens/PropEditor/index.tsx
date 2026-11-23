import { useEffect, useRef, useState } from "react";
import { useSelector } from "../..";
import Nui from "../../FiveM";
import { act, actSilent, hover } from "../../ui";
import "./index.scss";

const list = <T,>(value: T[] | undefined) => (Array.isArray(value) ? value : []);
const send = (data: object) => Nui.post("PROP_EDITOR_INPUT", data);

const kindTag: Record<string, string> = { prop: "PROP", ped: "PED", vehicle: "VEH", world: "WORLD" };

const Step = ({
  label,
  value,
  min,
  max,
  step = 1,
  onSet,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  step?: number;
  onSet: (next: number) => void;
}) => {
  const clamp = (next: number) => Math.max(min, Math.min(max, next));
  return (
    <div className="pe__step">
      <span className="pe__step-label">{label}</span>
      <button className="pe__mini" onMouseEnter={hover} onClick={() => onSet(clamp(value - step))}>
        ‹
      </button>
      <span className="pe__step-value">{value}</span>
      <button className="pe__mini" onMouseEnter={hover} onClick={() => onSet(clamp(value + step))}>
        ›
      </button>
    </div>
  );
};

const Flag = ({ label, on, onSet }: { label: string; on: boolean; onSet: (next: boolean) => void }) => (
  <button className={`pe__flag${on ? " pe__flag--on" : ""}`} onMouseEnter={hover} onClick={() => onSet(!on)}>
    <span className="pe__box">{on ? "×" : ""}</span>
    <span className="pe__flag-name">{label}</span>
  </button>
);

const PropEditor = () => {
  const d = useSelector((s) => s.propEditor);
  const live = useSelector((s) => s.propEditorLive);
  const sel = live.selection;

  const selectedRow = useRef<HTMLButtonElement>(null);

  const [model, setModel] = useState("");
  const [newMap, setNewMap] = useState("");
  const [naming, setNaming] = useState(false);
  const [confirming, setConfirming] = useState("");
  const [tab, setTab] = useState<"history" | "favorites">("history");
  const [renaming, setRenaming] = useState(-1);
  const [renameText, setRenameText] = useState("");

  useEffect(() => {
    selectedRow.current?.scrollIntoView({ block: "nearest" });
  }, [sel?.index]);

  useEffect(() => {
    let typing = false;
    const watchFocus = window.setInterval(() => {
      const el = document.activeElement;
      const now = el instanceof HTMLInputElement || el instanceof HTMLSelectElement;
      if (now === typing) return;
      typing = now;
      actSilent("propedit_typing", { on: now });
    }, 120);

    const onMove = (e: MouseEvent) =>
      send({ kind: "move", x: e.clientX / window.innerWidth, y: e.clientY / window.innerHeight });

    const onUp = () => send({ kind: "up" });

    const onKey = (e: KeyboardEvent) => {
      if (typing) return;

      if (e.key === "Delete") actSilent("propedit_delete");
      else if (e.key === "Escape") send({ kind: "cancel" });
      else if (e.key === "ArrowLeft") actSilent("propedit_rotate", { axis: "z", delta: -15 });
      else if (e.key === "ArrowRight") actSilent("propedit_rotate", { axis: "z", delta: 15 });
      else if (e.key === "ArrowUp") actSilent("propedit_rotate", { axis: "x", delta: 15 });
      else if (e.key === "ArrowDown") actSilent("propedit_rotate", { axis: "x", delta: -15 });
      else if (e.code === "KeyD" && e.ctrlKey) actSilent("propedit_duplicate");
      else if (e.code === "KeyZ" && e.ctrlKey) actSilent("propedit_undo");
      else if (e.code === "KeyS" && e.ctrlKey) actSilent("propedit_save");
    };

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    window.addEventListener("keydown", onKey);
    return () => {
      window.clearInterval(watchFocus);
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
      window.removeEventListener("keydown", onKey);
      actSilent("propedit_typing", { on: false });
    };
  }, []);

  const onViewportDown = (e: React.MouseEvent) => {
    if (e.button === 2) {
      send({ kind: "looking", on: true });
      return;
    }
    if (e.button === 0) send({ kind: "down" });
  };

  const place = (name: string) => {
    act("propedit_add", { model: name });
    setModel("");
  };

  if (d.mode === "pick") {
    return (
      <div className="pe pe--pick">
        <div className="pe__pickhead">
          <div>
            <span className="pe__title">Prop Editor</span>
            <span className="pe__picksub">Props · peds · vehicles · on top of the world</span>
          </div>
          <span className="pe__spacer" />
          {naming ? (
            <input
              className="pe__input"
              autoFocus
              value={newMap}
              placeholder="NEW MAP NAME"
              onChange={(e) => setNewMap(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && newMap.trim()) {
                  act("propedit_create", { name: newMap.trim() });
                  setNaming(false);
                  setNewMap("");
                } else if (e.key === "Escape") setNaming(false);
              }}
            />
          ) : (
            <button className="pe__btn pe__btn--go" onMouseEnter={hover} onClick={() => setNaming(true)}>
              New map
            </button>
          )}
          <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_close")}>
            Exit
          </button>
        </div>

        {d.status !== "" && <span className="pe__status">{d.status}</span>}

        <div className="pe__grid">
          {list(d.cards).map((card) => (
            <div key={card.name} className="pe__card">
              <button className="pe__card-open" onMouseEnter={hover} onClick={() => act("propedit_select_map", { name: card.name })}>
                <span className="pe__card-name">{card.name}</span>
                <span className="pe__card-meta">
                  <span>{card.props} props</span>
                  <span>{card.peds} peds</span>
                  <span>{card.vehicles} veh</span>
                  <span>{card.hidden} removed</span>
                </span>
                {card.live && <span className="pe__tag">Loaded</span>}
              </button>
              {confirming === card.name ? (
                <div className="pe__confirm">
                  <span>Delete {card.name}?</span>
                  <button
                    className="pe__btn pe__btn--bad"
                    onMouseEnter={hover}
                    onClick={() => {
                      act("propedit_delete_map", { name: card.name });
                      setConfirming("");
                    }}
                  >
                    Delete
                  </button>
                  <button className="pe__btn" onMouseEnter={hover} onClick={() => setConfirming("")}>
                    Cancel
                  </button>
                </div>
              ) : (
                <button className="pe__mini pe__mini--bad" title="Delete map" onMouseEnter={hover} onClick={() => setConfirming(card.name)}>
                  ×
                </button>
              )}
            </div>
          ))}
          {list(d.cards).length === 0 && <span className="pe__empty">No map</span>}
        </div>
      </div>
    );
  }

  const vehicle = sel?.vehicle;
  const lobby = d.lobby;
  const handle = live.handle;

  return (
    <div className={`pe${live.looking ? " pe--looking" : ""}${live.preview ? " pe--preview" : ""}${live.gizmo ? " pe--gizmo" : ""}`}>
      <div
        className="pe__viewport"
        onMouseDown={onViewportDown}
        onMouseEnter={() => send({ kind: "over", on: true })}
        onMouseLeave={() => send({ kind: "over", on: false })}
        onContextMenu={(e) => e.preventDefault()}
        onWheel={(e) => send({ kind: "wheel", dy: e.deltaY < 0 ? 1 : -1 })}
      />
      <div className="pe__cross" />

      <div className="pe__top">
        <span className="pe__title">{d.mapName}</span>
        <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_back")}>
          Maps
        </button>
        <span className="pe__spacer" />
        {d.status !== "" && <span className="pe__status">{d.status}</span>}
        {live.dirty && <span className="pe__dirty">Unsaved</span>}
        <span className="pe__speed">{live.speed} m/s</span>
        <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_undo")}>
          Undo
        </button>
        <button className="pe__btn pe__btn--go" onMouseEnter={hover} onClick={() => act("propedit_save")}>
          Save
        </button>
        <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_close")}>
          Exit
        </button>
      </div>

      <div className="pe__left">
        <div className="pe__block">
          <span className="pe__cap">Spawn</span>
          <div className="pe__row">
            <input
              className="pe__input pe__input--wide"
              value={model}
              placeholder="MODEL NAME"
              onChange={(e) => setModel(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && model.trim()) place(model.trim());
              }}
            />
            <button className="pe__btn pe__btn--go" onMouseEnter={hover} onClick={() => model.trim() && place(model.trim())}>
              Place
            </button>
          </div>
          <span className="pe__hintline">Prop, ped or vehicle · kind auto-detected</span>
        </div>

        <div className="pe__block pe__block--grow">
          <div className="pe__tabs">
            <button className={`pe__tab${tab === "history" ? " pe__tab--on" : ""}`} onMouseEnter={hover} onClick={() => setTab("history")}>
              Recent
            </button>
            <button className={`pe__tab${tab === "favorites" ? " pe__tab--on" : ""}`} onMouseEnter={hover} onClick={() => setTab("favorites")}>
              Favorites
            </button>
            <span className="pe__spacer" />
            {tab === "history" && list(d.history).length > 0 && (
              <button className="pe__mini" title="Clear" onMouseEnter={hover} onClick={() => act("propedit_history_clear")}>
                ×
              </button>
            )}
          </div>

          {tab === "history" ? (
            <div className="pe__scroll">
              {list(d.history).map((entry) => (
                <div key={entry} className="pe__item">
                  <button className="pe__item-go" onMouseEnter={hover} onClick={() => place(entry)}>
                    {entry}
                  </button>
                  <button
                    className="pe__mini"
                    title="Add to favorites"
                    onMouseEnter={hover}
                    onClick={() => act("propedit_fav_add", { model: entry, label: entry })}
                  >
                    ★
                  </button>
                </div>
              ))}
              {list(d.history).length === 0 && <span className="pe__empty">Nothing placed yet</span>}
            </div>
          ) : (
            <div className="pe__scroll">
              {list(d.favorites).map((entry, index) =>
                renaming === index ? (
                  <input
                    key={entry.model}
                    className="pe__input"
                    autoFocus
                    value={renameText}
                    onChange={(e) => setRenameText(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        act("propedit_fav_rename", { index: index + 1, label: renameText });
                        setRenaming(-1);
                      } else if (e.key === "Escape") setRenaming(-1);
                    }}
                  />
                ) : (
                  <div key={entry.model} className="pe__item">
                    <button className="pe__item-go" onMouseEnter={hover} onClick={() => place(entry.model)}>
                      <span className="pe__item-name">{entry.label}</span>
                      <span className="pe__item-sub">{entry.model}</span>
                    </button>
                    <button
                      className="pe__mini"
                      title="Rename"
                      onMouseEnter={hover}
                      onClick={() => {
                        setRenaming(index);
                        setRenameText(entry.label);
                      }}
                    >
                      ✎
                    </button>
                    <button
                      className="pe__mini pe__mini--bad"
                      title="Remove"
                      onMouseEnter={hover}
                      onClick={() => act("propedit_fav_delete", { index: index + 1 })}
                    >
                      ×
                    </button>
                  </div>
                )
              )}
              {list(d.favorites).length === 0 && <span className="pe__empty">Star a model to keep it</span>}
            </div>
          )}
        </div>

        <div className="pe__block pe__block--grow">
          <span className="pe__cap">Scene · {list(d.props).length}</span>
          <div className="pe__scroll">
            {list(d.props).map((entry) => (
              <div key={entry.index} className={`pe__item${sel?.index === entry.index ? " pe__item--on" : ""}`}>
                <button
                  className="pe__item-go"
                  ref={sel?.index === entry.index ? selectedRow : undefined}
                  onMouseEnter={hover}
                  onClick={() => act("propedit_focus", { index: entry.index })}
                >
                  <span className={`pe__kind pe__kind--${entry.kind}`}>{kindTag[entry.kind]}</span>
                  <span className="pe__item-name">{entry.model}</span>
                </button>
                <button
                  className="pe__mini pe__mini--bad"
                  title="Delete"
                  onMouseEnter={hover}
                  onClick={() => act("propedit_delete_at", { index: entry.index })}
                >
                  ×
                </button>
              </div>
            ))}
            {list(d.props).length === 0 && <span className="pe__empty">Nothing placed</span>}
          </div>
        </div>

        {lobby && (
          <div className="pe__block">
            <div className="pe__tabs">
              <span className="pe__cap">Lobby</span>
              <span className="pe__spacer" />
              <Flag label="Use this map" on={lobby.enabled} onSet={() => act("propedit_lobby_toggle")} />
            </div>

            {lobby.enabled && (
              <>
                <div className="pe__item">
                  <button
                    className={`pe__item-go${handle?.handle === "me" ? " pe__item-go--on" : ""}`}
                    onMouseEnter={hover}
                    onClick={() => act(lobby.meSet ? "propedit_lobby_select" : "propedit_lobby_place", { id: "me" })}
                  >
                    <span className="pe__kind pe__kind--ped">ME</span>
                    <span className="pe__item-name">{lobby.meSet ? "My position" : "Place my position"}</span>
                  </button>
                </div>

                <div className="pe__item">
                  <button
                    className={`pe__item-go${handle?.handle === "weapon" ? " pe__item-go--on" : ""}`}
                    onMouseEnter={hover}
                    onClick={() => act(lobby.weaponSet ? "propedit_lobby_select" : "propedit_lobby_place", { id: "weapon" })}
                  >
                    <span className="pe__kind pe__kind--vehicle">GUN</span>
                    <span className="pe__item-name">{lobby.weaponSet ? "Weapon stand" : "Place weapon stand"}</span>
                  </button>
                </div>

                {list(lobby.cams).map((cam) => (
                  <div key={cam.key} className="pe__item">
                    <button
                      className={`pe__item-go${handle?.camKey === cam.key ? " pe__item-go--on" : ""}`}
                      onMouseEnter={hover}
                      onClick={() => act(cam.set ? "propedit_lobby_select" : "propedit_lobby_place", { id: `cam:${cam.key}` })}
                    >
                      <span className="pe__kind">CAM</span>
                      <span className="pe__item-name">{cam.label}</span>
                    </button>
                    {cam.set && (
                      <button
                        className={`pe__mini${live.preview === cam.key ? " pe__mini--on" : ""}`}
                        title="Preview"
                        onMouseEnter={hover}
                        onClick={() => act("propedit_lobby_preview", { key: cam.key })}
                      >
                        ◉
                      </button>
                    )}
                  </div>
                ))}

                <div className="pe__tabs">
                  <span className="pe__cap">Time & weather</span>
                  <span className="pe__spacer" />
                  <Flag
                    label="Force"
                    on={lobby.env.set}
                    onSet={(v) => act("propedit_lobby_env", { field: "set", value: v })}
                  />
                </div>
                {lobby.env.set && (
                  <>
                    <Step
                      label="Hour"
                      value={lobby.env.hour}
                      min={-1}
                      max={24}
                      onSet={(v) => act("propedit_lobby_env", { field: "hour", value: (v + 24) % 24 }, false)}
                    />
                    <Step
                      label="Minute"
                      value={lobby.env.minute}
                      min={-5}
                      max={60}
                      step={5}
                      onSet={(v) => act("propedit_lobby_env", { field: "minute", value: (v + 60) % 60 }, false)}
                    />
                    <select
                      className="pe__pick"
                      value={lobby.env.weather}
                      onChange={(e) => act("propedit_lobby_env", { field: "weather", value: e.target.value })}
                    >
                      {list(lobby.weathers).map((weather) => (
                        <option key={weather} value={weather}>
                          {weather}
                        </option>
                      ))}
                    </select>
                  </>
                )}

                <div className="pe__tabs">
                  <span className="pe__cap">Background players · {list(lobby.slots).length}</span>
                  <span className="pe__spacer" />
                  <button className="pe__mini" title="Add" onMouseEnter={hover} onClick={() => act("propedit_lobby_add_slot")}>
                    +
                  </button>
                </div>
                {list(lobby.slots).map((slot) => (
                  <div key={slot.index} className="pe__item">
                    <button
                      className={`pe__item-go${handle?.handle === `slot:${slot.index}` ? " pe__item-go--on" : ""}`}
                      onMouseEnter={hover}
                      onClick={() => act("propedit_lobby_select", { id: `slot:${slot.index}` })}
                    >
                      <span className="pe__kind pe__kind--ped">{slot.index}</span>
                      <span className="pe__item-name">{slot.scenario || "No animation"}</span>
                    </button>
                    <button
                      className="pe__mini pe__mini--bad"
                      title="Remove"
                      onMouseEnter={hover}
                      onClick={() => act("propedit_lobby_remove_slot", { index: slot.index })}
                    >
                      ×
                    </button>
                  </div>
                ))}
              </>
            )}
          </div>
        )}

        {list(d.hidden).length > 0 && (
          <div className="pe__block">
            <span className="pe__cap">Removed world · {list(d.hidden).length}</span>
            <div className="pe__scroll pe__scroll--short">
              {list(d.hidden).map((entry) => (
                <div key={entry.index} className="pe__item">
                  <span className="pe__item-go pe__item-go--flat">{entry.model}</span>
                  <button
                    className="pe__mini"
                    title="Restore"
                    onMouseEnter={hover}
                    onClick={() => act("propedit_restore", { index: entry.index })}
                  >
                    ↺
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="pe__right">
        {handle ? (
          <>
            <div className="pe__block">
              <div className="pe__selhead">
                <span className="pe__kind">{handle.kind.toUpperCase()}</span>
                <span className="pe__sel-name">{handle.label}</span>
              </div>
              <div className="pe__row">
                <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_grab")}>
                  Move
                </button>
                {!handle.camKey && (
                  <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_gizmo")}>
                    Gizmo
                  </button>
                )}
                {handle.camKey && (
                  <button
                    className={`pe__btn${live.preview === handle.camKey ? " pe__btn--go" : ""}`}
                    onMouseEnter={hover}
                    onClick={() => act("propedit_lobby_preview", { key: handle.camKey })}
                  >
                    {live.preview === handle.camKey ? "Exit preview" : "Preview"}
                  </button>
                )}
                <button className="pe__btn pe__btn--bad" onMouseEnter={hover} onClick={() => act("propedit_delete")}>
                  Clear
                </button>
              </div>
              <span className="pe__hintline">
                {handle.kind === "cam" || handle.kind === "look"
                  ? "Drag it in the world · wheel pushes it away"
                  : handle.kind === "weapon"
                    ? "Orange line · gunsmith camera spot"
                    : "Drag it in the world · it snaps to the ground"}
              </span>
            </div>

            {handle.kind !== "cam" && handle.kind !== "look" && (
              <div className="pe__block">
                <span className="pe__cap">Placement</span>
                <Step
                  label="Height cm"
                  value={Math.round(handle.z * 100)}
                  min={-100000}
                  max={100000}
                  step={5}
                  onSet={(v) => act("propedit_lobby_pose", { field: "z", value: v / 100 }, false)}
                />
                {handle.turnable && (
                  <Step
                    label="Heading"
                    value={Math.round(handle.h ?? 0)}
                    min={-360}
                    max={720}
                    step={5}
                    onSet={(v) => act("propedit_lobby_pose", { field: "h", value: (v + 360) % 360 }, false)}
                  />
                )}
              </div>
            )}

            {handle.posed && (
              <div className="pe__block">
                <span className="pe__cap">Pose</span>
                <select
                  className="pe__pick"
                  value={handle.scenario}
                  onChange={(e) => act("propedit_lobby_pose", { field: "scenario", value: e.target.value })}
                >
                  <option value="">No scenario</option>
                  {list(handle.scenarios).map((scenario) => (
                    <option key={scenario} value={scenario}>
                      {scenario}
                    </option>
                  ))}
                </select>
                <div className="pe__fields">
                  <label className="pe__field pe__field--wide">
                    <span>Anim dict</span>
                    <input
                      className="pe__num"
                      key={`hdict${handle.handle}${handle.dict}`}
                      defaultValue={handle.dict}
                      onBlur={(e) => act("propedit_lobby_pose", { field: "dict", value: e.target.value }, false)}
                    />
                  </label>
                  <label className="pe__field pe__field--wide">
                    <span>Anim name</span>
                    <input
                      className="pe__num"
                      key={`hanim${handle.handle}${handle.anim}`}
                      defaultValue={handle.anim}
                      onBlur={(e) => act("propedit_lobby_pose", { field: "anim", value: e.target.value }, false)}
                    />
                  </label>
                </div>
              </div>
            )}

            {handle.camKey && (
              <div className="pe__block">
                <span className="pe__cap">Framing</span>
                <Step
                  label="Field of view"
                  value={Math.round(handle.fov ?? 45)}
                  min={5}
                  max={120}
                  onSet={(v) => act("propedit_lobby_cam", { field: "fov", value: v }, false)}
                />
                <Step
                  label="Idle sway"
                  value={Math.round((handle.idle ?? 0) * 10)}
                  min={0}
                  max={30}
                  onSet={(v) => act("propedit_lobby_cam", { field: "idle", value: v / 10 }, false)}
                />
                <span className="pe__hintline">Drag the yellow dot to aim the camera</span>
              </div>
            )}

            {handle.camKey && (
              <div className="pe__block">
                <span className="pe__cap">Depth of field</span>
                <Flag
                  label="Enabled"
                  on={handle.dof === true}
                  onSet={(v) => act("propedit_lobby_cam", { field: "dof", value: v }, false)}
                />
                <Step
                  label="Strength %"
                  value={Math.round((handle.dofStrength ?? 1) * 100)}
                  min={0}
                  max={100}
                  step={5}
                  onSet={(v) => act("propedit_lobby_cam", { field: "dofStrength", value: v / 100 }, false)}
                />
                <Step
                  label="Near cm"
                  value={Math.round((handle.dofNear ?? 0.5) * 100)}
                  min={0}
                  max={5000}
                  step={10}
                  onSet={(v) => act("propedit_lobby_cam", { field: "dofNear", value: v / 100 }, false)}
                />
                <Step
                  label="Far cm"
                  value={Math.round((handle.dofFar ?? 8) * 100)}
                  min={10}
                  max={20000}
                  step={25}
                  onSet={(v) => act("propedit_lobby_cam", { field: "dofFar", value: v / 100 }, false)}
                />
              </div>
            )}
          </>
        ) : !sel ? (
          <div className="pe__block">
            <span className="pe__cap">Selection</span>
            <span className="pe__empty">Click any entity to select</span>
          </div>
        ) : (
          <>
            <div className="pe__block">
              <div className="pe__selhead">
                <span className={`pe__kind pe__kind--${sel.kind}`}>{kindTag[sel.kind]}</span>
                <span className="pe__sel-name">{sel.model}</span>
              </div>
              {!sel.mine && <span className="pe__hintline">World entity · edits capture a copy</span>}
              <div className="pe__row">
                <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_grab")}>
                  Move
                </button>
                <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_gizmo")}>
                  Gizmo
                </button>
                <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_duplicate")}>
                  Duplicate
                </button>
                <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_ground")}>
                  Ground
                </button>
                {sel.mine && !sel.favorite && (
                  <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_fav_selection")}>
                    ★ Save
                  </button>
                )}
                <button className="pe__btn pe__btn--bad" onMouseEnter={hover} onClick={() => act("propedit_delete")}>
                  Delete
                </button>
              </div>
            </div>

            {sel.mine && (
              <div className="pe__block">
                <span className="pe__cap">Transform</span>
                <div className="pe__fields">
                  {(["x", "y", "z"] as const).map((axis) => (
                    <label key={axis} className="pe__field">
                      <span>{axis.toUpperCase()}</span>
                      <input
                        className="pe__num"
                        key={`${axis}${sel.index}${sel[axis]}`}
                        defaultValue={Math.round(sel[axis] * 100) / 100}
                        onBlur={(e) => act("propedit_set", { field: axis, value: e.target.value }, false)}
                      />
                    </label>
                  ))}
                </div>
                <div className="pe__fields">
                  {(["rx", "ry", "rz"] as const).map((axis) => (
                    <label key={axis} className="pe__field">
                      <span>{axis.toUpperCase()}</span>
                      <input
                        className="pe__num"
                        key={`${axis}${sel.index}${sel[axis]}`}
                        defaultValue={Math.round(sel[axis] * 10) / 10}
                        onBlur={(e) => act("propedit_set", { field: axis, value: e.target.value }, false)}
                      />
                    </label>
                  ))}
                </div>
                <div className="pe__row">
                  <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_rotate", { axis: "z", delta: -15 })}>
                    ⟲ ←
                  </button>
                  <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_rotate", { axis: "z", delta: 15 })}>
                    ⟳ →
                  </button>
                  <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_rotate", { axis: "x", delta: 15 })}>
                    Pitch
                  </button>
                  <button className="pe__btn" onMouseEnter={hover} onClick={() => act("propedit_rotate", { axis: "y", delta: 15 })}>
                    Roll
                  </button>
                </div>
              </div>
            )}

            {sel.kind === "ped" && sel.ped && (
              <div className="pe__block">
                <span className="pe__cap">Behaviour</span>
                <select
                  className="pe__pick"
                  value={sel.ped.scenario}
                  onChange={(e) => act("propedit_ped", { field: "scenario", value: e.target.value })}
                >
                  <option value="">No scenario</option>
                  {list(sel.scenarios).map((scenario) => (
                    <option key={scenario} value={scenario}>
                      {scenario}
                    </option>
                  ))}
                </select>
                <div className="pe__fields">
                  <label className="pe__field pe__field--wide">
                    <span>Anim dict</span>
                    <input
                      className="pe__num"
                      key={`dict${sel.index}${sel.ped.dict}`}
                      defaultValue={sel.ped.dict}
                      onBlur={(e) => act("propedit_ped", { field: "dict", value: e.target.value }, false)}
                    />
                  </label>
                  <label className="pe__field pe__field--wide">
                    <span>Anim name</span>
                    <input
                      className="pe__num"
                      key={`anim${sel.index}${sel.ped.anim}`}
                      defaultValue={sel.ped.anim}
                      onBlur={(e) => act("propedit_ped", { field: "anim", value: e.target.value }, false)}
                    />
                  </label>
                </div>
              </div>
            )}

            {sel.kind === "vehicle" && vehicle && (
              <>
                <div className="pe__block">
                  <span className="pe__cap">Paint</span>
                  <Step label="Primary" value={vehicle.primary} min={0} max={159} onSet={(v) => act("propedit_vehicle", { field: "primary", value: v }, false)} />
                  <Step label="Secondary" value={vehicle.secondary} min={0} max={159} onSet={(v) => act("propedit_vehicle", { field: "secondary", value: v }, false)} />
                  <Step label="Pearl" value={vehicle.pearl} min={0} max={159} onSet={(v) => act("propedit_vehicle", { field: "pearl", value: v }, false)} />
                  <Step label="Wheels" value={vehicle.wheelColor} min={0} max={159} onSet={(v) => act("propedit_vehicle", { field: "wheelColor", value: v }, false)} />
                  <Step label="Interior" value={vehicle.interior} min={0} max={159} onSet={(v) => act("propedit_vehicle", { field: "interior", value: v }, false)} />
                  <Step label="Dashboard" value={vehicle.dashboard} min={0} max={159} onSet={(v) => act("propedit_vehicle", { field: "dashboard", value: v }, false)} />
                  <Step label="Dirt" value={vehicle.dirt} min={0} max={15} onSet={(v) => act("propedit_vehicle", { field: "dirt", value: v }, false)} />
                  <Step label="Tint" value={vehicle.windowTint} min={0} max={6} onSet={(v) => act("propedit_vehicle", { field: "windowTint", value: v }, false)} />
                  <Step label="Livery" value={vehicle.livery} min={-1} max={20} onSet={(v) => act("propedit_vehicle", { field: "livery", value: v }, false)} />
                </div>

                <div className="pe__block">
                  <span className="pe__cap">Wheels & plate</span>
                  <select
                    className="pe__pick"
                    value={vehicle.wheelType}
                    onChange={(e) => act("propedit_vehicle", { field: "wheelType", value: Number(e.target.value) })}
                  >
                    {list(sel.wheelTypes).map((name, index) => (
                      <option key={name} value={index}>
                        {name}
                      </option>
                    ))}
                  </select>
                  <div className="pe__fields">
                    <label className="pe__field pe__field--wide">
                      <span>Plate</span>
                      <input
                        className="pe__num"
                        key={`plate${sel.index}${vehicle.plate}`}
                        defaultValue={vehicle.plate}
                        onBlur={(e) => act("propedit_vehicle", { field: "plate", value: e.target.value }, false)}
                      />
                    </label>
                  </div>
                  <Step label="Plate style" value={vehicle.plateStyle} min={0} max={5} onSet={(v) => act("propedit_vehicle", { field: "plateStyle", value: v }, false)} />
                </div>

                {(["neon", "tyreSmoke"] as const).map((group) => (
                  <div key={group} className="pe__block">
                    <span className="pe__cap">{group === "neon" ? "Neon" : "Tyre smoke"}</span>
                    {group === "neon" && (
                      <Flag label="Enabled" on={vehicle.neonOn} onSet={(v) => act("propedit_vehicle", { field: "neonOn", value: v }, false)} />
                    )}
                    <div className="pe__fields">
                      {(["r", "g", "b"] as const).map((channel) => (
                        <label key={channel} className="pe__field">
                          <span>{channel.toUpperCase()}</span>
                          <input
                            className="pe__num"
                            key={`${group}${channel}${vehicle[group][channel]}`}
                            defaultValue={vehicle[group][channel]}
                            onBlur={(e) => act("propedit_rgb", { group, channel, value: e.target.value }, false)}
                          />
                        </label>
                      ))}
                    </div>
                    <span
                      className="pe__swatch"
                      style={{ background: `rgb(${vehicle[group].r},${vehicle[group].g},${vehicle[group].b})` }}
                    />
                  </div>
                ))}

                <div className="pe__block">
                  <span className="pe__cap">Tuning</span>
                  {list(sel.mods).map((mod) => (
                    <Step
                      key={mod.id}
                      label={mod.label}
                      value={mod.value}
                      min={-1}
                      max={mod.count - 1}
                      onSet={(v) => act("propedit_mod", { id: mod.id, value: v }, false)}
                    />
                  ))}
                  {list(sel.mods).length === 0 && <span className="pe__empty">No mod slot</span>}
                </div>

                <div className="pe__block">
                  <span className="pe__cap">Options</span>
                  {list(sel.toggles).map((slot) => (
                    <Flag
                      key={slot.id}
                      label={slot.label}
                      on={slot.on}
                      onSet={(v) => act("propedit_toggle", { list: "toggles", id: slot.id, on: v }, false)}
                    />
                  ))}
                  {list(sel.extras).map((slot) => (
                    <Flag
                      key={`extra${slot.id}`}
                      label={`Extra ${slot.id}`}
                      on={slot.on}
                      onSet={(v) => act("propedit_toggle", { list: "extras", id: slot.id, on: v }, false)}
                    />
                  ))}
                  <Flag label="Bulletproof tyres" on={vehicle.bulletproof} onSet={(v) => act("propedit_vehicle", { field: "bulletproof", value: v }, false)} />
                </div>

                <div className="pe__block">
                  <span className="pe__cap">State</span>
                  <Flag label="Engine running" on={vehicle.engineOn} onSet={(v) => act("propedit_vehicle", { field: "engineOn", value: v }, false)} />
                  <Flag label="Headlights" on={vehicle.lights} onSet={(v) => act("propedit_vehicle", { field: "lights", value: v }, false)} />
                  <Flag label="High beams" on={vehicle.highBeams} onSet={(v) => act("propedit_vehicle", { field: "highBeams", value: v }, false)} />
                  <Flag label="Siren" on={vehicle.siren} onSet={(v) => act("propedit_vehicle", { field: "siren", value: v }, false)} />
                </div>

                <div className="pe__block">
                  <span className="pe__cap">Doors open</span>
                  {list(sel.doors).map((slot) => (
                    <Flag
                      key={`door${slot.id}`}
                      label={slot.label}
                      on={slot.on}
                      onSet={(v) => act("propedit_toggle", { list: "doors", id: slot.id, on: v }, false)}
                    />
                  ))}
                </div>

                <div className="pe__block">
                  <span className="pe__cap">Windows down</span>
                  {list(sel.windows).map((slot) => (
                    <Flag
                      key={`window${slot.id}`}
                      label={slot.label}
                      on={slot.on}
                      onSet={(v) => act("propedit_toggle", { list: "windows", id: slot.id, on: v }, false)}
                    />
                  ))}
                </div>
              </>
            )}
          </>
        )}
      </div>

      <div className="pe__hint">
        {live.preview
          ? "Preview · camera button to exit"
          : live.placing
          ? "Left click to drop · wheel raises · arrows rotate · Escape cancels"
          : "Move keys fly · jump/crouch up-down · sprint boost · right drag look · left click select · drag to move"}
      </div>
    </div>
  );
};

export default PropEditor;
