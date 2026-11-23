import { ClothingCreatorData, ClothingOutfit, EventPayload } from "../../types";

const teamList = (value: unknown) => (Array.isArray(value) ? value.map(Number) : []);

const withTeams = (outfit: ClothingOutfit) => ({ ...outfit, teams: teamList(outfit.teams) });

const emptyAppearance = {
  model: "mp_m_freemode_01",
  components: {},
  props: {},
  faceFeatures: {},
  headOverlays: {},
  hair: { color: 0, highlight: 0 },
  eyeColor: 0,
  headBlend: {
    shapeFirst: 0,
    shapeSecond: 0,
    shapeThird: 0,
    skinFirst: 0,
    skinSecond: 0,
    skinThird: 0,
    shapeMix: 0.5,
    skinMix: 0.5,
    thirdMix: 0,
  },
};

const defaultState: ClothingCreatorData = {
  outfits: [],
  draft: {
    name: "New Outfit",
    teams: [],
    appearance: emptyAppearance,
  },
  limits: {
    components: [],
    props: [],
    overlayMax: {},
    hairColorMax: 63,
  },
  saving: false,
  notice: "",
};

export const clothingCreator = (
  state: ClothingCreatorData = defaultState,
  data: EventPayload<any>
) => {
  if (data.type === "SET_CLOTHING_CREATOR") {
    const next = data.payload as ClothingCreatorData;
    return {
      ...next,
      outfits: next.outfits.map(withTeams),
      draft: withTeams(next.draft),
    };
  }
  if (data.type === "SET_CLOTHING_LIMITS") {
    return { ...state, limits: data.payload };
  }
  return state;
};
