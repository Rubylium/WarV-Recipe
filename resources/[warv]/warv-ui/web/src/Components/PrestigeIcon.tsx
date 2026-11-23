import { useEffect, useState } from "react";
import { IMG } from "../images";

const cols = 8;
const rows = 6;
const frames = cols * rows;
const fps = 24;

interface Props {
  prestige: number;
  className?: string;
}

const PrestigeIcon = ({ prestige, className = "prestige-icon" }: Props) => {
  const [f, setF] = useState(0);
  const p = Math.max(1, Math.min(5, Math.floor(prestige)));

  useEffect(() => {
    setF(0);
    const id = window.setInterval(() => setF((x) => (x + 1) % frames), 1000 / fps);
    return () => window.clearInterval(id);
  }, [p]);

  const col = f % cols;
  const row = Math.floor(f / cols);
  return (
    <div
      className={className}
      style={{
        backgroundImage: `url(${IMG(`menu/prestige/prestige_${p}.png`)})`,
        backgroundSize: `${cols * 100}% ${rows * 100}%`,
        backgroundPosition: `${(col / (cols - 1)) * 100}% ${(row / (rows - 1)) * 100}%`,
        backgroundRepeat: "no-repeat",
      }}
    />
  );
};

export default PrestigeIcon;
