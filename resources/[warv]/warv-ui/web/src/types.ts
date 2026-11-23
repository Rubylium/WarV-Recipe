export interface EventPayload<T> {
  type: string;
  payload: T;
}

export type Screen =
  | "none"
  | "gamemode_select"
  | "server_browser"
  | "lobby_wait"
  | "class_editor"
  | "weapon_picker"
  | "attach_editor"
  | "class_pick"
  | "pause"
  | "death"
  | "killstreak_editor"
  | "endscreen"
  | "loading"
  | "match_loading"
  | "menu"
  | "barracks"
  | "leaderboard"
  | "card_select"
  | "emblem_select"
  | "settings"
  | "clothing_creator"
  | "map_editor"
  | "prop_editor";

export interface LoadingData {
  progress: number;
  status: string;
}

export type MatchLoadingPhase = "loading" | "waiting";
export interface MatchLoadingData {
  map: { name: string; image: string };
  gamemode: string;
  ranked: boolean;
  teamMode: boolean;
  phase: MatchLoadingPhase;
  progress: number;
  waitingText: string;
  tip: string;
}

export interface KillfeedEntry {
  killer: string;
  victim: string;
  weapon: string;
  headshot: boolean;
  suicide: boolean;
  special: string;
  killerFriendly: boolean;
  victimFriendly: boolean;
  mine: boolean;
  streak: number;
}

export interface ScoreSide {
  score: number;
  label: string;
  logo: string;
  color: "blue" | "red";
}
export interface ScoreHudData {
  visible: boolean;
  teamMode: boolean;
  gamemode: string;
  gmIcon: string;
  timer: number;
  maxScore: number;
  left: ScoreSide;
  right: ScoreSide;
}

export type KillstreakState = "progress" | "ready" | "spent" | "cooldown";
export interface KillstreakEntry {
  key: string;
  type: string;
  icon: string;
  label: string;
  state: KillstreakState;
  progress: number;
  needed: number;
  pct: number;
  cooldownRemaining: number;
  cooldownTotal: number;
}
export interface KillstreakHudData {
  visible: boolean;
  streaks: KillstreakEntry[];
}

export interface WeaponHudData {
  visible: boolean;
  name: string;
  image: string;
  clip: number;
  clipMax: number;
  reserve: number;
  grenade: number;
}

export interface KillstreakSlot {
  index: number;
  type: string;
  label: string;
  icon: string;
  kill: number;
}
export interface KillstreakEditItem {
  type: string;
  label: string;
  icon: string;
  kill: number;
  desc: string;
  equipped: boolean;
}
export interface KillstreakEditorData {
  slots: KillstreakSlot[];
  streaks: KillstreakEditItem[];
}

export type EndResult = "victory" | "defeat" | "draw";
export interface EndScreenSide {
  name: string;
  logo: string;
  score: number;
  color: "blue" | "red";
}
export interface EndScreenRow {
  pos: number;
  name: string;
  score: number;
  level: number;
  prestige: number;
  rankIcon: string;
  me: boolean;
}
export interface EndScreenData {
  result: EndResult;
  subtitle: string;
  teamMode: boolean;
  left: EndScreenSide;
  right: EndScreenSide;
  board: EndScreenRow[];
}

export interface SquadMember {
  id: number;
  name: string;
  level: number;
  prestige: number;
  rankIcon: string;
  leader: boolean;
  self?: boolean;
}

export interface SquadInvite {
  inviteId: string;
  uid: number;
  name: string;
  level: number;
  prestige: number;
  rankIcon: string;
}

export interface MenuPlayer {
  name: string;
  uid: number;
  level: number;
  prestige: number;
  xp: number;
  xpMax: number;
  credit: number;
  rankIcon: string;
  callingCard: string;
  emblem: string;
}

export interface NewsItem {
  title: string;
  text: string;
}

export interface QuickGamemode {
  name: string;
  label: string;
  sprite: string;
  players: number;
}

