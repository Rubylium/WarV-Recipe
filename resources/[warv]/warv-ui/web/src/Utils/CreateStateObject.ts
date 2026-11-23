import { EventPayload } from "../types";

export const createStateObject = <T>(eventName: string, defaultState: T) => {
  return (state: T = defaultState, data: EventPayload<T>) =>
    data.type === eventName ? data.payload : state;
};
