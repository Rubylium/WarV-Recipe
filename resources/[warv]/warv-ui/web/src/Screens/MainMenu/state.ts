import { createStateObject } from "../../Utils";
import { MenuData } from "../../types";

export const menuData = createStateObject<MenuData>("SET_MENU_DATA", {
  player: {
    name: "OPERATOR",
    uid: 0,
    level: 1,
    prestige: 0,
    xp: 0,
    xpMax: 1000,
    credit: 0,
    rankIcon: "rank_1",
    callingCard: "",
    emblem: "",
  },
  squad: { isLeader: true, isOpen: false, members: [], invites: [] },
  news: [],
  gamemodes: [],
  banned: { active: false, text: "" },
  permissions: { clothingCreator: false, mapEditor: false },
});
