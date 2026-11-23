import { useEffect, useState } from "react";
import { useSelector } from "../..";
import Countdown from "./Countdown";
import "./index.scss";

const OutOfBounds = () => {
  const { visible, seconds, total } = useSelector((s) => s.oob);
  const [render, setRender] = useState(false);
  const [leaving, setLeaving] = useState(false);

  useEffect(() => {
    if (visible) {
      setRender(true);
      setLeaving(false);
      return;
    }
    if (render) {
      setLeaving(true);
      const timeout = setTimeout(() => setRender(false), 360);
      return () => clearTimeout(timeout);
    }
  }, [visible, render]);

  if (!render) return null;

  return (
    <div className={"oob " + (leaving ? "oob--out" : "oob--in")}>
      <div className="oob__vignette" />
      <div className="oob__center">
        <div className="oob__warn">Out of bounds</div>
        <div className="oob__title">Return to combat</div>
        <div className="oob__description">
          Get back inside the combat area
        </div>
        <Countdown active={visible} seconds={seconds} total={total} />
      </div>
    </div>
  );
};

export default OutOfBounds;
