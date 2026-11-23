import { createStateObject } from "../../Utils";
import { PropEditorData, PropEditorLive } from "../../types";

export const propEditor = createStateObject<PropEditorData>("SET_PROP_EDITOR", {
  mode: "pick",
  mapName: "",
  cards: [],
  props: [],
  hidden: [],
  history: [],
  favorites: [],
  selection: null,
  lobby: null,
  placing: false,
  dirty: false,
  speed: 14,
  status: "",
});

export const propEditorLive = createStateObject<PropEditorLive>("SET_PROP_EDITOR_LIVE", {
  selection: null,
  handle: null,
  placing: false,
  preview: "",
  gizmo: false,
  looking: false,
  speed: 14,
  dirty: false,
});
