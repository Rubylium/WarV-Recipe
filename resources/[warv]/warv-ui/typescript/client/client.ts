import { GetCurrentScreen, RegisterNUICallback, SendUIMessage } from "./nui";
import { syncLoadscreenMusicVolume } from "./loadscreenAudio";

syncLoadscreenMusicVolume();

let focused = false;

setTick(() => {
  if (!focused) return;
  DisableControlAction(0, 199, true);
  DisableControlAction(0, 200, true);
});

const focusScreens = new Set([
  "menu",
  "gamemode_select",
  "server_browser",
  "lobby_wait",
  "class_editor",
  "weapon_picker",
  "attach_editor",
  "class_pick",
  "pause",
  "death",
  "killstreak_editor",
  "barracks",
  "leaderboard",
  "card_select",
  "emblem_select",
  "settings",
  "clothing_creator",
]);

function setFocus(focus: boolean, force = false): void {
  if (!force && focus === focused) return;
  focused = focus;
  if (focus) {
    SetNuiFocus(true, true);
    SetNuiFocusKeepInput(true);
  } else {
    SetNuiFocusKeepInput(false);
    SetNuiFocus(false, false);
  }
}

global.exports("GetScreen", () => GetCurrentScreen());
global.exports("RestoreFocusAfterChat", () => {
  if (focusScreens.has(GetCurrentScreen())) {
    setFocus(true, true);
  }
});

global.exports("ShowGamemodeSelect", () => {
  SendUIMessage("SET_SCREEN", "gamemode_select");
  setFocus(true);
});

global.exports("SetGamemodeData", (data: unknown) => {
  SendUIMessage("SET_GAMEMODE_DATA", data);
});

global.exports("ShowServerBrowser", () => {
  SendUIMessage("SET_SCREEN", "server_browser");
  setFocus(true);
});
global.exports("SetServerBrowser", (data: unknown) => {
  SendUIMessage("SET_SERVER_BROWSER", data);
});

global.exports("ShowLobbyWait", () => {
  SendUIMessage("SET_SCREEN", "lobby_wait");
  setFocus(true);
});
global.exports("SetLobbyWait", (data: unknown) => {
  SendUIMessage("SET_LOBBY_WAIT", data);
});

global.exports("ShowClassEditor", () => {
  SendUIMessage("SET_SCREEN", "class_editor");
  setFocus(true);
});
global.exports("SetClassSelect", (data: unknown) => {
  SendUIMessage("SET_CLASS_SELECT", data);
});

global.exports("ShowWeaponPicker", () => {
  SendUIMessage("SET_SCREEN", "weapon_picker");
  setFocus(true);
});
global.exports("SetWeaponPicker", (data: unknown) => {
  SendUIMessage("SET_WEAPON_PICKER", data);
});

global.exports("ShowAttachEditor", () => {
  SendUIMessage("SET_SCREEN", "attach_editor");
  setFocus(true);
});
global.exports("SetAttachEditor", (data: unknown) => {
  SendUIMessage("SET_ATTACH_EDITOR", data);
});
global.exports("SetAttachMarkers", (data: unknown) => {
  SendUIMessage("SET_ATTACH_MARKERS", data);
});

global.exports("ShowClassPick", () => {
  SendUIMessage("SET_SCREEN", "class_pick");
  setFocus(true);
});
global.exports("SetClassPick", (data: unknown) => {
  SendUIMessage("SET_CLASS_PICK", data);
});

global.exports("ShowPause", () => {
  SendUIMessage("SET_SCREEN", "pause");
  setFocus(true);
});

global.exports("ShowDeath", () => {
  SendUIMessage("SET_SCREEN", "death");
  setFocus(true);
});
global.exports("SetDeath", (data: unknown) => {
  SendUIMessage("SET_DEATH", data);
});

global.exports("ShowKillstreakEditor", () => {
  SendUIMessage("SET_SCREEN", "killstreak_editor");
  setFocus(true);
});
global.exports("SetKillstreakEditor", (data: unknown) => {
  SendUIMessage("SET_KILLSTREAK_EDITOR", data);
});

