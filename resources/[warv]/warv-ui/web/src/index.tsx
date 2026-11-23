import { createRoot } from "react-dom/client";
import {
  Provider,
  TypedUseSelectorHook,
  useSelector as useReduxSelector,
} from "react-redux";
import { legacy_createStore } from "redux";
import App from "./App";
import ErrorBoundaryHost from "./ErrorBoundary";
import { installGlobalErrorHandlers } from "./errorReporting";
import Nui, { EventListener } from "./FiveM";
import "./index.css";
import rootReducer from "./reducer";

export const store = legacy_createStore(rootReducer, {});

type RootState = ReturnType<typeof rootReducer>;

export const useSelector: TypedUseSelectorHook<RootState> = useReduxSelector;

installGlobalErrorHandlers();

const container = document.getElementById("root")!;
const root = createRoot(container);

root.render(
  <Provider store={store}>
    <ErrorBoundaryHost>
      <App />
    </ErrorBoundaryHost>
    <EventListener />
  </Provider>
);

Nui.post("NUI_MOUNTED");
