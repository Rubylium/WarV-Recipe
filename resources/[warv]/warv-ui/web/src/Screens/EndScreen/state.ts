import { createStateObject } from "../../Utils";
import { EndScreenData } from "../../types";

export const endScreen = createStateObject<EndScreenData>("SET_ENDSCREEN", {
  result: "victory",
  subtitle: "",
  teamMode: true,
  left: { name: "", logo: "", score: 0, color: "blue" },
  right: { name: "", logo: "", score: 0, color: "red" },
  board: [],
});
