import { useEffect, useState } from "react";
import { useSelector } from "../..";
import TopBar from "../../Components/TopBar";
import RankBadge from "../../Components/RankBadge";
import CallingCard from "../../Components/CallingCard";
import Emblem from "../../Components/Emblem";
import Spinner from "../../Components/Spinner";
import Sprite from "../../Components/Sprite";
import { IMG, hideImg } from "../../images";
import { LobbyPlayer, LobbyWaitData, MapVote } from "../../types";
import { act, hover, nf } from "../../ui";
import "./index.scss";

const fxColumns = 6;
const fxRows = 7;
const fxFps = 40;
const fxDuration = ((fxColumns * fxRows) / fxFps) * 1000;

const burstDelay = (streak: number) => {
  if (streak > 20) return 2000;
  if (streak > 15) return 3000;
  if (streak > 10) return 4000;
  return 5000;
};

const StreakFx = ({ streak }: { streak: number }) => {
  const looping = streak > 25;
  const [burst, setBurst] = useState(0);
  const [visible, setVisible] = useState(looping);

  useEffect(() => {
    if (looping) {
      setVisible(true);
      return;
    }

    setVisible(false);
    let hide = 0;
    const id = window.setInterval(() => {
      setBurst((n) => n + 1);
      setVisible(true);
      hide = window.setTimeout(() => setVisible(false), fxDuration);
    }, burstDelay(streak));

    return () => {
      window.clearInterval(id);
      window.clearTimeout(hide);
    };
  }, [streak, looping]);

  if (!visible) return null;

  return (
    <Sprite
      key={looping ? "loop" : burst}
      className="lw__pstreak-fx"
      src={IMG("sprites/streak_fx.png")}
      columns={fxColumns}
      rows={fxRows}
      fps={fxFps}
      loop={looping}
    />
  );
};

const LeaveIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="square">
    <path d="M14 4h4v16h-4" />
    <path d="M10 8l-4 4 4 4" />
    <line x1="6" y1="12" x2="15" y2="12" />
  </svg>
);
const ShuffleIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="square">
    <path d="M4 7h4l8 10h4" />
    <path d="M4 17h4l3-3.5" />
    <path d="M13.5 8L16 7l0 0h4" />
    <path d="M18 4l3 3-3 3" />
    <path d="M18 14l3 3-3 3" />
  </svg>
);

type Peek = { slot: number; rect: DOMRect };

const peekHeight = 10;

const Stat = ({ label, value, hot }: { label: string; value: string; hot?: boolean }) => (
  <div className={`lw__peek-stat${hot ? " lw__peek-stat--hot" : ""}`}>
    <span className="lw__peek-stat-v">{value}</span>
    <span className="lw__peek-stat-l">{label}</span>
  </div>
);

const PlayerProfile = ({ p, rect, ranked }: { p: LobbyPlayer; rect: DOMRect; ranked: boolean }) => {
  const gap = window.innerHeight * 0.012;
  const above = rect.top - (window.innerHeight * peekHeight) / 100 - gap;
  const top = above > window.innerHeight * 0.13 ? above : rect.bottom + gap;

  return (
    <div className="lw__peek" style={{ top, right: window.innerWidth - rect.right }}>
      <CallingCard sprite={p.callingCard} className="lw__peek-cc" />
      <span className="lw__peek-scrim" />
      <Emblem sprite={p.emblem} className="lw__peek-emblem" />

      <div className="lw__peek-head">
        <RankBadge icon={p.rankIcon} prestige={p.prestige} className="lw__peek-rank" />
        <div className="lw__peek-id">
          <span className="lw__peek-name">
            {p.name}
            <i>#{p.uid}</i>
          </span>
          <span className="lw__peek-sub">
            {p.prestige > 0 && <b>P{p.prestige}</b>}
            LVL {p.level}
          </span>
        </div>
        <span className="lw__peek-tags">
          {p.squad && <i>Squad</i>}
          {p.voted && <i>Voted</i>}
          {p.muted && <i className="lw__peek-tag--muted">Muted</i>}
        </span>
        {ranked && p.rankingIcon && (
          <div className="lw__peek-div">
            <img src={IMG(`menu/divisions/${p.rankingIcon}.png`)} alt="" draggable={false} onError={hideImg} />
            <span>{p.ranking}</span>
          </div>
        )}
      </div>

      <div className="lw__peek-stats">
        <Stat label="K/D" value={p.kd} />
        <Stat label="Kills" value={nf(p.kills)} />
        <Stat label="W/L" value={p.wl} />
        <Stat label="Wins" value={nf(p.wins)} />
        <Stat label="Streak" value={`${p.winStreak}`} hot={p.winStreak >= 3} />
        <Stat label="Best" value={`${p.bestStreak}`} />
      </div>
    </div>
  );
};