export interface MenuData {
  player: MenuPlayer;
  squad: {
    isLeader: boolean;
    isOpen: boolean;
    members: SquadMember[];
    invites: SquadInvite[];
  };
  news: NewsItem[];
  gamemodes: QuickGamemode[];
  banned: { active: boolean; text: string };
  permissions: {
    clothingCreator: boolean;
    mapEditor: boolean;
  };
}

export interface ClothingComponent {
  drawable: number;
  texture: number;
  palette: number;
}

export interface ClothingProp {
  drawable: number;
  texture: number;
}

export interface HeadOverlay {
  value: number;
  opacity: number;
  colorType: number;
  color: number;
  secondColor: number;
}

export interface HeadBlend {
  shapeFirst: number;
  shapeSecond: number;
  shapeThird: number;
  skinFirst: number;
  skinSecond: number;
  skinThird: number;
  shapeMix: number;
  skinMix: number;
  thirdMix: number;
}

export interface ClothingAppearance {
  model: string | number;
  components: Record<string, ClothingComponent>;
  props: Record<string, ClothingProp>;
  faceFeatures: Record<string, number>;
  headOverlays: Record<string, HeadOverlay>;
  hair: {
    color: number;
    highlight: number;
  };
  eyeColor: number;
  headBlend: HeadBlend;
}

export interface ClothingOutfit {
  id?: string;
  name: string;
  teams: number[];
  appearance: ClothingAppearance;
  updatedAt?: number;
  updatedBy?: number;
}

export interface ClothingLimit {
  id: number;
  label: string;
  drawableMax: number;
  textureMax: number;
}

export interface ClothingLimits {
  components: ClothingLimit[];
  props: ClothingLimit[];
  overlayMax: Record<string, number>;
  hairColorMax: number;
}

export interface ClothingCreatorData {
  outfits: ClothingOutfit[];
  selectedId?: string;
  draft: ClothingOutfit;
  limits: ClothingLimits;
  saving: boolean;
  notice: string;
}

export interface Playlist {
  name: string;
  label: string;
  description: string;
  sprite: string;
  players: number;
  maxPlayers: number;
  ranked: boolean;
}
export interface GamemodeSelectData {
  playlists: Playlist[];
}

export interface BrowserServer {
  id: string;
  official: boolean;
  gamemode: string;
  map: string;
  voting: boolean;
  players: number;
  maxPlayers: number;
  ping: number;
  sprite: string;
}
export interface ServerBrowserData {
  servers: BrowserServer[];
  error: string;
}

export type LobbyWaitState = "searching" | "waiting" | "voting" | "starting";
export interface LobbyPlayer {
  slot: number;
  empty: boolean;
  id: number;
  uid: number;
  name: string;
  level: number | string;
  rankIcon: string;
  prestige: number;
  self: boolean;
  talking: boolean;
  muted: boolean;
  rankingIcon: string;
  ranking: number;
  winStreak: number;
  bestStreak: number;
  callingCard: string;
  emblem: string;
  kills: number;
  deaths: number;
  kd: string;
  wins: number;
  wl: string;
  squad: boolean;
  voted: boolean;
}
export interface MapVote {
  key: string;
  name: string;
  image: string;
  votes: number;
}
export interface LobbyWaitData {
  ranked: boolean;
  gamemode: string;
  maxPlayers: number;
  playersInLobby: number;
  players: LobbyPlayer[];
  myRankingIcon: string;
  state: LobbyWaitState;
  queuePlace: number;
  queueTotal: number;
  timer: number;
  voted: boolean;
  vote: { map1: MapVote; map2: MapVote; randomVotes: number } | null;
  selectedMap: { name: string; image: string } | null;
}

export interface ClassWeaponSlot {
  weapon: string;
  label: string;
  image: string;
  empty: boolean;
  attachOn: number;
  attachTotal: number;
  level: number;
  maxLevel: number;
}
export interface ClassEntry {
  index: number;
  name: string;
  primary: ClassWeaponSlot;
  secondary: ClassWeaponSlot;
  extra: ClassWeaponSlot;
}
export interface ClassSelectData {
  classes: ClassEntry[];
  lockedSlots: number;
  warvPlus: boolean;
  selected: number;
  scorestreaks: KillstreakSlot[];
}

