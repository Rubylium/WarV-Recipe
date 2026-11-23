import { ReactNode } from "react";
import { act, hover } from "../ui";
import "./SubHeader.scss";

const SubHeader = ({ title, back, right }: { title: string; back: string; right?: ReactNode }) => (
  <div className="subhead">
    <button className="subhead__back" onMouseEnter={hover} onClick={() => act(back, {}, "back")}>
      &lsaquo; Back
    </button>
    <span className="subhead__title">{title}</span>
    {right && <div className="subhead__right">{right}</div>}
  </div>
);

export default SubHeader;
