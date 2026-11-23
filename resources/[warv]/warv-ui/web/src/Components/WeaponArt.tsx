import { useState } from "react";
import { IMG } from "../images";

export const LockIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="square">
    <rect x="5" y="11" width="14" height="9" />
    <path d="M8 11V8a4 4 0 0 1 8 0v3" />
  </svg>
);

const GunIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="square">
    <path d="M3 8h15v4h-3l-2 3H8l-1-3H3z" />
    <path d="M6 12v3" />
  </svg>
);

const WeaponArt = ({ image, cls }: { image: string; cls: string }) => {
  const [err, setErr] = useState(false);
  if (!image || err)
    return (
      <span className={`${cls} ${cls}--ph`}>
        <GunIcon />
      </span>
    );
  return (
    <img
      className={cls}
      src={IMG(`weapons/${encodeURIComponent(image)}.png`)}
      alt=""
      draggable={false}
      onError={() => setErr(true)}
    />
  );
};

export default WeaponArt;
