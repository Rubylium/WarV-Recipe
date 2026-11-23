import { useSelector } from "../..";
import { IMG, hideImg } from "../../images";
import { BrowserServer } from "../../types";
import { act, hover } from "../../ui";
import { LockIcon } from "../../Components/WeaponArt";
import "./index.scss";

const RefreshIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="square">
    <path d="M20 11a8 8 0 0 0-14-4.5L4 9" />
    <path d="M4 5v4h4" />
    <path d="M4 13a8 8 0 0 0 14 4.5L20 15" />
    <path d="M20 19v-4h-4" />
  </svg>
);
const JoinIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="square">
    <path d="M5 12h13M13 6l6 6-6 6" />
  </svg>
);

const pingColor = (p: number) => (p < 60 ? "#5ad16a" : p < 120 ? "#f2b13a" : "#e5484d");
const pingBars = (p: number) => (p < 60 ? 3 : p < 120 ? 2 : 1);

const ServerRow = ({ s }: { s: BrowserServer }) => {
  const fill = s.maxPlayers > 0 ? Math.min(100, (s.players / s.maxPlayers) * 100) : 0;
  const bars = pingBars(s.ping);
  return (
    <button
      className="sb__row"
      onMouseEnter={hover}
      onClick={() => act("browser_join", { id: s.id })}
    >
      <span className="sb__thumb">
        <img src={IMG(`gamemode/icons/${s.sprite}.png`)} alt="" draggable={false} onError={hideImg} />
      </span>

      <span className="sb__main">
        <span className="sb__title-row">
          <span className={`sb__badge${s.official ? " sb__badge--official" : " sb__badge--private"}`}>
            {!s.official && <LockIcon />}
            {s.official ? "Official" : "Private"}
          </span>
          <span className="sb__name">
            {s.official ? "WARV Public Server" : "Private WARV Server"}
          </span>
        </span>
        <span className="sb__sub">
          {s.gamemode}
          <span className="sb__dotsep" />
          {s.voting ? "Voting for next map" : s.map || "Unknown map"}
        </span>
      </span>

      <span className="sb__players">
        <span className="sb__players-count">
          {s.players}
          <b>/{s.maxPlayers}</b>
        </span>
        <span className="sb__bar">
          <span className="sb__bar-fill" style={{ width: `${fill}%` }} />
        </span>
      </span>

      <span className="sb__ping" style={{ color: pingColor(s.ping) }}>
        <span className="sb__ping-bars">
          {[0, 1, 2].map((b) => (
            <i key={b} className={`sb__ping-bar${b < bars ? " sb__ping-bar--on" : ""}`} style={{ height: `${(b + 1) * 33}%` }} />
          ))}
        </span>
        <span className="sb__ping-ms">{s.ping}ms</span>
      </span>

      <span className="sb__join">
        <span>Join</span>
        <JoinIcon />
      </span>
    </button>
  );
};

const ServerBrowser = () => {
  const data = useSelector((s) => s.serverBrowser);
  const servers = data.servers;

  return (
    <div className="sb">
      <div className="sb__panel">
        <div className="sb__bar-head">
          <span className="sb__count">
            {servers.length} {servers.length === 1 ? "Server" : "Servers"} Available
          </span>
          <button className="sb__refresh" onMouseEnter={hover} onClick={() => act("browser_refresh")}>
            <RefreshIcon />
            <span>Refresh</span>
          </button>
        </div>

        {data.error && (
          <div className="sb__error">
            <span>{data.error}</span>
            <button className="sb__error-x" onMouseEnter={hover} onClick={() => act("browser_dismiss_error")}>
              Dismiss
            </button>
          </div>
        )}

        <div className="sb__list">
          {servers.length === 0 ? (
            <div className="sb__empty">
              <span className="sb__empty-title">No servers found</span>
              <span className="sb__empty-sub">Hit refresh</span>
            </div>
          ) : (
            servers.map((s) => <ServerRow key={s.id} s={s} />)
          )}
        </div>
      </div>
    </div>
  );
};

export default ServerBrowser;
