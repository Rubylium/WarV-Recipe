let currentScreen = "none";

export function RegisterNUICallback<T, P = "yes">(
  eventName: string,
  callback: (data: T, cb: (response: P) => void) => void
) {
  RegisterNuiCallbackType(eventName);
  on(`__cfx_nui:${eventName}`, callback);
}

export function SendUIMessage(type: string, payload: unknown) {
  if (type === "SET_SCREEN") {
    currentScreen = typeof payload === "string" ? payload : "none";
  }
  SendNuiMessage(JSON.stringify({ type, payload }));
}

export function GetCurrentScreen() {
  return currentScreen;
}
