import { createStateObject } from "../Utils";
import { Screen } from "../types";

export const screen = createStateObject<Screen>("SET_SCREEN", "none");
