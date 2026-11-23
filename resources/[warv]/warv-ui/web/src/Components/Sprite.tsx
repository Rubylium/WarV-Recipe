import { CSSProperties, useEffect, useState } from "react";

interface SpriteProps {
  src: string;
  columns: number;
  rows: number;
  fps?: number;
  frames?: number;
  offset?: number;
  loop?: boolean;
  className?: string;
  style?: CSSProperties;
}

const Sprite = ({
  src,
  columns,
  rows,
  fps = 12,
  frames,
  offset = 0,
  loop = true,
  className,
  style,
}: SpriteProps) => {
  const total = Math.max(1, frames ?? columns * rows);
  const start = ((Math.floor(offset) % total) + total) % total;
  const [f, setF] = useState(start);

  useEffect(() => {
    setF(start);
    if (total <= 1 || fps <= 0) return;
    const id = setInterval(() => {
      setF((prev) => {
        const next = prev + 1;
        if (next >= total) return loop ? 0 : prev;
        return next;
      });
    }, 1000 / fps);
    return () => clearInterval(id);
  }, [src, total, fps, loop, start]);

  const col = columns > 1 ? ((f % columns) / (columns - 1)) * 100 : 0;
  const row = rows > 1 ? (Math.floor(f / columns) / (rows - 1)) * 100 : 0;

  return (
    <div
      className={className}
      style={{
        backgroundImage: `url(${src})`,
        backgroundSize: `${columns * 100}% ${rows * 100}%`,
        backgroundPosition: `${col}% ${row}%`,
        backgroundRepeat: "no-repeat",
        ...style,
      }}
    />
  );
};

export default Sprite;
