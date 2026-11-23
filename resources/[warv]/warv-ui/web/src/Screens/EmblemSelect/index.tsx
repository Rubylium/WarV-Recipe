import { useState } from "react";
import { useSelector } from "../..";
import Requirements from "../../Components/Requirements";
import { IMG } from "../../images";
import { act, hover } from "../../ui";
import "../select.scss";

const EmblemPreview = ({ sprite }: { sprite: string }) => {
  const [ok, setOk] = useState(true);
  if (!sprite || !ok) return <div className="sel__cc sel__cc--ph" />;
  return (
    <img
      className="sel__em"
      src={IMG(`menu/emblems/${sprite}.png`)}
      loading="lazy"
      draggable={false}
      alt=""
      onError={() => setOk(false)}
    />
  );
};

const EmblemSelect = () => {
  const data = useSelector((s) => s.emblemSelect);
  const [hovId, setHovId] = useState<number | null>(null);
  const focus = data.items.find((it) => it.id === (hovId ?? data.selected));

  return (
    <div className="sel sel--emblems">
      <div className="sel__grid">
        {data.items.map((it) => (
          <button
            key={it.id}
            className={`sel__item sel__item--emblem${it.id === data.selected ? " sel__item--active" : ""}${
              it.locked ? " sel__item--locked" : ""
            }`}
            onMouseEnter={() => {
              if (!it.locked) hover();
              setHovId(it.id);
            }}
            onMouseLeave={() => setHovId((h) => (h === it.id ? null : h))}
            onClick={() => !it.locked && act("select_emblem", { id: it.id })}
          >
            <EmblemPreview sprite={it.sprite} />
            {it.id === data.selected && <span className="sel__equipped">Equipped</span>}
            {it.locked && <span className="sel__status">Locked</span>}
          </button>
        ))}
      </div>

      {focus && (
        <div className="sel__detail">
          <span className="sel__card-name">{focus.label || focus.key || focus.sprite}</span>
          <span className="sel__detail-reqs">
            <Requirements list={focus.requirements || []} description={focus.description} />
          </span>
        </div>
      )}
    </div>
  );
};

export default EmblemSelect;
