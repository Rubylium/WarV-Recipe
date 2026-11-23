import { ComponentType, Fragment, useEffect, useState } from "react";
import { useSelector } from "..";
import GamemodeSelect from "../Screens/GamemodeSelect";
import ServerBrowser from "../Screens/ServerBrowser";
import LobbyWait from "../Screens/LobbyWait";
import AttachEditor from "../Screens/AttachEditor";
import MapEditor from "../Screens/MapEditor";
import PropEditor from "../Screens/PropEditor";
import ClassPick from "../Screens/ClassPick";
import PauseMenu from "../Screens/PauseMenu";
import DeathScreen from "../Screens/Death";
import LoadingScreen from "../Screens/LoadingScreen";
import MatchLoading from "../Screens/MatchLoading";
import EndScreen from "../Screens/EndScreen";
import LobbyShell from "../Components/LobbyShell";
import MainMenu from "../Screens/MainMenu";
import Barracks from "../Screens/Barracks";
import Leaderboard from "../Screens/Leaderboard";
import ClassEditor from "../Screens/ClassEditor";
import WeaponPicker from "../Screens/WeaponPicker";
import CardSelect from "../Screens/CardSelect";
import EmblemSelect from "../Screens/EmblemSelect";
import Settings from "../Screens/Settings";
import KillstreakEditor from "../Screens/KillstreakEditor";
import Killfeed from "../Components/Killfeed";
import ScorePopup from "../Components/ScorePopup";
import MatchIntro from "../Components/MatchIntro";
import IntroNameplate from "../Components/IntroNameplate";
import OutOfBounds from "../Components/OutOfBounds";
import Countdown from "../Components/Countdown";
import PlayerMarkers from "../Components/PlayerMarkers";
import VoiceChat from "../Components/VoiceChat";
import HitMarker from "../Components/HitMarker";
import Scoreboard from "../Components/Scoreboard";
import Notifications from "../Components/Notifications";
import KsAnnounce from "../Components/KsAnnounce";
import NukeIncoming from "../Components/NukeIncoming";
import TypeText from "../Components/TypeText";
import Podium from "../Components/Podium";
import CruiseHud from "../Components/CruiseHud";
import AirstrikeHud from "../Components/AirstrikeHud";
import RcxdHud from "../Components/RcxdHud";
import HeliHud from "../Components/HeliHud";
import ScoreHud from "../Components/ScoreHud";
import KillstreakHud from "../Components/KillstreakHud";
import WeaponHud from "../Components/WeaponHud";
import BloodScreen from "../Components/BloodScreen";
import Nui from "../FiveM";
import ClothingCreator from "../Screens/ClothingCreator";

const lobbyFamily = ["menu", "gamemode_select", "server_browser", "leaderboard", "class_editor", "weapon_picker", "killstreak_editor", "barracks", "card_select", "emblem_select", "settings", "clothing_creator"];

const TransitionHost = ({ active, ms, screen: Screen }: { active: boolean; ms: number; screen: ComponentType<{ closing: boolean }> }) => {
  const [mounted, setMounted] = useState(false);
  const [closing, setClosing] = useState(false);

  useEffect(() => {
    if (active) {
      setMounted(true);
      setClosing(false);
      return;
    }
    if (mounted) {
      setClosing(true);
      const t = setTimeout(() => setMounted(false), ms);
      return () => clearTimeout(t);
    }
  }, [active, mounted, ms]);

  if (!mounted) return null;
  return <Screen closing={closing} />;
};

const App = () => {
  const screen = useSelector((s) => s.screen);
  const hudGeneration = useSelector((s) => s.hudGeneration);

  useEffect(() => {
    Nui.clearSelection();
  }, [screen]);

  return (
    <>
      <Fragment key={hudGeneration}>
        <BloodScreen />
        <ScoreHud />
        <KillstreakHud />
        <WeaponHud />
        <Killfeed />
        <ScorePopup />
        <MatchIntro />
        <IntroNameplate />
        <OutOfBounds />
        <Countdown />
        <PlayerMarkers />
        <VoiceChat />
        <HitMarker />
        <Scoreboard />
        <Notifications />
        <KsAnnounce />
        <NukeIncoming />
        <TypeText />
        <Podium />
        <CruiseHud />
        <AirstrikeHud />
        <RcxdHud />
        <HeliHud />
      </Fragment>

      {screen === "lobby_wait" && <LobbyWait />}
      {screen === "attach_editor" && <AttachEditor />}
      {screen === "map_editor" && <MapEditor />}
      {screen === "prop_editor" && <PropEditor />}
      {screen === "class_pick" && <ClassPick />}
      <TransitionHost active={screen === "pause"} ms={240} screen={PauseMenu} />
      <TransitionHost active={screen === "death"} ms={260} screen={DeathScreen} />
      <TransitionHost active={screen === "endscreen"} ms={650} screen={EndScreen} />
      <TransitionHost active={screen === "match_loading"} ms={650} screen={MatchLoading} />

      {lobbyFamily.includes(screen) && (
        <LobbyShell screen={screen}>
          {screen === "menu" && <MainMenu />}
          {screen === "gamemode_select" && <GamemodeSelect />}
          {screen === "server_browser" && <ServerBrowser />}
          {screen === "class_editor" && <ClassEditor />}
          {screen === "weapon_picker" && <WeaponPicker />}
          {screen === "killstreak_editor" && <KillstreakEditor />}
          {screen === "barracks" && <Barracks />}
          {screen === "leaderboard" && <Leaderboard />}
          {screen === "card_select" && <CardSelect />}
          {screen === "emblem_select" && <EmblemSelect />}
          {screen === "settings" && <Settings />}
          {screen === "clothing_creator" && <ClothingCreator />}
        </LobbyShell>
      )}

      <TransitionHost active={screen === "loading"} ms={860} screen={LoadingScreen} />
    </>
  );
};

export default App;
