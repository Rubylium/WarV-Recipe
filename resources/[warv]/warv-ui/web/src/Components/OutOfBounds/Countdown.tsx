import { useEffect, useRef } from "react";

interface CountdownProps {
  active: boolean;
  seconds: number;
  total: number;
}

const Countdown = ({ active, seconds, total }: CountdownProps) => {
  const fillRef = useRef<HTMLDivElement>(null);
  const remaining = Number.isFinite(seconds) ? Math.max(0, seconds) : 0;
  const duration = Number.isFinite(total) && total > 0 ? total : remaining;
  const progress = duration > 0 ? Math.min(1, remaining / duration) : 0;

  useEffect(() => {
    if (!active || !fillRef.current || remaining <= 0) return;

    const animation = fillRef.current.animate(
      [
        { transform: "scaleX(" + progress + ")" },
        { transform: "scaleX(0)" },
      ],
      { duration: remaining * 1000, easing: "linear", fill: "forwards" },
    );
    return () => animation.cancel();
  }, [active, remaining, progress]);

  return (
    <div className="oob__countdown">
      <div className="oob__timerRow">
        <span className="oob__timerLabel">Time remaining</span>
        <span className="oob__timer">
          {String(Math.ceil(remaining)).padStart(2, "0")} s
        </span>
      </div>
      <div className="oob__track">
        <div
          ref={fillRef}
          className="oob__fill"
          style={{ transform: "scaleX(" + progress + ")" }}
        />
      </div>
    </div>
  );
};

export default Countdown;
