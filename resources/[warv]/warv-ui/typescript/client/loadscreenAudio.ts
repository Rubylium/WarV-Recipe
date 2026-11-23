const musicReferenceVolume = 0.02;
const loadscreenBaseVolume = 0.05;

export function syncLoadscreenMusicVolume(): void {
  const zeroSafe = GetExternalKvpInt("warv", "AUDIO_SETTINGS_ZERO_SAFE_V1") === 1;
  const storedVolume = GetExternalKvpFloat("warv", "MUSIC_VOLUME_NEW");
  const musicVolume = storedVolume === 0 && !zeroSafe ? musicReferenceVolume : storedVolume;
  const multiplier = Math.max(0, Math.min(3, musicVolume / musicReferenceVolume));

  SendLoadingScreenMessage(JSON.stringify({
    audioCategory: "music",
    volume: Math.max(0, Math.min(1, loadscreenBaseVolume * multiplier)),
  }));
}
