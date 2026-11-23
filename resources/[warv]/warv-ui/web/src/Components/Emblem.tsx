import { useState } from "react";
import { IMG } from "../images";

interface Props {
  sprite: string;
  className?: string;
}

const Emblem = ({ sprite, className = "emblem" }: Props) => {
  const [ok, setOk] = useState(true);
  if (!sprite || !ok) return null;
  return (
    <img
      className={className}
      src={IMG(`menu/emblems/${sprite}.png`)}
      alt=""
      draggable={false}
      onError={() => setOk(false)}
    />
  );
};

export default Emblem;
