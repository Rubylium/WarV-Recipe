import { ReactNode, useEffect, useState } from "react";
import { useSelector } from "../..";
import PlayerCard from "../../Components/PlayerCard";
import FriendsPanel from "../../Components/FriendsPanel";
import Challenges from "../../Components/Challenges";
import SquadPanel from "../../Components/SquadPanel";
import Sprite from "../../Components/Sprite";
import { IMG } from "../../images";
import { MenuData } from "../../types";
import { act, hover } from "../../ui";
import "./index.scss";
import "./quickPlay.scss";
import "./rightRail.scss";

const BrowserIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="square">
    <line x1="3" y1="6" x2="15" y2="6" />
    <line x1="3" y1="11" x2="11" y2="11" />
    <line x1="3" y1="16" x2="14" y2="16" />
    <circle cx="18" cy="15.5" r="2.6" />
    <line x1="18" y1="11.6" x2="18" y2="12.9" />
    <line x1="18" y1="18.1" x2="18" y2="19.4" />
  </svg>
);
const ClassIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="square">
    <path d="M4 20v-4L15 5l4 4L8 20z" />
    <line x1="13.5" y1="6.5" x2="17.5" y2="10.5" />
  </svg>
);
const CustomIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="square">
    <rect x="4" y="5" width="16" height="14" />
    <line x1="12" y1="9" x2="12" y2="15" />
    <line x1="9" y1="12" x2="15" y2="12" />
  </svg>
);
const FeatureTile = () => (
  <button className="mm__btn mm__btn--feature" onMouseEnter={hover} onClick={() => act("play")}>
    <div className="mm__btn-photo-wrap">
      <div
        className="mm__btn-photo"
        style={{ backgroundImage: `url(${IMG("menu/find_match_background.png")})` }}
      />
    </div>
    <div className="mm__btn-scrim" />
    <div className="mm__btn-body">
      <span className="mm__btn-title">Find a Match</span>
      <span className="mm__btn-sub">Matchmaking with other players</span>
    </div>
    <Sprite src={IMG("sprites/arrow_right.png")} columns={8} rows={8} fps={18} className="mm__btn-arrow" />
  </button>
);

interface IconTileProps {
  icon: ReactNode;
  title: string;
  sub: string;
  action: string;
  className: string;
  disabled?: boolean;
}
const IconTile = ({ icon, title, sub, action, className, disabled }: IconTileProps) => (
  <button
    className={`mm__btn mm__btn--icon ${className}${disabled ? " mm__btn--disabled" : ""}`}
    onMouseEnter={() => !disabled && hover()}
    onClick={() => !disabled && act(action)}
  >
    <div className="mm__btn-ico">{icon}</div>
    <div className="mm__btn-body">
      <span className="mm__btn-title">{title}</span>
      <span className="mm__btn-sub">{sub}</span>
    </div>
  </button>
);

const Tiles = () => (
  <div className="mm__tiles">
    <div className="mm__row mm__row--top">
      <FeatureTile />
      <IconTile icon={<BrowserIcon />} title="Browser" sub="Server browser" action="browser" className="mm__btn--browser" />
    </div>
    <div className="mm__row mm__row--bottom">
      <IconTile icon={<ClassIcon />} title="Custom Class" sub="Create your own class" action="classes" className="mm__btn--class" />
      <IconTile icon={<CustomIcon />} title="Custom Game" sub="Create your own lobby" action="custom" className="mm__btn--custom" disabled />
    </div>
  </div>
);

const useRotate = (pages: number, ms: number) => {
  const [page, setPage] = useState(0);

  useEffect(() => {
    setPage(0);
    if (pages <= 1) return;
    const t = setInterval(() => setPage((p) => (p + 1) % pages), ms);
    return () => clearInterval(t);
  }, [pages, ms]);

  return page;
};

const patchPerPage = 5;
const PatchNotes = ({ news }: { news: MenuData["news"] }) => {
  const pages = Math.max(1, Math.ceil(news.length / patchPerPage));
  const page = useRotate(pages, 6500);

  const slice = news.slice(page * patchPerPage, page * patchPerPage + patchPerPage);

  return (
    <aside className="mm__patch">
      <div className="mm__patch-head">
        <span className="mm__patch-title">Patch Notes</span>
        <span className="mm__patch-tag">Latest</span>
      </div>
      <div className="mm__patch-list" key={page}>
        {slice.map((n, i) => (
          <div key={i} className="mm__patch-line">
            {n.text}
          </div>
        ))}
      </div>
      {pages > 1 && (
        <div className="mm__patch-dots">
          {Array.from({ length: pages }).map((_, i) => (
            <span key={i} className={`mm__patch-dot${i === page ? " mm__patch-dot--on" : ""}`} />
          ))}
        </div>
      )}
    </aside>
  );
};

const PlayArrow = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="square">
    <path d="M5 12h13M13 6l6 6-6 6" />
  </svg>
);

const quickVisible = 3;
const quickRotateMs = 4500;

const QuickPlay = ({ modes }: { modes: MenuData["gamemodes"] }) => {
  const pages = Math.max(1, Math.ceil(modes.length / quickVisible));
  const page = useRotate(pages, quickRotateMs);

  if (modes.length === 0) return null;

  const slice = modes.slice(page * quickVisible, page * quickVisible + quickVisible);

  return (
    <section className="mm__quick">
      <div className="mm__quick-head">
        <span className="mm__quick-title">Quick Play</span>
        <span className="mm__quick-line" />
        {pages > 1 && (
          <div className="mm__quick-dots">
            {Array.from({ length: pages }).map((_, i) => (
              <span key={i} className={`mm__quick-nav${i === page ? " mm__quick-nav--on" : ""}`} />
            ))}
          </div>
        )}
      </div>
      <div className="mm__quick-row" key={page}>
        {slice.map((m) => (
          <button
            key={m.name}
            className="mm__quick-card"
            onMouseEnter={hover}
            onClick={() => act("quickplay", { name: m.name })}
          >
            <span className="mm__quick-icon-box">
              <img
                className="mm__quick-icon"
                src={IMG(`gamemode/icons/${m.sprite}.png`)}
                alt=""
                draggable={false}
                onError={(e) => (e.currentTarget.style.visibility = "hidden")}
              />
            </span>
            <span className="mm__quick-text">
              <span className="mm__quick-label">{m.label}</span>
              <span className="mm__quick-meta">
                <span className="mm__quick-dot" />
                {m.players} online
              </span>
            </span>
            <span className="mm__quick-go">
              <PlayArrow />
            </span>
          </button>
        ))}
      </div>
    </section>
  );
};

const MainMenu = () => {
  const data = useSelector((s) => s.menuData);
  const [squadOpen, setSquadOpen] = useState(false);
  const [friendsOpen, setFriendsOpen] = useState(false);

  return (
    <>
      {data.banned.active && <div className="mm__ban">{data.banned.text || "Banned"}</div>}

      <main className="mm__main">
        <Tiles />
      </main>

      <QuickPlay modes={data.gamemodes} />

      <aside className="mm__right">
        <PlayerCard p={data.player} />
        <SquadPanel squad={data.squad} onOpenChange={setSquadOpen} />
        <FriendsPanel onOpenChange={setFriendsOpen} />
        <PatchNotes news={data.news} />
        <div className="mm__challenges" hidden={squadOpen || friendsOpen}>
          <Challenges />
        </div>
      </aside>
    </>
  );
};

export default MainMenu;
