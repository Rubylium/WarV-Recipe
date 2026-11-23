import { useEffect, useState } from "react";
import { callingCardSource } from "./callingCardAssets";
import callingCardFrames from "../callingcards.json";

const frameSets = callingCardFrames as Record<string, string[]>;

export const cardFrames = (sprite: string): string[] => {
  if (!sprite) return [];
  if (sprite.endsWith("_")) return frameSets[sprite] || [`${sprite}1`];
  return [sprite];
};

interface Props {
  sprite: string;
  className?: string;
  fps?: number;
}

const CallingCard = ({ sprite, className = "cc", fps = 11 }: Props) => {
  const frames = cardFrames(sprite);
  const [f, setF] = useState(0);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setF(0);
    setFailed(false);
    if (frames.length <= 1) return;
    const id = setInterval(() => setF((p) => (p + 1) % frames.length), 1000 / fps);
    return () => clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sprite, fps]);

  if (frames.length === 0 || failed) return <div className={`${className} cc--ph`} />;

  return (
    <>
      {frames.map((name, i) => (
        <img
          key={name}
          className={className}
          src={callingCardSource(name)}
          alt=""
          draggable={false}
          style={{ opacity: i === f ? 1 : 0 }}
          onError={i === 0 ? () => setFailed(true) : undefined}
        />
      ))}
    </>
  );
};

export default CallingCard;
