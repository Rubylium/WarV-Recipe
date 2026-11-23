import { combineReducers } from "redux";
import { screen } from "./App/state";
import { loading } from "./Screens/LoadingScreen/state";
import { matchLoading } from "./Screens/MatchLoading/state";
import { scoreHud } from "./Components/ScoreHud/state";
import { killstreaks } from "./Components/KillstreakHud/state";
import { weaponHud } from "./Components/WeaponHud/state";
import { blood } from "./Components/BloodScreen/state";
import { gamemodeSelect } from "./Screens/GamemodeSelect/state";
import { serverBrowser } from "./Screens/ServerBrowser/state";
import { lobbyWait } from "./Screens/LobbyWait/state";
import { classSelect } from "./Screens/ClassEditor/state";
import { weaponPicker } from "./Screens/WeaponPicker/state";
import { attachEditor, attachMarkers } from "./Screens/AttachEditor/state";
import { classPick } from "./Screens/ClassPick/state";
import { death } from "./Screens/Death/state";
import { matchIntro } from "./Components/MatchIntro/state";
import { introTag } from "./Components/IntroNameplate/state";
import { oob } from "./Components/OutOfBounds/state";
import { countdown } from "./Components/Countdown/state";
import { playerMarkers } from "./Components/PlayerMarkers/state";
import { voiceChat } from "./Components/VoiceChat/state";
import { hitMarker } from "./Components/HitMarker/state";
import { scoreboard } from "./Components/Scoreboard/state";
import { killstreakEditor } from "./Screens/KillstreakEditor/state";
import { endScreen } from "./Screens/EndScreen/state";
import { menuData } from "./Screens/MainMenu/state";
import { barracks } from "./Screens/Barracks/state";
import { leaderboard } from "./Screens/Leaderboard/state";
import { friends } from "./Components/FriendsPanel/state";
import { challenges } from "./Components/Challenges/state";
import { cardSelect } from "./Screens/CardSelect/state";
import { emblemSelect } from "./Screens/EmblemSelect/state";
import { settings } from "./Screens/Settings/state";
import { clothingCreator } from "./Screens/ClothingCreator/state";
import { mapEditor } from "./Screens/MapEditor/state";
import { propEditor, propEditorLive } from "./Screens/PropEditor/state";

const hudGeneration = (state = 0, action: { type: string }) =>
  action.type === "RESET_GAME_HUD" ? state + 1 : state;

const rootReducer = combineReducers({
  screen,
  loading,
  matchLoading,
  scoreHud,
  killstreaks,
  weaponHud,
  blood,
  gamemodeSelect,
  serverBrowser,
  lobbyWait,
  classSelect,
  weaponPicker,
  attachEditor,
  attachMarkers,
  classPick,
  death,
  matchIntro,
  introTag,
  oob,
  countdown,
  playerMarkers,
  voiceChat,
  hitMarker,
  scoreboard,
  killstreakEditor,
  endScreen,
  menuData,
  barracks,
  leaderboard,
  friends,
  challenges,
  cardSelect,
  emblemSelect,
  settings,
  clothingCreator,
  mapEditor,
  propEditor,
  propEditorLive,
  hudGeneration,
});

export default rootReducer;
