import Nui from "./FiveM";

interface UiError {
  kind: string;
  message: string;
  stack?: string;
  source?: string;
  line?: number;
  col?: number;
  componentStack?: string;
}

let lastKey = "";
let lastAt = 0;

export function reportUiError(err: UiError) {
  const key = `${err.kind}|${err.message}`;
  const now = Date.now();
  if (key === lastKey && now - lastAt < 1500) return;
  lastKey = key;
  lastAt = now;
  Nui.post("UI_ERROR", err);
}

export function installGlobalErrorHandlers() {
  window.addEventListener("error", (e: ErrorEvent) => {
    reportUiError({
      kind: "error",
      message: e.message || (e.error ? String(e.error) : "unknown error"),
      stack: e.error?.stack,
      source: e.filename || undefined,
      line: e.lineno || undefined,
      col: e.colno || undefined,
    });
  });

  window.addEventListener("unhandledrejection", (e: PromiseRejectionEvent) => {
    reportUiError({
      kind: "unhandledrejection",
      message: e.reason?.message || String(e.reason),
      stack: e.reason?.stack,
    });
  });

  const warned = new Set<string>();
  window.addEventListener(
    "error",
    (e: Event) => {
      const img = e.target as HTMLImageElement;
      if (img.tagName !== "IMG") return;
      const m = img.src.match(/\/assets\/images\/(.+?)(?:\?|$)/);
      const file = m ? decodeURIComponent(m[1]) : img.src;
      if (!file || warned.has(file)) return;
      warned.add(file);
      Nui.post("MISSING_IMAGE", { file });
    },
    true
  );
}