export interface PickerWeapon {
  weapon: string;
  label: string;
  image: string;
  level: number;
  locked: boolean;
  weaponLevel: number;
  equipped: boolean;
  damage: number;
  accuracy: number;
  range: number;
  fireRate: number;
  clip: number;
}
export interface PickerCategory {
  label: string;
  weapons: PickerWeapon[];
}
export interface WeaponPickerData {
  slot: "primary" | "secondary" | "extra";
  playerLevel: number;
  maxWeaponLevel: number;
  categories: PickerCategory[];
}

export interface AttachEffect {
  label: string;
  value: string;
  tone: "positive" | "negative" | "utility" | "neutral";
}
export interface AttachItem {
  name: string;
  model: string;
  effects: AttachEffect[];
  level: number;
  locked: boolean;
  installed: boolean;
  previewing: boolean;
}
export interface AttachType {
  type: string;
  label: string;
  items: AttachItem[];
  installed: string;
  dirty: boolean;
  capped: boolean;
}
export interface AttachTint {
  index: number;
  label: string;
  unlock: number;
  locked: boolean;
  installed: boolean;
  previewing: boolean;
}
export interface AttachMarker {
  slot: string;
  label: string;
  x: number;
  y: number;
  side: "top" | "left" | "right" | "bottom";
  installed: string;
  internal: boolean;
}
export interface AttachStat {
  value: number;
  referenceValue: number;
  bar: number;
  referenceBar: number;
  delta: number;
  tone: "positive" | "negative" | "neutral";
  lowerIsBetter: boolean;
}
export interface AttachClipStat {
  value: number;
  referenceValue: number;
  delta: number;
  tone: "positive" | "negative" | "neutral";
}
export interface AttachStats {
  isPreview: boolean;
  damage: AttachStat;
  recoil: AttachStat;
  spread: AttachStat;
  range: AttachStat;
  fireRate: AttachStat;
  mobility: AttachStat;
  clip: AttachClipStat;
}
export interface AttachEditorData {
  weapon: { label: string; image: string };
  level: number;
  maxLevel: number;
  xpInto: number;
  xpSpan: number;
  types: AttachType[];
  tints: AttachTint[];
  tintDirty: boolean;
  attachments: { used: number; limit: number };
  canEdit: boolean;
  editing: boolean;
  stats: AttachStats;
}

export interface MatchIntroData {
  visible: boolean;
  map: string;
  gamemode: string;
  team: string;
  teamColor: "blue" | "red";
  name: string;
  nameKey: number;
}

export interface CountdownData {
  visible: boolean;
  seconds: number;
  label: string;
}

export interface OobData {
  visible: boolean;
  seconds: number;
  total: number;
}

export interface IntroTagData {
  visible: boolean;
  name: string;
  key: number;
  x: number;
  y: number;
  teamColor: "blue" | "red";
}

export interface MapEditorLayer {
  id: string;
  label: string;
  kind: string;
  count: number;
  max: number;
  active: boolean;
  color: string;
}
export interface MapEditorGamemode {
  id: string;
  name: string;
  implemented: boolean;
  enabled: boolean;
  requirements: string[];
}
export interface MapEditorSelection {
  label: string;
  index: number;
  x: number;
  y: number;
  z: number;
  heading: number;
}
export interface MapEditorCard {
  name: string;
  label: string;
  description: string;
  image: string;
  spawns: number;
  bounds: number;
  gamemodes: string[];
}
export interface MapEditorPoint {
  index: number;
  x: number;
  y: number;
  z: number;
  heading: number;
  flat: boolean;
}
export interface MapEditorData {
  mode: "pick" | "edit";
  mapName: string;
  cards: MapEditorCard[];
  layers: MapEditorLayer[];
  points: MapEditorPoint[];
  activeLabel: string;
  hidden: boolean;
  env: { hour: number; minute: number; weather: string; set: boolean };
  weathers: string[];
  boundsMaxZ: string;
  boundsMinZ: string;
  gamemodes: MapEditorGamemode[];
  selection: MapEditorSelection | null;
  dirty: boolean;
  missing: string[];
  height: number;
}

