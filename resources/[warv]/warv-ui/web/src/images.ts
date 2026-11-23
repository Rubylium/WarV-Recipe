import { SyntheticEvent } from "react";

export const IMG = (path: string): string =>
  `${process.env.PUBLIC_URL}/assets/images/${path}`;

export const hideImg = (e: SyntheticEvent<HTMLImageElement>) => (e.currentTarget.style.visibility = "hidden");
