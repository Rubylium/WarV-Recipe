import { createStateObject } from "../../Utils";
import { AttachEditorData, AttachMarker } from "../../types";

export const attachEditor = createStateObject<AttachEditorData>("SET_ATTACH_EDITOR", {
  weapon: { label: "", image: "" },
  level: 1,
  maxLevel: 50,
  xpInto: 0,
  xpSpan: 0,
  types: [],
  tints: [],
  tintDirty: false,
  attachments: { used: 0, limit: 6 },
  canEdit: false,
  editing: false,
  stats: {
    isPreview: false,
    damage: { value: 0, referenceValue: 0, bar: 0, referenceBar: 0, delta: 0, tone: "neutral", lowerIsBetter: false },
    recoil: { value: 0, referenceValue: 0, bar: 0, referenceBar: 0, delta: 0, tone: "neutral", lowerIsBetter: true },
    spread: { value: 0, referenceValue: 0, bar: 0, referenceBar: 0, delta: 0, tone: "neutral", lowerIsBetter: true },
    range: { value: 0, referenceValue: 0, bar: 0, referenceBar: 0, delta: 0, tone: "neutral", lowerIsBetter: false },
    fireRate: { value: 0, referenceValue: 0, bar: 0, referenceBar: 0, delta: 0, tone: "neutral", lowerIsBetter: false },
    mobility: { value: 0, referenceValue: 0, bar: 0, referenceBar: 0, delta: 0, tone: "neutral", lowerIsBetter: false },
    clip: { value: 0, referenceValue: 0, delta: 0, tone: "neutral" },
  },
});

export const attachMarkers = createStateObject<AttachMarker[]>("SET_ATTACH_MARKERS", []);
