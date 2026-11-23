import { ReactNode } from "react";
import { Screen } from "../types";
import { useSelector } from "..";
import TopBar, { TopBarTab } from "./TopBar";
import SubHeader from "./SubHeader";
import "./LobbyShell.scss";

const subHeaders: Partial<Record<Screen, { title: string; back: string }>> = {
  gamemode_select: { title: "Find a Match", back: "back_to_lobby" },
  server_browser: { title: "Server Browser", back: "back_to_lobby" },
  class_editor: { title: "Class Editor", back: "class_back" },
  weapon_picker: { title: "Select Weapon", back: "weapon_picker_back" },
  killstreak_editor: { title: "Scorestreaks", back: "ks_back" },
  card_select: { title: "Calling Cards", back: "select_back" },
  emblem_select: { title: "Emblems", back: "select_back" },
};

const noNavTabs: Screen[] = ["class_editor", "weapon_picker", "killstreak_editor"];

const baseTabs: TopBarTab[] = [
  { id: "lobby", label: "Lobby" },
  { id: "barracks", label: "Barracks" },
  { id: "leaderboard", label: "Leaderboard" },
  { id: "settings", label: "Settings" },
];

const LobbyShell = ({ screen, children }: { screen: Screen; children: ReactNode }) => {
  const perms = useSelector((state) => state.menuData.permissions);
  const transparent = screen === "clothing_creator";
  const tabs: TopBarTab[] = [...baseTabs];
  if (perms.clothingCreator) tabs.push({ id: "clothing_creator", label: "Cloth Creator", tag: "DEV" });
  if (perms.mapEditor) tabs.push({ id: "map_editor", label: "Map Editor", tag: "DEV" });
  const activeTab =
    screen === "menu" || screen === "gamemode_select" || screen === "server_browser"
      ? "lobby"
      : screen === "settings"
      ? "settings"
      : screen === "leaderboard"
      ? "leaderboard"
      : screen === "clothing_creator"
      ? "clothing_creator"
      : "barracks";
  const sub = subHeaders[screen];

  return (
    <div className={`shell${screen === "menu" ? " shell--menu" : ""}`}>
      {!transparent && <div className="shell__vignette" />}

      {!transparent && <TopBar active={activeTab} tabs={noNavTabs.includes(screen) ? [] : tabs} />}

      {sub && <SubHeader title={sub.title} back={sub.back} />}

      <div className="shell__content" key={screen}>
        {children}
      </div>
    </div>
  );
};

export default LobbyShell;
