export { createStateObject } from "./CreateStateObject";

export const pad = (n: number, w: number) =>
  (n < 0 ? "-" : "") + Math.abs(Math.trunc(n)).toString().padStart(w, "0");

export const vh = (px: number): string => `${(100 / 1080) * px}vh`;
