import Nui from "./FiveM";

export const uiSound = (name: string) => Nui.post("UI_SOUND", { name });

export const hover = (name?: unknown) => uiSound(typeof name === "string" ? name : "hover");

export const act = (action: string, extra: object = {}, sound: string | false = "select") => {
  if (sound) uiSound(sound);
  Nui.post("MENU_ACTION", { action, ...extra });
};

export const actSilent = (action: string, extra: object = {}) =>
  Nui.post("MENU_ACTION", { action, ...extra });

export const nf = (n: number) => new Intl.NumberFormat("en-US").format(Math.floor(n || 0));
