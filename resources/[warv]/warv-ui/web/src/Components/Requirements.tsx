import { SelectRequirement } from "../types";

interface Props {
  list: SelectRequirement[];
  description?: string;
}

const Requirements = ({ list, description }: Props) => {
  if (list.length === 0)
    return (
      <>
        {description && <span className="sel__card-desc">{description}</span>}
        <span className="sel__default-unlock">Unlocked by default</span>
      </>
    );

  return (
    <>
      {list.map((r) => (
        <span className="sel__requirement" key={r.stat}>
          <span className="sel__requirement-copy">
            <span>{r.label}</span>
            <b>
              {Math.min(r.current, r.target)} / {r.target}
            </b>
          </span>
          <span className="sel__progress">
            <span
              className={`sel__progress-fill${r.complete ? " sel__progress-fill--complete" : ""}`}
              style={{ width: `${Math.max(0, Math.min(100, r.percent))}%` }}
            />
          </span>
        </span>
      ))}
    </>
  );
};

export default Requirements;
