import { createStateObject } from "../../Utils";
import { SettingsData } from "../../types";

export const settings = createStateObject<SettingsData>("SET_SETTINGS", {
  volumes: [],
  rankup: [],
  music: [],
});
