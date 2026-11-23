import { createStateObject } from "../../Utils";
import { FriendsData } from "../../types";

export const friends = createStateObject<FriendsData>("SET_FRIENDS", {
  friends: [],
  incoming: [],
  outgoing: [],
  blocked: [],
  hidden: false,
  cap: 100,
});
