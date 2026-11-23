import { useEffect, useRef, useState } from "react";
import { useSelector } from "../..";
import Nui from "../../FiveM";
import { act, actSilent, hover } from "../../ui";
import "./index.scss";

const list = <T,>(value: T[] | undefined) => (Array.isArray(value) ? value : []);

const MapEditor = () => {
  const d = useSelector((s) => s.mapEditor);
  const panning = useRef(false);
  const orbiting = useRef(false);
  const [naming, setNaming] = useState(false);
  const [newName, setNewName] = useState("");
  const selectedRow = useRef<HTMLDivElement>(null);

  useEffect(() => {
    selectedRow.current?.scrollIntoView({ block: "nearest" });
  }, [d.selection?.index, d.selection?.label]);

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      const drag = panning.current ? "pan" : orbiting.current ? "orbit" : "";
      if (drag) {
        Nui.post("MAP_EDITOR_INPUT", {
          kind: drag,
          dx: e.movementX / window.innerWidth,
          dy: e.movementY / window.innerHeight,
        });
        return;
      }
      Nui.post("MAP_EDITOR_INPUT", {
        kind: "move",
        x: e.clientX / window.innerWidth,
        y: e.clientY / window.innerHeight,
      });
    };
    const onUp = () => {
      panning.current = false;
      orbiting.current = false;
      Nui.post("MAP_EDITOR_INPUT", { kind: "up" });
    };
    const onKey = (e: KeyboardEvent) => {
      if (naming) return;
      const k = e.key.toLowerCase();
      if (e.key === "Delete") actSilent("mapedit_delete");
      else if (k === "q") actSilent("mapedit_rotate", { delta: -15 });
      else if (k === "e") actSilent("mapedit_rotate", { delta: 15 });
      else if (k === "f") actSilent("mapedit_snap");
      else if (e.key === "z" && e.ctrlKey) actSilent("mapedit_undo");
    };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
      window.removeEventListener("keydown", onKey);
    };
  }, [naming]);

  const onViewportDown = (e: React.MouseEvent) => {
    if (e.button === 2) {
      panning.current = true;
      return;
    }
    if (e.button === 1) {
      orbiting.current = true;
      return;
    }
    Nui.post("MAP_EDITOR_INPUT", { kind: "down", shift: e.shiftKey });
  };

  const sel = d.selection;
  const missing = list(d.missing);

  if (d.mode === "pick") {
    return (
      <div className="me me--pick">
        <div className="me__pickhead">
          <div>
            <span className="me__title">Map Editor</span>
            <span className="me__picksub">Select a map · teleports you there</span>
          </div>
          <span className="me__spacer" />
          {naming ? (
            <input
              className="me__input"
              autoFocus
              value={newName}
              placeholder="NEW MAP NAME"
              onChange={(e) => setNewName(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && newName.trim()) {
                  act("mapedit_create", { name: newName.trim() });
                  setNaming(false);
                  setNewName("");
                } else if (e.key === "Escape") setNaming(false);
              }}
            />
          ) : (
            <button className="me__btn me__btn--go" onMouseEnter={hover} onClick={() => setNaming(true)}>
              New map
            </button>
          )}
          <button className="me__btn" onMouseEnter={hover} onClick={() => act("mapedit_close")}>
            Exit
          </button>
        </div>

        <div className="me__grid">
          {list(d.cards).map((card) => (
            <button
              key={card.name}
              className="me__card"
              onMouseEnter={hover}
              onClick={() => act("mapedit_select_map", { name: card.name })}
            >
              <span className="me__card-name">{card.label}</span>
              <span className="me__card-desc">{card.description || "No description"}</span>
              <span className="me__card-meta">
                <span>{card.spawns} spawns</span>
                <span>{card.bounds > 0 ? `${card.bounds}-pt bounds` : "No bounds"}</span>
              </span>
              <span className="me__card-modes">
                {list(card.gamemodes).length > 0 ? (
                  list(card.gamemodes).map((mode) => (
                    <span key={mode} className="me__tag">
                      {mode}
                    </span>
                  ))
                ) : (
                  <span className="me__tag me__tag--none">No gamemode</span>
                )}
              </span>
            </button>
          ))}
        </div>
      </div>
    );
  }

  if (d.hidden) return <div className="me__blackout" />;

  return (
    <div className="me">
      <div
        className="me__viewport"
        onMouseDown={onViewportDown}
        onContextMenu={(e) => e.preventDefault()}
        onWheel={(e) => Nui.post("MAP_EDITOR_INPUT", { kind: "zoom", dy: e.deltaY < 0 ? 1 : -1 })}
      />

      <div className="me__top">
        <span className="me__title">{d.mapName}</span>
        <button className="me__btn" onMouseEnter={hover} onClick={() => act("mapedit_back")}>
          Maps
        </button>
        <span className="me__spacer" />
        {d.dirty && <span className="me__dirty">Unsaved</span>}
        <button
          className="me__btn"
          title="Hide UI 5s"
          onMouseEnter={hover}
          onClick={() => act("mapedit_hide", { seconds: 5 })}
        >
          Screenshot
        </button>
        <button className="me__btn me__btn--go" onMouseEnter={hover} onClick={() => act("mapedit_save")}>
          Save
        </button>
        <button className="me__btn" onMouseEnter={hover} onClick={() => act("mapedit_close")}>
          Exit
        </button>
      </div>

      <div className="me__layers">
        <span className="me__cap">Layers</span>
        {list(d.layers).map((layer) => (
          <div key={layer.id}>
            <button
              className={`me__layer${layer.active ? " me__layer--on" : ""}`}
              onMouseEnter={hover}
              onClick={() => act("mapedit_layer", { id: layer.id })}
            >
              <span className="me__chip" style={{ background: layer.color }} />
              <span className="me__layer-name">{layer.label}</span>
              <span className="me__layer-n">
                {layer.count}
                {layer.max > 0 ? `/${layer.max}` : ""}
              </span>
            </button>

            {layer.active && (
              <div className="me__points">
                {list(d.points).map((point) => (
                  <div
                    key={point.index}
                    ref={sel && sel.index === point.index ? selectedRow : undefined}
                    className={`me__point${sel && sel.index === point.index ? " me__point--on" : ""}`}
                  >
                    <button
                      className="me__point-go"
                      onMouseEnter={hover}
                      onClick={() => act("mapedit_focus", { index: point.index }, "hover")}
                    >
                      <span className="me__point-i">{point.index}</span>
                      <span className="me__point-pos">
                        {point.x} · {point.y}
                        {!point.flat && ` · ${point.z}`}
                        {point.heading >= 0 && ` · ${point.heading}°`}
                      </span>
                    </button>
                    {!point.flat && (
                      <button
                        className="me__mini"
                        title="Drop to ground"
                        onMouseEnter={hover}
                        onClick={() => act("mapedit_snap_ground", { index: point.index })}
                      >
                        ↓
                      </button>
                    )}
                    <button
                      className="me__mini me__mini--bad"
                      title="Delete"
                      onMouseEnter={hover}
                      onClick={() => act("mapedit_delete_at", { index: point.index })}
                    >
                      ×
                    </button>
                  </div>
                ))}
                {list(d.points).length === 0 && <span className="me__empty">Click the ground to place</span>}

                {layer.kind === "polygon" && (
                  <div className="me__zrow">
                    <label className="me__zfield">
                      <span>Ceiling Z</span>
                      <input
                        className="me__zinput"
                        defaultValue={d.boundsMaxZ}
                        placeholder="none"
                        onBlur={(e) => act("mapedit_set_z", { field: "mapBoundsZ", value: e.target.value })}
                      />
                    </label>
                    <label className="me__zfield">
                      <span>Kill floor Z</span>
                      <input
                        className="me__zinput"
                        defaultValue={d.boundsMinZ}
                        placeholder="none"
                        onBlur={(e) => act("mapedit_set_z", { field: "minZ", value: e.target.value })}
                      />
                    </label>
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="me__side">
        <div className="me__block">
          <span className="me__cap">Selection</span>
          {sel ? (
            <>
              <div className="me__sel">
                <span className="me__sel-name">
                  {sel.label} #{sel.index}
                </span>
                <span className="me__sel-pos">
                  {sel.x} · {sel.y} · {sel.z}
                </span>
                {sel.heading >= 0 && <span className="me__sel-pos">Heading {sel.heading}°</span>}
              </div>
              <div className="me__row">
                <button className="me__btn" onMouseEnter={hover} onClick={() => act("mapedit_rotate", { delta: -15 })}>
                  ⟲ Q
                </button>
                <button className="me__btn" onMouseEnter={hover} onClick={() => act("mapedit_rotate", { delta: 15 })}>
                  ⟳ E
                </button>
                <button className="me__btn" onMouseEnter={hover} onClick={() => act("mapedit_snap")}>
                  To me F
                </button>
                <button className="me__btn me__btn--bad" onMouseEnter={hover} onClick={() => act("mapedit_delete")}>
                  Delete
                </button>
              </div>
            </>
          ) : (
            <span className="me__empty">Click a point to select · click ground to place</span>
          )}
        </div>

        <div className="me__block">
          <span className="me__cap">Environment</span>
          <div className="me__zrow">
            <label className="me__zfield">
              <span>Hour</span>
              <input
                className="me__zinput"
                key={`h${d.env.hour}`}
                defaultValue={d.env.hour}
                onBlur={(e) => act("mapedit_set_env", { field: "hour", value: e.target.value })}
              />
            </label>
            <label className="me__zfield">
              <span>Minute</span>
              <input
                className="me__zinput"
                key={`m${d.env.minute}`}
                defaultValue={d.env.minute}
                onBlur={(e) => act("mapedit_set_env", { field: "minute", value: e.target.value })}
              />
            </label>
          </div>
          <select
            className="me__pick"
            value={d.env.weather}
            onChange={(e) => act("mapedit_set_env", { field: "weather", value: e.target.value })}
          >
            {list(d.weathers).map((w) => (
              <option key={w} value={w}>
                {w}
              </option>
            ))}
          </select>
          {!d.env.set && <span className="me__empty">Not set · 12:00 EXTRASUNNY</span>}
        </div>

        <div className="me__block">
          <span className="me__cap">Gamemodes</span>
          {list(d.gamemodes).map((gamemode) => (
            <button
              key={gamemode.id}
              className={`me__gm${gamemode.enabled ? " me__gm--on" : ""}`}
              onMouseEnter={hover}
              onClick={() => act("mapedit_gamemode", { id: gamemode.id })}
            >
              <span className="me__box">{gamemode.enabled ? "×" : ""}</span>
              <span className="me__gm-name">{gamemode.name}</span>
              {!gamemode.implemented && <span className="me__gm-soon">Planned</span>}
            </button>
          ))}
        </div>

        {missing.length > 0 && (
          <div className="me__block me__block--warn">
            <span className="me__cap">Incomplete</span>
            {missing.map((label) => (
              <span key={label} className="me__miss">
                {label}
              </span>
            ))}
          </div>
        )}
      </div>

      <div className="me__hint">
        Left click place / select · drag point to move · right drag pan · middle drag orbit · wheel zoom ({d.height}m)
      </div>
    </div>
  );
};

export default MapEditor;
