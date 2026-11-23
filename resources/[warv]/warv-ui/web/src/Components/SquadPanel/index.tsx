import { useEffect, useLayoutEffect, useState } from "react";
import { MenuData } from "../../types";
import { act, hover, uiSound } from "../../ui";
import RankBadge from "../RankBadge";
import "./index.scss";

type SquadTab = "members" | "invites";

const XIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="square">
    <line x1="6" y1="6" x2="18" y2="18" />
    <line x1="18" y1="6" x2="6" y2="18" />
  </svg>
);

interface SquadPanelProps {
  squad: MenuData["squad"];
  onOpenChange?: (open: boolean) => void;
}

const SquadPanel = ({ squad, onOpenChange }: SquadPanelProps) => {
  const [open, setOpen] = useState(false);
  useLayoutEffect(() => {
    onOpenChange?.(open);
  }, [open, onOpenChange]);

  const [tab, setTab] = useState<SquadTab>("members");
  const [inviting, setInviting] = useState(false);
  const [val, setVal] = useState("");
  const invites = squad.invites || [];

  useEffect(() => {
    if (invites.length > 0) {
      setOpen(true);
      setTab("invites");
    }
  }, [invites.length]);

  const closeInvite = () => {
    setInviting(false);
    setVal("");
  };

  const submitInvite = () => {
    const id = parseInt(val.replace(/\D/g, ""), 10);
    if (!isNaN(id)) act("squad_invite", { id });
    closeInvite();
  };

  const setActiveTab = (nextTab: SquadTab) => {
    uiSound("tab");
    setTab(nextTab);
    closeInvite();
  };

  return (
    <div className={`sq${open ? " sq--open" : ""}`}>
      <button
        className="sq__head"
        onMouseEnter={hover}
        onClick={() => {
          uiSound(open ? "collapse" : "expand");
          setOpen((current) => !current);
        }}
      >
        <span className="sq__title">Squad</span>
        <span className="sq__count">{squad.members.length}/6</span>
        {invites.length > 0 && <span className="sq__badge">{invites.length}</span>}
        <span className={`sq__caret${open ? " sq__caret--open" : ""}`} />
      </button>

      <div className="sq__wrap">
        <div className="sq__clip">
          <div className="sq__body">
            <div className="sq__tabs">
              <button
                className={`sq__tab${tab === "members" ? " sq__tab--active" : ""}`}
                onMouseEnter={hover}
                onClick={() => setActiveTab("members")}
              >
                Members
              </button>
              <button
                className={`sq__tab${tab === "invites" ? " sq__tab--active" : ""}`}
                onMouseEnter={hover}
                onClick={() => setActiveTab("invites")}
              >
                {invites.length > 0 ? `Invites (${invites.length})` : "Invites"}
              </button>
            </div>

            {tab === "members" && (
              <>
                {squad.members.length === 0 && <div className="sq__empty">No squad members</div>}

                {squad.members.map((member) => (
                  <div key={member.id} className="sq__row">
                    <RankBadge
                      icon={member.rankIcon || `rank_${member.level || 1}`}
                      prestige={member.prestige}
                      className="sq__rank"
                    />
                    <span className="sq__meta">
                      <span className={`sq__name${member.leader ? " sq__name--leader" : ""}`}>
                        {member.name}
                      </span>
                      {member.leader && <span className="sq__role">Leader</span>}
                    </span>
                    {squad.isLeader && !member.self && (
                      <button
                        className="sq__act sq__act--warn"
                        onMouseEnter={hover}
                        onClick={() => act("squad_kick", { id: member.id })}
                      >
                        Kick
                      </button>
                    )}
                    {member.self && !member.leader && (
                      <button
                        className="sq__act sq__act--warn"
                        onMouseEnter={hover}
                        onClick={() => act("squad_leave")}
                      >
                        Leave
                      </button>
                    )}
                  </div>
                ))}

                {squad.members.length === 0 || squad.isLeader ? (
                  inviting ? (
                    <div className="sq__invite-row">
                      <input
                        className="sq__input"
                        autoFocus
                        inputMode="numeric"
                        maxLength={6}
                        placeholder="Player ID"
                        value={val}
                        onChange={(event) => setVal(event.target.value)}
                        onKeyDown={(event) => {
                          if (event.key === "Enter") submitInvite();
                          else if (event.key === "Escape") closeInvite();
                        }}
                      />
                      <button className="sq__send" onMouseEnter={hover} onClick={submitInvite}>
                        Invite
                      </button>
                      <button className="sq__close" onMouseEnter={hover} onClick={closeInvite}>
                        <XIcon />
                      </button>
                    </div>
                  ) : (
                    <button
                      className="sq__invite"
                      onMouseEnter={hover}
                      onClick={() => {
                        uiSound("select");
                        setInviting(true);
                      }}
                    >
                      + Invite player
                    </button>
                  )
                ) : null}
              </>
            )}

            {tab === "invites" && (
              <>
                {invites.length === 0 && <div className="sq__empty">No pending invites</div>}

                {invites.map((invite) => (
                  <div key={invite.inviteId} className="sq__row">
                    <RankBadge
                      icon={invite.rankIcon || `rank_${invite.level || 1}`}
                      prestige={invite.prestige}
                      className="sq__rank"
                    />
                    <span className="sq__meta">
                      <span className="sq__name">{invite.name}</span>
                      <span className="sq__role">Squad invitation</span>
                    </span>
                    <span className="sq__actions">
                      <button
                        className="sq__act sq__act--accept"
                        onMouseEnter={hover}
                        onClick={() => act("squad_accept", { inviteId: invite.inviteId })}
                      >
                        Accept
                      </button>
                      <button
                        className="sq__act sq__act--warn"
                        onMouseEnter={hover}
                        onClick={() => act("squad_refuse", { inviteId: invite.inviteId })}
                      >
                        Decline
                      </button>
                    </span>
                  </div>
                ))}
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default SquadPanel;
