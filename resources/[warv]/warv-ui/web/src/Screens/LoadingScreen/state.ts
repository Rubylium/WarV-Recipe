import { createStateObject } from "../../Utils";
import { LoadingData } from "../../types";

export const loading = createStateObject<LoadingData>("SET_LOADING", {
  progress: 0,
  status: "",
});