export type PropKind = "prop" | "ped" | "vehicle";

export interface PropEditorCard {
  name: string;
  props: number;
  peds: number;
  vehicles: number;
  hidden: number;
  live: boolean;
}
export interface PropEditorProp {
  index: number;
  kind: PropKind;
  model: string;
  x: number;
  y: number;
  z: number;
}
export interface PropEditorFavorite {
  model: string;
  label: string;
}
export interface PropModSlot {
  id: number;
  label: string;
  count: number;
  value: number;
}
export interface PropFlagSlot {
  id: number;
  label: string;
  on: boolean;
}
export interface PropPedSettings {
  scenario: string;
  dict: string;
  anim: string;
}
export interface PropRgb {
  r: number;
  g: number;
  b: number;
}
export interface PropVehicleSettings {
  primary: number;
  secondary: number;
  pearl: number;
  wheelColor: number;
  interior: number;
  dashboard: number;
  wheelType: number;
  windowTint: number;
  plateStyle: number;
  livery: number;
  dirt: number;
  plate: string;
  bulletproof: boolean;
  engineOn: boolean;
  lights: boolean;
  highBeams: boolean;
  siren: boolean;
  neonOn: boolean;
  neon: PropRgb;
  tyreSmoke: PropRgb;
}
export interface PropEditorSelection {
  index: number;
  kind: PropKind | "world";
  model: string;
  mine: boolean;
  favorite: boolean;
  x: number;
  y: number;
  z: number;
  rx: number;
  ry: number;
  rz: number;
  ped?: PropPedSettings;
  scenarios?: string[];
  vehicle?: PropVehicleSettings;
  mods?: PropModSlot[];
  toggles?: PropFlagSlot[];
  extras?: PropFlagSlot[];
  doors?: PropFlagSlot[];
  windows?: PropFlagSlot[];
  wheelTypes?: string[];
}
export interface PropLobbySlot {
  index: number;
  set: boolean;
  scenario: string;
}
export interface PropLobbyCam {
  key: string;
  label: string;
  set: boolean;
  fov: number;
  idle: number;
}
export interface PropLobbyEnv {
  set: boolean;
  hour: number;
  minute: number;
  weather: string;
}
export interface PropLobbyData {
  enabled: boolean;
  meSet: boolean;
  weaponSet: boolean;
  slots: PropLobbySlot[];
  cams: PropLobbyCam[];
  env: PropLobbyEnv;
  weathers: string[];
  scenarios: string[];
}
export interface PropHandleSelection {
  handle: string;
  kind: string;
  label: string;
  x: number;
  y: number;
  z: number;
  h?: number;
  tx?: number;
  ty?: number;
  tz?: number;
  fov?: number;
  idle?: number;
  dof?: boolean;
  dofStrength?: number;
  dofNear?: number;
  dofFar?: number;
  camKey?: string;
  posed?: boolean;
  turnable?: boolean;
  scenario?: string;
  dict?: string;
  anim?: string;
  scenarios?: string[];
}
export interface PropEditorData {
  mode: "pick" | "edit";
  mapName: string;
  cards: PropEditorCard[];
  props: PropEditorProp[];
  hidden: PropEditorProp[];
  history: string[];
  favorites: PropEditorFavorite[];
  selection: PropEditorSelection | null;
  lobby: PropLobbyData | null;
  placing: boolean;
  dirty: boolean;
  speed: number;
  status: string;
}
export interface PropEditorLive {
  selection: PropEditorSelection | null;
  handle: PropHandleSelection | null;
  placing: boolean;
  preview: string;
  gizmo: boolean;
  looking: boolean;
  speed: number;
  dirty: boolean;
}

export interface DeathDamage {
  name: string;
  damage: number;
  hits: number;
  headshot: boolean;
  final: boolean;
  weaponImage: string;
}
export interface DeathData {
  killer: string;
  respawnMs: number;
  canChangeClass: boolean;
  weaponImage: string;
  weaponName: string;
  distance: number;
  headshot: boolean;
  rankIcon: string;
  level: number;
  prestige: number;
  spectating: string;
  specSeq: number;
  damage: DeathDamage[];
}

