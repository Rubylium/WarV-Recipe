import { ComponentType, SVGProps } from "react";
import { IconType } from "react-icons";
import {
  FaAnglesUp,
  FaChartSimple,
  FaRankingStar,
  FaTrophy,
} from "react-icons/fa6";
import {
  GiCrossedSwords,
  GiCrosshair,
  GiHeadShot,
  GiNuclear,
} from "react-icons/gi";

const icons: Record<string, IconType> = {
  kills: GiCrosshair,
  wins: FaTrophy,
  score: FaChartSimple,
  kd: GiCrossedSwords,
  level: FaAnglesUp,
  ranked: FaRankingStar,
  headshots: GiHeadShot,
  nukes: GiNuclear,
};

const CategoryIcon = ({ category }: { category: string }) => {
  const Icon = (icons[category] ?? FaRankingStar) as ComponentType<SVGProps<SVGSVGElement>>;
  return <Icon aria-hidden="true" focusable="false" />;
};

export default CategoryIcon;