global.exports("ShowEndScreen", (data: unknown) => {
  SendUIMessage("SET_ENDSCREEN", data);
  SendUIMessage("SET_SCREEN", "endscreen");
  setFocus(false);
});
global.exports("HideEndScreen", () => {
  SendUIMessage("SET_SCREEN", "none");
  setFocus(false);
});

global.exports("SetScoreHud", (data: unknown) => {
  SendUIMessage("SET_SCORE_HUD", data);
});

global.exports("SetKillstreaks", (data: unknown) => {
  SendUIMessage("SET_KILLSTREAKS", data);
});

global.exports("SetWeaponHud", (data: unknown) => {
  SendUIMessage("SET_WEAPON_HUD", data);
});

global.exports("SetBlood", (alpha: number) => {
  SendUIMessage("SET_BLOOD", alpha);
});

global.exports("HudKill", (data: unknown) => {
  SendUIMessage("HUD_KILL", data);
});
global.exports("HudClear", () => {
  SendUIMessage("HUD_CLEAR", true);
});

global.exports("KsAnnounce", (data: unknown) => {
  SendUIMessage("KS_ANNOUNCE", data);
});

global.exports("NukeIncoming", (ms: number) => {
  SendUIMessage("NUKE_INCOMING", { ms });
});

global.exports("TypeText", (data: unknown) => {
  SendUIMessage("TYPE_TEXT", data);
});

global.exports("SetPodium", (data: unknown) => {
  SendUIMessage("SET_PODIUM", data);
});

global.exports("SetCruise", (data: unknown) => {
  SendUIMessage("SET_CRUISE", data);
});

global.exports("SetAirstrike", (data: unknown) => {
  SendUIMessage("SET_AIRSTRIKE", data);
});

global.exports("SetRcxd", (data: unknown) => {
  SendUIMessage("SET_RCXD", data);
});

global.exports("SetHeli", (data: unknown) => {
  SendUIMessage("SET_HELI", data);
});

global.exports("ScorePopup", (points: number, label: string) => {
  SendUIMessage("HUD_SCORE", { points, label });
});
global.exports("ScorePopupReset", () => {
  SendUIMessage("HUD_SCORE_RESET", true);
});

global.exports("ShowMedal", (data: Record<string, unknown>) => {
  SendUIMessage("HUD_NOTIFY", { kind: "medal", ...data });
});
global.exports("ClearMedals", () => {
  SendUIMessage("HUD_NOTIFY_CLEAR", { kind: "medal" });
});

global.exports("SetMatchIntro", (data: unknown) => {
  SendUIMessage("SET_MATCH_INTRO", data);
});
global.exports("SetIntroTag", (data: unknown) => {
  SendUIMessage("SET_INTRO_TAG", data);
});

global.exports("SetPlayerMarkers", (data: unknown) => {
  SendUIMessage("SET_PLAYER_MARKERS", data);
});

global.exports("SetVoiceChat", (data: unknown) => {
  SendUIMessage("SET_VOICE_CHAT", data);
});

global.exports("HitMarker", (data: unknown) => {
  SendUIMessage("HIT_MARKER", data);
});

global.exports("SetScoreboard", (data: unknown) => {
  SendUIMessage("SET_SCOREBOARD", data);
});

global.exports("SetOob", (data: unknown) => {
  SendUIMessage("SET_OOB", data);
});

global.exports("SetCountdown", (data: unknown) => {
  SendUIMessage("SET_COUNTDOWN", data);
});

