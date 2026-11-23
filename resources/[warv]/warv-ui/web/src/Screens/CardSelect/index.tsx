import { useState } from "react";
import { useSelector } from "../..";
import CallingCard, { cardFrames } from "../../Components/CallingCard";
import Requirements from "../../Components/Requirements";
import { callingCardSource } from "../../Components/callingCardAssets";
import { act, hover } from "../../ui";
import "../select.scss";

const CardPreview = ({ sprite }: { sprite: string }) => {
  const [ok, setOk] = useState(true);
  const frame = cardFrames(sprite)[0];
  if (!frame || !ok) return <div className="sel__cc sel__cc--ph" />;
  return (
    <img
      className="sel__cc"
      src={callingCardSource(frame, false)}
      loading="lazy"
      draggable={false}
      alt=""
      onError={() => setOk(false)}
    />
  );
};

const CardSelect = () => {
  const data = useSelector((s) => s.cardSelect);
  const [hovId, setHovId] = useState<number | null>(null);

  return (
    <div className="sel sel--cards">
      {data.items.map((it) => (
        <button
          key={it.id}
          className={`sel__item sel__item--card${it.id === data.selected ? " sel__item--active" : ""}${
            it.locked ? " sel__item--locked" : ""
          }`}
          onMouseEnter={() => {
            if (it.locked) return;
            hover();
            setHovId(it.id);
          }}
          onMouseLeave={() => setHovId((h) => (h === it.id ? null : h))}
          onClick={() => !it.locked && act("select_card", { id: it.id })}
        >
          <span className="sel__visual">
            {hovId === it.id ? (
              <CallingCard sprite={it.sprite} className="sel__cc" fps={12} />
            ) : (
              <CardPreview sprite={it.sprite} />
            )}
            {it.id === data.selected && <span className="sel__equipped">Equipped</span>}
            {it.locked && <span className="sel__status">Locked</span>}
          </span>

          <span className="sel__details">
            <span className="sel__card-name">{it.label || it.key || it.sprite}</span>
            <Requirements list={it.requirements || []} description={it.description} />
          </span>
        </button>
      ))}
    </div>
  );
};

export default CardSelect;
