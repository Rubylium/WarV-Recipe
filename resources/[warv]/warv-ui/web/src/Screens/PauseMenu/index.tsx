import { useEffect } from "react";
import { act, hover } from "../../ui";
import "./index.scss";

const options: { label: string; sub: string; action: string; danger?: boolean }[] = [
  { label: "Resume Game", sub: "Back to combat", action: "pause_resume" },
  { label: "Game Settings", sub: "Video, audio and controls", action: "pause_settings" },
  { label: "Leave Lobby", sub: "Abandon the match", action: "pause_leave", danger: true },
];

const PauseMenu = ({ closing = false }: { closing?: boolean }) => {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" || e.key.toLowerCase() === "p") act("pause_resume");
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  return (
    <div className={`pse${closing ? " pse--closing" : ""}`}>
      <div className="pse__wash" />
      <div className="pse__glow" />

      <div className="pse__head">
        <h1 className="pse__title">Paused</h1>
        <div className="pse__rule" />
      </div>

      <div className="pse__options">
        {options.map((o, i) => (
          <button
            key={o.action}
            className={`pse__btn${o.danger ? " pse__btn--danger" : ""}`}
            style={{ animationDelay: `${0.08 + i * 0.06}s` }}
            onMouseEnter={hover}
            onClick={() => act(o.action)}
          >
            <span className="pse__btn-label">{o.label}</span>
            <span className="pse__btn-sub">{o.sub}</span>
          </button>
        ))}
      </div>

      <div className="pse__foot">
        <span className="pse__foot-rule" />
        <span className="pse__hint">Esc · Resume</span>
      </div>
    </div>
  );
};

export default PauseMenu;
