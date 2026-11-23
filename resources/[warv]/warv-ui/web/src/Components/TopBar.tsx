import { ReactNode } from "react";
import { act, hover } from "../ui";
import "./TopBar.scss";

export interface TopBarTab {
  id: string;
  label: string;
  action?: string;
  tag?: string;
}

const defaultSub: Record<string, string> = {
  lobby: "Main Menu",
  barracks: "Barracks",
  leaderboard: "Leaderboard",
  settings: "Settings",
};

interface TopBarProps {
  active?: string;
  subtitle?: ReactNode;
  tabs: TopBarTab[];
  right?: ReactNode;
}

const TopBar = ({ active, subtitle, tabs, right }: TopBarProps) => {
  const sub = subtitle ?? defaultSub[active ?? ""] ?? "Main Menu";
  return (
    <>
      <div className="topbar__scrim" />
      <header className="topbar">
      <div className="topbar__brand">
        <div className="topbar__title">
          WAR<span>V</span>
        </div>
        <div className="topbar__sub">{sub}</div>
      </div>
      <div className="topbar__tabs">
        {tabs.map((t) => (
          <button
            key={t.id}
            className={`topbar__tab${t.id === active ? " topbar__tab--active" : ""}`}
            onMouseEnter={hover}
            onClick={() => t.id !== active && act(t.action ?? `tab_${t.id}`, {}, "tab")}
          >
            {t.label}
            {t.tag && <span className="topbar__tag">{t.tag}</span>}
          </button>
        ))}
      </div>
      {right && <div className="topbar__right">{right}</div>}
      </header>
    </>
  );
};

export default TopBar;
