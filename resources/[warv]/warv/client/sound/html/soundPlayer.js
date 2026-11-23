let activeSounds = {};
let playerCoordinates = { x: 0.0, y: 0.0, z: 0.0, };
var players = [];

function updatePosition(coordinates, camera, volume) {
    playerCoordinates = coordinates;

    Howler.pos(coordinates.x, coordinates.y, coordinates.z);
    Howler.orientation(camera.x, camera.y, camera.z, 0, 0, 1);
    Howler.volume(1.0);

    _.forEach(activeSounds, (_, soundId) => {
        updateVolume(soundId);
    });
}

function updateSoundPosition(soundId, coordinates) {
    if (typeof activeSounds[soundId] === 'undefined') {
        return;
    }

    _.forEach(coordinates, (coordinate, key) => {
        if (typeof activeSounds[soundId].howlerIds[key] !== 'undefined') {
            activeSounds[soundId].howlerSound.pos(coordinate.x, coordinate.y, coordinate.z, activeSounds[soundId].howlerIds[key]);
        }
    });

    activeSounds[soundId].coordinates = coordinates;

    updateVolume(soundId);
}

function GetSoundForDistance(maxVolume, minVolume, maxDistance, distance) {
    if (distance >= maxDistance) {
        return 0.0;
    } else {
        let volume = maxVolume - (distance / maxDistance) * maxVolume
        if (volume < minVolume) {
            volume = minVolume;
        }

        if (volume > maxVolume) {
            volume = maxVolume;
        }

        return volume;
    }
}

function updateVolume(soundId) {
    if (typeof activeSounds[soundId] === 'undefined') {
        return;
    }

    let newVolume = GetSoundForDistance(activeSounds[soundId].maxVolume, activeSounds[soundId].minVolume, activeSounds[soundId].maxDistanceSound, activeSounds[soundId].distance);

    _.forEach(activeSounds[soundId].coordinates, (coordinate, key) => {
        if (coordinate === 'self') {
            activeSounds[soundId].howlerSound.volume(activeSounds[soundId].volume, activeSounds[soundId].howlerIds[key]);
        } else {
            let volume = newVolume

            if (volume < 0) {
                volume = 0.0;
                stopSound(soundId)
            }

            if (activeSounds[soundId].howlerIds[key]) {
                activeSounds[soundId].howlerSound.volume(volume, activeSounds[soundId].howlerIds[key]);
            }
        }
    });
}

function addSound(eventData) {
    let howlerSound = new Howl({
        src: [`/sounds/${eventData.soundName}.ogg`],
        loop: eventData.isLooped,

        onplayerror: function (id, error) {
            console.log('Error with sound ', eventData.soundName, error);
        },
        onend: function () {
            if (activeSounds[eventData.soundId].isLooped) {
                return;
            }

            soundFinished(eventData.soundId);
        }
    });

    let howlerIds = [];

    _.forEach(eventData.coordinates, (coordinate, key) => {
        howlerIds[key] = howlerSound.play();

        if (coordinate === 'self') {
            howlerSound.volume(eventData.volume, howlerIds[key]);
        } else {
            howlerSound.pannerAttr({
                panningModel: 'HRTF',
                rolloffFactor: 1,
                distanceModel: 'linear',
            }, howlerIds[key]);

            howlerSound.pos(coordinate.x, coordinate.y, coordinate.z, howlerIds[key]);
        }
    });

    activeSounds[eventData.soundId] = {
        howlerSound: howlerSound,
        howlerIds: howlerIds,
        name: eventData.soundName,
        coordinates: eventData.coordinates,
        maxDistance: eventData.maxDistance,
        isLooped: eventData.isLooped,
        maxVolume: eventData.maxVolume,
        minVolume: eventData.minVolume,
        maxDistanceSound: eventData.maxDistanceSound,
        distance: eventData.distance,
    }

    howlerSound.on('end', () => {
        if (activeSounds[eventData.soundId].isLooped) {
            return;
        }
        activeSounds[eventData.soundId].howlerSound.unload();
    });
}

function stopSound(soundId) {
    if (typeof activeSounds[soundId] === 'undefined') {
        return;
    }

    activeSounds[soundId].howlerSound.unload();

    soundFinished(soundId);
}

function soundFinished(soundId) {
    fetch(`https://${GetParentResourceName()}/soundEnded`, {
        method: 'POST',

        headers: {
            'Content-Type': 'application/json',
        },

        body: JSON.stringify({
            soundId: soundId,
        }),
    }).then(() => { });

    delete activeSounds[soundId];

    if (!_.isEmpty(activeSounds)) {
        return;
    }

}

window.addEventListener('message', (event) => {
    const eventData = event.data;

    if (eventData.type === 'position') {
        updatePosition(eventData.coordinates, eventData.camera, eventData.volume);

        return;
    }

    if (eventData.type === 'soundPosition') {
        updateSoundPosition(eventData.soundId, eventData.coordinates);

        return;
    }

    if (eventData.type === 'play') {
        addSound(eventData);

        return;
    }

    if (eventData.type === 'stop') {
        stopSound(eventData.soundId);

        return;
    }

    if (eventData.type === 'playNormalSound') {
        var audioPlayer = new Howl({
            src: [`/sounds/${eventData.soundName}.ogg`],
            loop: eventData.isLooped
        });
        audioPlayer.volume(eventData.volume);
        audioPlayer.play();
        players.push(audioPlayer);
        audioPlayer.on('end', function () {
            var fadeOut = setInterval(function () {
                if (!audioPlayer.loop) {
                    audioPlayer.unload();
                    clearInterval(fadeOut);
                    soundFinished(eventData.soundId)
                }

            }, 500);

        });
    }

    if (eventData.type === 'stopAllNormalSounds') {
        players.forEach(function (player, index, array) {
            player.fade(player.volume(), 0.0, 300);
            var fadeOut = setInterval(function () {
                if (player.volume() <= 0.0) {
                    player.pause();
                    clearInterval(300);
                    player.unload();
                }
            }, 300);
        });
        players = []

    }

    if (eventData.type === 'stopAllNormalSoundsWithTimeout') {
        players.forEach(function (player, index, array) {
            player.fade(player.volume(), 0.0, eventData.fadeOutDuration);
            var fadeOut = setInterval(function () {
                if (player.volume() <= 0.0) {
                    player.pause();
                    clearInterval(fadeOut);
                    player.unload();
                }
            }, eventData.fadeOutDuration);
        });
        players = []

    }
});
