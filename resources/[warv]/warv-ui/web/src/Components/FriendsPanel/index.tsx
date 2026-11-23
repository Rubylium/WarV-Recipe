import { useLayoutEffect, useRef, useState } from "react";
import { useSelector } from "../..";
import { act, hover, uiSound } from "../../ui";
import { FriendEntry, FriendState } from "../../types";
import "./index.scss";

const stateLabel: Record<FriendState, string> = {
  match: "In match",
  queue: "In queue",
  lobby: "In lobby",
  offline: "Offline",
};

const Marquee = ({ text }: { text: string }) => {
  const ref = useRef<HTMLSpanElement>(null);
  const [roll, setRoll] = useState(false);

  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.classList.remove("fr__ticker--roll");
    setRoll(el.scrollWidth > el.clientWidth + 1);
  }, [text]);

  return (
    <span className="fr__ticker-clip">
      <span ref={ref} className={`fr__ticker${roll ? " fr__ticker--roll" : ""}`} data-text={text}>
        {text}
      </span>
    </span>
  );
};

const Row = ({ f, tab }: { f: FriendEntry; tab: string }) => (
  <div className={`fr__row fr__row--${f.state}`}>
    <span className="fr__meta">
      <span className="fr__name">{f.name}</span>
      <span className="fr__status">
        <i className={`fr__dot fr__dot--${f.state}`} />
        <Marquee text={f.detail || stateLabel[f.state]} />
      </span>
    </span>

    <span className="fr__acts">
      {tab === "friends" && (
        <>
          {f.joinable && (
            <button className="fr__act fr__act--go" onMouseEnter={hover} onClick={() => act("friend_join", { id: f.uid })}>
              Join
            </button>
          )}
          {f.state !== "offline" && (
            <button className="fr__act" onMouseEnter={hover} onClick={() => act("friend_invite", { id: f.uid })}>
              Invite
            </button>
          )}
          <button className="fr__act fr__act--warn" onMouseEnter={hover} onClick={() => act("friend_remove", { id: f.uid })}>
            Remove
          </button>
          <button className="fr__act fr__act--warn" onMouseEnter={hover} onClick={() => act("friend_block", { id: f.uid })}>
            Block
          </button>
        </>
      )}

      {tab === "requests" && (
        <>
          <button className="fr__act fr__act--go" onMouseEnter={hover} onClick={() => act("friend_accept", { id: f.uid })}>
            Accept
          </button>
          <button className="fr__act fr__act--warn" onMouseEnter={hover} onClick={() => act("friend_remove", { id: f.uid })}>
            Decline
          </button>
          <button className="fr__act fr__act--warn" onMouseEnter={hover} onClick={() => act("friend_block", { id: f.uid })}>
            Block
          </button>
        </>
      )}

      {tab === "blocked" && (
        <button className="fr__act" onMouseEnter={hover} onClick={() => act("friend_unblock", { id: f.uid })}>
          Unblock
        </button>
      )}
    </span>
  </div>
);

const FriendsPanel = ({ onOpenChange }: { onOpenChange?: (open: boolean) => void }) => {
  const data = useSelector((s) => s.friends);
  const [open, setOpen] = useState(false);
  useLayoutEffect(() => {
    onOpenChange?.(open);
  }, [open, onOpenChange]);

  const [tab, setTab] = useState("friends");
  const [adding, setAdding] = useState(false);
  const [val, setVal] = useState("");

  const { friends, incoming, outgoing, blocked } = data;
  const online = friends.filter((f) => f.state !== "offline").length;
  const rows = tab === "requests" ? incoming : tab === "blocked" ? blocked : friends;

  const closeAdd = () => {
    setAdding(false);
    setVal("");
  };
  const submitAdd = () => {
    const id = parseInt(val.replace(/\D/g, ""), 10);
    if (!isNaN(id)) act("friend_add", { id });
    closeAdd();
  };

  return (
    <div className={`fr${open ? " fr--open" : ""}`}>
      <button
        className="fr__head"
        onMouseEnter={hover}
        onClick={() => {
          uiSound(open ? "collapse" : "expand");
          setOpen((o) => !o);
        }}
      >
        <span className="fr__title">Friends</span>
        <span className="fr__count">
          {online}/{friends.length}
        </span>
        {incoming.length > 0 && <span className="fr__badge">{incoming.length}</span>}
        <span className={`fr__caret${open ? " fr__caret--open" : ""}`} />
      </button>

      <div className="fr__wrap">
        <div className="fr__clip">
          <div className="fr__body">
            <div className="fr__tabs">
              {["friends", "requests", "blocked"].map((t) => (
                <button
                  key={t}
                  className={`fr__tab${t === tab ? " fr__tab--active" : ""}`}
                  onMouseEnter={hover}
                  onClick={() => {
                    uiSound("tab");
                    setTab(t);
                  }}
                >
                  {t === "requests" && incoming.length > 0 ? `Requests (${incoming.length})` : t}
                </button>
              ))}
            </div>

            {rows.length === 0 ? (
              <div className="fr__empty">
                {tab === "friends" ? "No friends yet" : tab === "requests" ? "No pending requests" : "Nobody blocked"}
              </div>
            ) : (
              <div className="fr__list">
                {rows.map((f) => (
                  <Row key={f.uid} f={f} tab={tab} />
                ))}
              </div>
            )}

            {tab === "friends" && (
              <>
                {outgoing.length > 0 && (
                  <div className="fr__pending">{outgoing.length} request(s) sent</div>
                )}

                {adding ? (
                  <div className="fr__addrow">
                    <input
                      className="fr__input"
                      autoFocus
                      inputMode="numeric"
                      maxLength={6}
                      placeholder="Player ID"
                      value={val}
                      onChange={(e) => setVal(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") submitAdd();
                        else if (e.key === "Escape") closeAdd();
                      }}
                    />
                    <button className="fr__send" onMouseEnter={hover} onClick={submitAdd}>
                      Add
                    </button>
                  </div>
                ) : (
                  <button
                    className="fr__add"
                    onMouseEnter={hover}
                    onClick={() => {
                      uiSound("select");
                      setAdding(true);
                    }}
                  >
                    + Add friend
                  </button>
                )}

                <button
                  className={`fr__hide${data.hidden ? " fr__hide--on" : ""}`}
                  onMouseEnter={hover}
                  onClick={() => act("friend_hide", { hidden: !data.hidden })}
                >
                  <span className={`fr__check${data.hidden ? " fr__check--on" : ""}`} />
                  Appear offline
                </button>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default FriendsPanel;
