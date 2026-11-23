import { useState } from "react";
import { IMG } from "../images";
import PrestigeIcon from "./PrestigeIcon";

interface Props {
  icon: string;
  prestige?: number;
  className?: string;
}

const RankBadge = ({ icon, prestige = 0, className = "rank-badge" }: Props) => {
  const [ok, setOk] = useState(true);
  if (prestige > 0) return <PrestigeIcon prestige={prestige} className={className} />;
  if (!ok) return <div className={`${className} ${className}--ph`} />;
  return (
    <img
      className={className}
      src={IMG(`menu/ranks/${icon}.png`)}
      alt=""
      draggable={false}
      onError={() => setOk(false)}
    />
  );
};

export default RankBadge;
