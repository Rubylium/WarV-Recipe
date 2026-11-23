import { createStateObject } from "../../Utils";
import { ServerBrowserData } from "../../types";

export const serverBrowser = createStateObject<ServerBrowserData>("SET_SERVER_BROWSER", {
  servers: [],
  error: "",
});
