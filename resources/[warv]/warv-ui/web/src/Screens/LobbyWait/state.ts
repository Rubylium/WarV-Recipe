import { createStateObject } from "../../Utils";
import { LobbyWaitData } from "../../types";

export const lobbyWait = createStateObject<LobbyWaitData>("SET_LOBBY_WAIT", {
  ranked: false,
  gamemode: "",
  maxPlayers: 0,
  playersInLobby: 0,
  players: [],
  myRankingIcon: "",
  state: "searching",
  queuePlace: 0,
  queueTotal: 0,
  timer: 0,
  voted: false,
  vote: null,
  selectedMap: null,
});