global.exports("ResetGameHud", () => {
  SendUIMessage("SET_SCORE_HUD", {
    visible: false,
    teamMode: true,
    gamemode: "",
    gmIcon: "",
    timer: 0,
    maxScore: 0,
    left: { score: 0, label: "", logo: "", color: "blue" },
    right: { score: 0, label: "", logo: "", color: "red" },
  });
  SendUIMessage("SET_KILLSTREAKS", { visible: false, streaks: [] });
  SendUIMessage("SET_WEAPON_HUD", {
    visible: false,
    name: "",
    image: "",
    clip: 0,
    reserve: 0,
    clipMax: 0,
    grenade: -1,
  });
  SendUIMessage("SET_BLOOD", 0);
  SendUIMessage("SET_MATCH_INTRO", { visible: false });
  SendUIMessage("SET_INTRO_TAG", { visible: false });
  SendUIMessage("SET_OOB", { visible: false, seconds: 0, total: 0 });
  SendUIMessage("SET_COUNTDOWN", { visible: false, seconds: 0, label: "" });
  SendUIMessage("SET_PLAYER_MARKERS", []);
  SendUIMessage("SET_VOICE_CHAT", []);
  SendUIMessage("HIT_MARKER", { n: 0, kill: false });
  SendUIMessage("SET_SCOREBOARD", { visible: false });
  SendUIMessage("RESET_GAME_HUD", true);
});

global.exports("Notify", (kind: string, data?: Record<string, unknown>) => {
  SendUIMessage("HUD_NOTIFY", { kind, ...data });
});
global.exports("WeaponLevelUp", (data: Record<string, unknown>) => {
  SendUIMessage("HUD_NOTIFY", { kind: "weapon_level", ...data });
});

global.exports("ShowLoading", () => {
  SendUIMessage("SET_LOADING", { progress: 0, status: "" });
  SendUIMessage("SET_SCREEN", "loading");
  setFocus(false);
});

global.exports("SetLoadingProgress", (progress: number, status?: string) => {
  SendUIMessage("SET_LOADING", { progress, status: status || "" });
});

global.exports("ShowMatchLoading", () => {
  SendUIMessage("SET_SCREEN", "match_loading");
  setFocus(false);
});
global.exports("SetMatchLoading", (data: unknown) => {
  SendUIMessage("SET_MATCH_LOADING", data);
});

global.exports("HideUI", () => {
  SendUIMessage("SET_SCREEN", "none");
  setFocus(false);
});

global.exports("ShowMainMenu", () => {
  SendUIMessage("SET_SCREEN", "menu");
  setFocus(true);
});

global.exports("HideMainMenu", () => {
  SendUIMessage("SET_SCREEN", "none");
  setFocus(false);
});

global.exports("SetMenuData", (data: unknown) => {
  SendUIMessage("SET_MENU_DATA", data);
});

global.exports("ShowBarracks", () => {
  SendUIMessage("SET_SCREEN", "barracks");
  setFocus(true);
});
global.exports("SetBarracksData", (data: unknown) => {
  SendUIMessage("SET_BARRACKS", data);
});

global.exports("SetChallenges", (data: unknown) => {
  SendUIMessage("SET_CHALLENGES", data);
});

global.exports("SetFriends", (data: unknown) => {
  SendUIMessage("SET_FRIENDS", data);
});

global.exports("ShowLeaderboard", () => {
  SendUIMessage("SET_SCREEN", "leaderboard");
  setFocus(true);
});
global.exports("SetLeaderboard", (data: unknown) => {
  SendUIMessage("SET_LEADERBOARD", data);
});

global.exports("ShowCardSelect", () => {
  SendUIMessage("SET_SCREEN", "card_select");
  setFocus(true);
});
global.exports("SetCardSelect", (data: unknown) => {
  SendUIMessage("SET_CARD_SELECT", data);
});

global.exports("ShowEmblemSelect", () => {
  SendUIMessage("SET_SCREEN", "emblem_select");
  setFocus(true);
});
global.exports("SetEmblemSelect", (data: unknown) => {
  SendUIMessage("SET_EMBLEM_SELECT", data);
});

global.exports("ShowSettings", () => {
  SendUIMessage("SET_SCREEN", "settings");
  setFocus(true);
});
global.exports("SetSettingsData", (data: unknown) => {
  SendUIMessage("SET_SETTINGS", data);
});

global.exports("ShowClothingCreator", () => {
  SendUIMessage("SET_SCREEN", "clothing_creator");
  setFocus(true);
});
global.exports("SetClothingCreator", (data: unknown) => {
  SendUIMessage("SET_CLOTHING_CREATOR", data);
});
global.exports("SetClothingLimits", (data: unknown) => {
  SendUIMessage("SET_CLOTHING_LIMITS", data);
});

