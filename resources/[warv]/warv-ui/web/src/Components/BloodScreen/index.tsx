import { useSelector } from "../..";
import { IMG } from "../../images";
import "./index.scss";

const bloodImg = IMG("hud/blood.png");

const BloodScreen = () => {
  const alpha = useSelector((s) => s.blood);
  const screen = useSelector((s) => s.screen);
  const show = screen === "none" && alpha > 0;

  return (
    <div
      className="blood"
      style={{ opacity: show ? alpha : 0, backgroundImage: `url(${bloodImg})` }}
    />
  );
};

export default BloodScreen;
