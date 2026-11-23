import { IMG } from "../images";

const animatedCards: Record<string, string> = {
  sunset_stop: "gif",
};

export const callingCardSource = (name: string, animate = true): string =>
  IMG(`menu/callingcards/${name}.${animate ? animatedCards[name] || "png" : "png"}`);
