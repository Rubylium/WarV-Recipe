import { createStateObject } from "../../Utils";
import { KillstreakEditorData } from "../../types";

export const killstreakEditor = createStateObject<KillstreakEditorData>(
  "SET_KILLSTREAK_EDITOR",
  { slots: [], streaks: [] }
);
