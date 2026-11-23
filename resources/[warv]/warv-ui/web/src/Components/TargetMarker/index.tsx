import "./index.scss";

interface TargetMarkerProps {
  x: number;
  y: number;
  label: string;
}

const TargetMarker = ({ x, y, label }: TargetMarkerProps) => (
  <div className="target-marker" style={{ left: `${x * 100}%`, top: `${y * 100}%` }}>
    <span className="target-marker__box" />
    <span className="target-marker__tag">{label}</span>
  </div>
);

export default TargetMarker;
