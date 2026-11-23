
var lobbyPlayer = null;
var players = [];
var namedPlayers = {};
var display = false;

function stopNamedSound(soundId) {
  var audioPlayer = namedPlayers[soundId];
  if (!audioPlayer) {
    return;
  }

  delete namedPlayers[soundId];
  audioPlayer.stop();
  audioPlayer.unload();
}

function playNamedSequence(soundId, startFile, loopFile, volume) {
  stopNamedSound(soundId);

  var startPlayer = new Howl({
    src: ["./sounds/" + startFile],
    volume: volume,
    loop: false
  });

  namedPlayers[soundId] = startPlayer;
  startPlayer.on("end", function () {
    if (namedPlayers[soundId] !== startPlayer) {
      return;
    }

    startPlayer.unload();
    var loopPlayer = new Howl({
      src: ["./sounds/" + loopFile],
      volume: volume,
      loop: true
    });
    namedPlayers[soundId] = loopPlayer;
    loopPlayer.play();
  });
  startPlayer.play();
}

$(function () {
  window.addEventListener("message", function (event) {
    var data = event.data;

    if (data.openUrl) {
      window.invokeNative('openUrl', data.url);
    };



    if (
      event.data.transactionType !== undefined &&
      event.data.transactionType === "playSound"
    ) {
      var audioPlayer = new Howl({
        src: ["./sounds/" + event.data.transactionFile],
        volume: event.data.transactionVolume,
        loop: event.data.loop
      });
      if (event.data.soundId) {
        stopNamedSound(event.data.soundId);
        namedPlayers[event.data.soundId] = audioPlayer;
      }
      audioPlayer.play();
      if (!event.data.soundId) {
        players.push(audioPlayer);
      }
      if (event.data.isMusic) {
        lobbyPlayer = audioPlayer;
      }
      audioPlayer.on('end', function(){
        if (audioPlayer.loop()) {
          return;
        }
        if (event.data.soundId && namedPlayers[event.data.soundId] === audioPlayer) {
          delete namedPlayers[event.data.soundId];
        }
        var playerIndex = players.indexOf(audioPlayer);
        if (playerIndex !== -1) {
          players.splice(playerIndex, 1);
        }
        audioPlayer.unload();
      });
    }

    if (event.data.transactionType === "playSoundSequence") {
      playNamedSequence(
        event.data.soundId,
        event.data.startFile,
        event.data.loopFile,
        event.data.transactionVolume
      );
    }

    if (event.data.transactionType === "stopSound") {
      stopNamedSound(event.data.soundId);
    }

    if (
      event.data.transactionType !== undefined &&
      event.data.transactionType === "playSound3d"
    ) {
      var audioPlayer = new Howl({
        src: ["./sounds/" + event.data.transactionFile],
        loop: event.data.loop
      });
      audioPlayer.volume(parseFloat(event.data.transactionVolume));
      audioPlayer.pos(event.data.audioCoords.x,event.data.audioCoords.y,event.data.audioCoords.z);
      audioPlayer.orientation(parseFloat(event.data.audioRot.x),parseFloat(event.data.audioRot.y),parseFloat(event.data.audioRot.z))
      audioPlayer.pannerAttr({
        panningModel: 'equalpower',
        refDistance: 0.01,
        maxDistance: 500,
        rolloffFactor: 1,
        distanceModel: 'linear'
    })	
      audioPlayer.play();
      players.push(audioPlayer);
    }

    if (event.data.transactionType === "setMusicVolume") {
      if (lobbyPlayer !== null) {
        lobbyPlayer.volume(parseFloat(event.data.transactionVolume));
      }
    }

    if (event.data.transactionType === "yes") {
      players.forEach(function (player, index, array) {
        player.fade(player.volume(), 0.0, 500);
        var fadeOut = setInterval(function () {
          if (player.volume() <= 0.0) {
            player.pause();
            clearInterval(fadeOut);
            player.unload();
          }
        }, 500);
      });
      Object.keys(namedPlayers).forEach(stopNamedSound);
      players = []
      lobbyPlayer = null;

    }

    if (event.data.transactionType == "update") {
	    updateListerPos(event.data.pedCoord, event.data.pedRot);
    }

  })
});


function updateListerPos(pedCoord,pedRot){ 
	Howler.pos(pedCoord.x,pedCoord.y,pedCoord.z);
	Howler.orientation(pedRot.x ,pedRot.y,pedRot.z,0, 1, 0);	
}
