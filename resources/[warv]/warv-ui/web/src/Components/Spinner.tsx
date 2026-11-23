import { CSSProperties } from "react";
import Sprite from "./Sprite";
import { IMG } from "../images";

const Spinner = ({
  offset = 0,
  className,
  style,
}: {
  offset?: number;
  className?: string;
  style?: CSSProperties;
}) => (
  <Sprite
    src={IMG("sprites/spinner.png")}
    columns={9}
    rows={5}
    frames={45}
    fps={26}
    offset={offset}
    className={`spinner${className ? " " + className : ""}`}
    style={style}
  />
);

export default Spinner;
