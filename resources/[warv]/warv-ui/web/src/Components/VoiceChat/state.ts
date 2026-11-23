import { createStateObject } from "../../Utils";
import { VoicePlayer } from "../../types";

export const voiceChat = createStateObject<VoicePlayer[]>("SET_VOICE_CHAT", []);
