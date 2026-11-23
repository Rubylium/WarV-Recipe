import "./index.scss";

interface SensorOverlayProps {
  platform: string;
  weapon: string;
  status: string;
  heading?: number;
  pitch?: number;
  roll?: number;
  altitude?: number;
  speed?: number;
  time?: string;
}

const normalizeHeading = (value: number) => ((Math.round(value) % 360) + 360) % 360;
const pad = (value: number, width: number) =>
  Math.abs(Math.round(value)).toString().padStart(width, "0");
const signed = (value: number) => `${value >= 0 ? "+" : "-"}${pad(value, 2)}`;

const SensorOverlay = ({
  platform,
  weapon,
  status,
  heading = 0,
  pitch = 0,
  roll = 0,
  altitude = 0,
  speed = 0,
  time = "00:00",
}: SensorOverlayProps) => {
  const safePitch = Math.max(-45, Math.min(45, pitch));
  const safeRoll = Math.max(-45, Math.min(45, roll));

  return (
    <div className="sensor-overlay">
      <div className="sensor-overlay__mode">
        <span>{platform}</span>
        <strong>{weapon}</strong>
        <span>F/M&nbsp;&nbsp;SGL</span>
      </div>

      <div className="sensor-overlay__clock">{time}</div>

      <svg className="sensor-overlay__stadia" viewBox="0 0 1000 560" preserveAspectRatio="none">
        <g className="sensor-overlay__lines">
          <path d="M276 280H458M542 280H724" />
          <path d="M500 104V246M500 314V444" />
          <path d="M320 272V288M380 272V288M440 268V292M560 268V292M620 272V288M680 272V288" />
          <path d="M492 142H508M492 190H508M488 232H512M488 328H512M492 370H508M492 414H508" />
          <path d="M330 468H670M330 454V482M410 458V478M500 452V484M590 458V478M670 454V482" />
        </g>
        <text x="500" y="447" textAnchor="middle">WPN LIMIT</text>
        <text x="500" y="503" textAnchor="middle">{status}</text>
        <text x="252" y="274" textAnchor="end">{pad(speed, 3)}M/S</text>
        <text x="748" y="274">{pad(altitude, 4)}M</text>
      </svg>

      <div className="sensor-overlay__attitude">
        <svg viewBox="0 0 100 100">
          <circle cx="50" cy="50" r="38" />
          <path d="M50 8V18M50 82V92M8 50H18M82 50H92" />
          <g style={{ transform: `rotate(${-safeRoll}deg)`, transformOrigin: "50px 50px" }}>
            <path d={`M24 ${50 + safePitch * 0.35}H76`} />
            <path d={`M42 ${43 + safePitch * 0.35}L50 ${50 + safePitch * 0.35}L58 ${43 + safePitch * 0.35}`} />
          </g>
          <path d="M45 13L50 7L55 13" />
        </svg>
        <span>{signed(pitch)} P</span>
        <span>{signed(roll)} R</span>
      </div>

      <div className="sensor-overlay__bottom-data">
        <span>HDG {pad(normalizeHeading(heading), 3)}</span>
        <span>ALT {pad(altitude, 4)}</span>
        <span>VEL {pad(speed, 3)}</span>
        <span>TRK AUTO</span>
      </div>

      <div className="sensor-overlay__sweep" />
      <div className="sensor-overlay__dropout sensor-overlay__dropout--a" />
      <div className="sensor-overlay__dropout sensor-overlay__dropout--b" />
    </div>
  );
};

export default SensorOverlay;
