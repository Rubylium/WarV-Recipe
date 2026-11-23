import { ComponentType, SVGProps } from "react";
import { FiAlertTriangle } from "react-icons/fi";

const AlertIcon = FiAlertTriangle as ComponentType<SVGProps<SVGSVGElement>>;

interface NoticeCardProps {
  d: Record<string, unknown>;
  leaving: boolean;
}

const NoticeCard = ({ d, leaving }: NoticeCardProps) => {
  const title = String(d.title || "Notice");
  const message = String(d.message || "");

  return (
    <div className={`ntf-notice${leaving ? " ntf-notice--leaving" : ""}`}>
      <span className="ntf-notice__icon">
        <AlertIcon />
      </span>
      <span className="ntf-notice__content">
        <strong>{title}</strong>
        <span>{message}</span>
      </span>
    </div>
  );
};

export default NoticeCard;