let uiMounted = false;
RegisterNUICallback("NUI_MOUNTED", (_data, cb) => {
  uiMounted = true;
  cb("yes");
});
global.exports("IsMounted", () => uiMounted);

interface UiErrorPayload {
  kind?: string;
  message?: string;
  stack?: string;
  source?: string;
  line?: number;
  col?: number;
  componentStack?: string;
}
RegisterNUICallback<UiErrorPayload>("UI_ERROR", (data, cb) => {
  const parts: string[] = [];
  parts.push(`^1[warv-ui] UI error^7 (${data.kind || "error"})`);
  if (data.message) parts.push(`  ${data.message}`);
  if (data.source) {
    parts.push(`  at ${data.source}:${data.line ?? "?"}:${data.col ?? "?"}`);
  }
  if (data.stack) parts.push(String(data.stack));
  if (data.componentStack) parts.push(`  component stack:${data.componentStack}`);
  console.log(parts.join("\n"));
  emitNet("warv:reportClientError", data);
  cb("yes");
});

RegisterNUICallback<{ file?: string }>("MISSING_IMAGE", (data, cb) => {
  console.log(`^3[warv-ui] missing image: ${data.file || "?"}^7`);
  cb("yes");
});

RegisterNUICallback<{ name?: string }>("UI_SOUND", (data, cb) => {
  emit("warv-ui:playSound", data.name || "");
  cb("yes");
});

RegisterNUICallback<{ action: string; id?: number }>("MENU_ACTION", (data, cb) => {
  emit("warv-ui:menuAction", data);
  cb("yes");
});

RegisterNUICallback<{ dx?: number; dy?: number }>("GUNSMITH_DRAG", (data, cb) => {
  emit("warv-ui:gunsmithDrag", data);
  cb("yes");
});

RegisterNUICallback<{ slot?: string; dx?: number; dy?: number }>("GUNSMITH_ANCHOR_DRAG", (data, cb) => {
  emit("warv-ui:gunsmithAnchorDrag", data);
  cb("yes");
});

RegisterNUICallback<{ dx?: number; dy?: number }>("GUNSMITH_MOVE", (data, cb) => {
  emit("warv-ui:gunsmithMove", data);
  cb("yes");
});

RegisterNUICallback<{ kind?: string; x?: number; y?: number; dx?: number; dy?: number; shift?: boolean }>(
  "MAP_EDITOR_INPUT",
  (data, cb) => {
    emit("warv-ui:mapEditorInput", data);
    cb("yes");
  }
);

global.exports("ShowMapEditor", () => {
  SendUIMessage("SET_SCREEN", "map_editor");
  setFocus(true);
});
global.exports("SetMapEditor", (data: unknown) => {
  SendUIMessage("SET_MAP_EDITOR", data);
});

RegisterNUICallback<{ kind?: string }>("PROP_EDITOR_INPUT", (data, cb) => {
  emit("warv-ui:propEditorInput", data);
  cb("yes");
});

global.exports("ShowPropEditor", () => {
  SendUIMessage("SET_SCREEN", "prop_editor");
  setFocus(true);
});
global.exports("SetPropEditor", (data: unknown) => {
  SendUIMessage("SET_PROP_EDITOR", data);
});
global.exports("SetPropEditorLive", (data: unknown) => {
  SendUIMessage("SET_PROP_EDITOR_LIVE", data);
});
global.exports("SetEditorCursor", (visible: boolean) => {
  SetNuiFocus(true, visible);
  SetNuiFocusKeepInput(true);
});

RegisterNUICallback<{ dx?: number; dy?: number; wheel?: number }>("CLOTHING_CAMERA", (data, cb) => {
  emit("warv-ui:clothingCamera", data);
  cb("yes");
});

on("loading:finish", () => {
  SendLoadingScreenMessage(JSON.stringify({ shut: "yes" }));
  setTimeout(() => ShutdownLoadingScreenNui(), 1500);
});

on("onResourceStop", (resource: string) => {
  if (resource === GetCurrentResourceName() && focused) {
    SetNuiFocusKeepInput(false);
    SetNuiFocus(false, false);
  }
});
