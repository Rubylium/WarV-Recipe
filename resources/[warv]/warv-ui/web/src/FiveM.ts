import { store } from ".";

const isDev = !(window as any).GetParentResourceName;

export default class Nui {
  public static post(event: string, data = {}) {
    if (isDev) return null;
    return fetch(`https://${(window as any).GetParentResourceName()}/${event}`, {
      method: "post",
      headers: { "Content-type": "application/json; charset=UTF-8" },
      body: JSON.stringify(data),
    });
  }

  public static emitEvent(type: string, payload?: any) {
    window.dispatchEvent(new MessageEvent("message", { data: { type, payload } }));
  }

  public static clearSelection() {
    window.getSelection()!.removeAllRanges();
  }
}

const messageCallback = (e: MessageEvent) => {
  if (e.data && e.data.type) {
    store.dispatch({ type: e.data.type, payload: e.data.payload });
  }
};

export const EventListener = () => {
  window.addEventListener("message", messageCallback);
  return null;
};

if (isDev) {
  (window as any).Nui = Nui;
}