const PlayerRow = ({ p, ranked, onPeek }: { p: LobbyPlayer; ranked: boolean; onPeek: (v: Peek) => void }) => {
  if (p.empty) {
    return (
      <div className="lw__prow lw__prow--empty">
        <Spinner className="lw__spin" offset={(p.slot * 13) % 45} />
        <span className="lw__searching">Looking for players</span>
      </div>
    );
  }
  return (
    <button
      className={`lw__prow${p.self ? " lw__prow--self" : ""}`}
      onMouseEnter={(e) => {
        hover();
        onPeek({ slot: p.slot, rect: e.currentTarget.getBoundingClientRect() });
      }}
      onClick={() => act("mute_player", { id: p.id })}
    >
      <RankBadge icon={p.rankIcon} prestige={p.prestige} className="lw__prank" />
      <span className="lw__plevel">{p.level}</span>
      <span className="lw__pname">
        {p.name}
        <span className="lw__puid">#{p.uid}</span>
      </span>
      {p.winStreak >= 3 && (
        <span className="lw__pstreak">
          {p.winStreak > 5 && <StreakFx streak={p.winStreak} />}
          <span className="lw__pstreak-n">
            {p.winStreak}
            <small>W</small>
          </span>
        </span>
      )}
      {ranked && p.rankingIcon && (
        <img className="lw__pdiv" src={IMG(`menu/divisions/${p.rankingIcon}.png`)} alt="" draggable={false} onError={hideImg} />
      )}
      <span className={`lw__pmic${p.muted ? " lw__pmic--muted" : p.talking ? " lw__pmic--talking" : " lw__pmic--idle"}`}>
        <img
          src={IMG(`menu/voice/${p.muted ? "microphone_muted" : "microphone_talking"}.png`)}
          alt=""
          draggable={false}
        />
      </span>
    </button>
  );
};

const PlayerList = ({ d }: { d: LobbyWaitData }) => {
  const [peek, setPeek] = useState<Peek | null>(null);
  const peeked = peek && d.players.find((p) => p.slot === peek.slot);

  return (
    <aside className="lw__players">
      <div className="lw__players-head">
        <span className="lw__players-title">Players</span>
        <span className="lw__players-count">
          {d.playersInLobby}
          <b>/{d.maxPlayers}</b>
        </span>
      </div>
      <div className="lw__players-list" onMouseLeave={() => setPeek(null)}>
        {d.players.map((p) => (
          <PlayerRow key={p.slot} p={p} ranked={d.ranked} onPeek={setPeek} />
        ))}
      </div>
      {peek && peeked && !peeked.empty && <PlayerProfile p={peeked} rect={peek.rect} ranked={d.ranked} />}
    </aside>
  );
};

const VoteCard = ({ m, choice, voted }: { m: MapVote; choice: number; voted: boolean }) => (
  <button
    className={`lw__vote${voted ? " lw__vote--locked" : ""}${m.image ? "" : " lw__vote--random"}`}
    onMouseEnter={() => !voted && hover()}
    onClick={() => !voted && act("vote_map", { choice })}
    style={m.image ? { backgroundImage: `url(${IMG(`maps/${m.image}.png`)})` } : undefined}
  >
    <span className="lw__vote-grad" />
    {!m.image && (
      <span className="lw__vote-ico">
        <ShuffleIcon />
      </span>
    )}
    <span className="lw__vote-name">{m.name}</span>
    <span className="lw__vote-badge">{m.votes}</span>
  </button>
);

const StatusPanel = ({ d }: { d: LobbyWaitData }) => (
  <section className="lw__status">
    {d.state === "searching" && (
      <div className="lw__box">
        <span className="lw__box-title">
          <Spinner className="lw__spin lw__spin--box" />
          Looking for a game
        </span>
        <span className="lw__box-sub">
          Position {d.queuePlace} of {d.queueTotal} in queue
        </span>
      </div>
    )}

    {d.state === "waiting" && (
      <div className="lw__box">
        <span className="lw__box-title">
          <Spinner className="lw__spin lw__spin--box" offset={22} />
          Waiting for players
        </span>
        <span className="lw__box-sub">Not enough players to start the vote</span>
      </div>
    )}

    {d.state === "voting" && d.vote && (
      <div className="lw__votebox">
        <div className="lw__vote-head">
          <span className="lw__vote-title">Vote for the map</span>
          <span className="lw__vote-timer">{d.timer}s</span>
        </div>
        <div className="lw__votes">
          <VoteCard m={d.vote.map1} choice={1} voted={d.voted} />
          <VoteCard m={d.vote.map2} choice={2} voted={d.voted} />
          <VoteCard m={{ key: "random", name: "Random", image: "", votes: d.vote.randomVotes }} choice={3} voted={d.voted} />
        </div>
        {d.voted && <span className="lw__vote-cast">Your vote is locked in</span>}
      </div>
    )}

    {d.state === "starting" && d.selectedMap && (
      <div
        className="lw__start"
        style={d.selectedMap.image ? { backgroundImage: `url(${IMG(`maps/${d.selectedMap.image}.png`)})` } : undefined}
      >
        <span className="lw__start-grad" />
        <span className="lw__start-status">
          Match starting in <b>{d.timer}</b>
        </span>
        <span className="lw__start-name">{d.selectedMap.name}</span>
      </div>
    )}
  </section>
);

const LobbyWait = () => {
  const d = useSelector((s) => s.lobbyWait);

  const subtitle = (
    <span className="lw__hsub">
      {d.ranked && <span className="lw__ranked-tag">Ranked</span>}
      {d.gamemode || "Matchmaking"}
    </span>
  );
  const tabs = [
    { id: "change_class", label: "Change Class", action: "mm_change_class" },
    { id: "scorestreaks", label: "Scorestreaks", action: "mm_scorestreaks" },
  ];
  const leave = (
    <button className="lw__leave" onMouseEnter={hover} onClick={() => act("leave_matchmaking")}>
      <LeaveIcon />
      <span>Leave</span>
    </button>
  );

  return (
    <>
      <TopBar active="" subtitle={subtitle} tabs={tabs} right={leave} />
      <div className="lw">
        <PlayerList d={d} />
        <StatusPanel d={d} />

        {d.ranked && d.myRankingIcon && (
          <div className="lw__myrank">
            <img src={IMG(`menu/divisions/${d.myRankingIcon}.png`)} alt="" draggable={false} onError={hideImg} />
            <span className="lw__myrank-label">Your Division</span>
          </div>
        )}
      </div>
    </>
  );
};

export default LobbyWait;
