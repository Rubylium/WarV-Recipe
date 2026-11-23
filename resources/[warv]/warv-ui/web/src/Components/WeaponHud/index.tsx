import { useSelector } from "../..";
import { hideImg, IMG } from "../../images";
import "./index.scss";

const WeaponHud = () => {
  const d = useSelector((s) => s.weaponHud);
  const screen = useSelector((s) => s.screen);
  const show = d.visible && screen === "none";

  const hasAmmo = d.clipMax > 0 || d.reserve > 0 || d.clip > 0;
  const magPct = d.clipMax > 0 ? Math.max(0, Math.min(100, (d.clip / d.clipMax) * 100)) : 0;
  const low = hasAmmo && (d.clipMax > 0 ? d.clip / d.clipMax <= 0.25 : d.clip <= 5);
  const empty = hasAmmo && d.clip <= 0;

  return (
    <div className={`wh${show ? " wh--show" : ""}${low ? " wh--low" : ""}${empty ? " wh--empty" : ""}`}>
      <div className="wh__name">{d.name || "—"}</div>

      <div className="wh__main">
        {d.image && (
          <img
            className="wh__img"
            src={IMG(`weapons/${d.image}.png`)}
            alt=""
            draggable={false}
            onError={hideImg}
          />
        )}
        {hasAmmo && (
          <div className="wh__ammo">
            <span className="wh__clip">{d.clip}</span>
            <span className="wh__reserve">
              <img className="wh__ammo-ico" src={IMG("hud/ammo.png")} alt="" draggable={false} onError={hideImg} />
              {d.reserve}
            </span>
          </div>
        )}
      </div>

      {hasAmmo && d.clipMax > 0 && (
        <div className="wh__mag">
          <div className="wh__mag-fill" style={{ width: `${magPct}%` }} />
        </div>
      )}

      {d.grenade >= 0 && (
        <div className={`wh__nade${d.grenade <= 0 ? " wh__nade--empty" : ""}`}>
          <img className="wh__nade-ico" src={IMG("hud/grenade.png")} alt="" draggable={false} onError={hideImg} />
          <span className="wh__nade-count">{d.grenade}</span>
        </div>
      )}
    </div>
  );
};

export default WeaponHud;