export interface ClassPickWeapon {
  label: string;
  image: string;
  level: number;
  empty: boolean;
}
export interface ClassPickEntry {
  key: string;
  name: string;
  premade: boolean;
  primary: ClassPickWeapon;
  secondary: ClassPickWeapon;
  extra: ClassPickWeapon;
}
export interface ClassPickData {
  classes: ClassPickEntry[];
  maxWeaponLevel: number;
  selected: string;
}

export interface BarracksStats {
  kills: number;
  deaths: number;
  assists: number;
  kda: string;
  wins: number;
  draws: number;
  losses: number;
  wlr: string;
  score: number;
  winStreak: number;
  bestWinStreak: number;
  headshots: number;
  headshotRatio: string;
  playtimeText: string;
  canPrestige: boolean;
}

export interface BarracksData {
  player: MenuPlayer;
  stats: BarracksStats;
}

export interface ChallengeEntry {
  id: string;
  label: string;
  desc: string;
  target: number;
  credit: number;
  progress: number;
  completed: boolean;
  icon?: string;
}

export interface ChallengesData {
  items: ChallengeEntry[];
  resetsIn: number;
}

export type FriendState = "offline" | "lobby" | "queue" | "match";

export interface FriendEntry {
  uid: number;
  name: string;
  level: number;
  prestige: number;
  state: FriendState;
  detail?: string;
  joinable: boolean;
}

export interface FriendsData {
  friends: FriendEntry[];
  incoming: FriendEntry[];
  outgoing: FriendEntry[];
  blocked: FriendEntry[];
  hidden: boolean;
  cap: number;
}

export interface LeaderboardCategory {
  id: string;
  label: string;
  decimals: number;
}

export interface LeaderboardRow {
  rank: number;
  uid: number;
  name: string;
  level: number;
  prestige: number;
  rankIcon: string;
  callingCard: string;
  emblem: string;
  value: number;
}

export interface LeaderboardData {
  category: string;
  categories: LeaderboardCategory[];
  items: LeaderboardRow[];
  self?: LeaderboardRow;
}

export interface SelectItem {
  id: number;
  key?: string;
  sprite: string;
  label?: string;
  description?: string;
  locked: boolean;
  requirements?: SelectRequirement[];
}

export interface SelectRequirement {
  stat: string;
  label: string;
  current: number;
  target: number;
  percent: number;
  complete: boolean;
}

export interface SelectData {
  items: SelectItem[];
  selected: number;
}

export interface VolumeSetting {
  key: string;
  label: string;
  percent: number;
}
export interface ChoiceSetting {
  id: string;
  label: string;
  desc?: string;
  selected: boolean;
}
export interface SettingsData {
  volumes: VolumeSetting[];
  rankup: ChoiceSetting[];
  music: ChoiceSetting[];
}

export type PlayerMarkerKind = "enemy" | "friendly" | "dead" | "drone";
export interface PlayerMarker {
  x: number;
  y: number;
  kind: PlayerMarkerKind;
  size: number;
}

export interface VoicePlayer {
  name: string;
  talking: boolean;
}

export interface HitMarkerData {
  n: number;
  kill: boolean;
}

export type ScoreboardVoice = "none" | "idle" | "talking" | "muted";
export interface ScoreboardRow {
  empty?: boolean;
  id: number;
  name: string;
  uid: string;
  level: number | string;
  prestige: number;
  rankIcon: string;
  ping: number;
  score: number;
  kill: number;
  assist: number;
  death: number;
  kd: string;
  isMe: boolean;
  voice: ScoreboardVoice;
  bot: boolean;
  rank: number;
}
export interface ScoreboardData {
  visible: boolean;
  mode: "teams" | "ffa";
  myTeam: number;
  gamemode: string;
  map: string;
  team1Score: number | string;
  team2Score: number | string;
  team1: ScoreboardRow[];
  team2: ScoreboardRow[];
}
