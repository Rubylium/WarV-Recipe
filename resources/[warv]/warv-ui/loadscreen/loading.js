(function () {
  var themes = ["theme_1", "theme_2", "theme_3", "theme_4", "theme_5"];
  var pick = themes[Math.floor(Math.random() * themes.length)];
  var audio = new Howl({ src: ["sounds/" + pick + ".ogg"], loop: true, volume: 0.05 });
  audio.play();

  var ls = document.getElementById("ls");
  var fill = document.getElementById("fill");
  var pctEl = document.getElementById("pct");
  var statusEl = document.getElementById("status");
  var target = 0, shown = 0, done = false;

  function setStatus(t) { if (t) statusEl.textContent = t; }

  window.addEventListener("message", function (e) {
    var d = e.data || {};

    if (d.shut === "yes") {
      if (done) return;
      done = true; target = 100;
      setStatus("Deploying");
      setTimeout(function () { ls.classList.add("ls--closing"); }, 300);
      audio.fade(audio.volume(), 0, 1000);
      setTimeout(function () { audio.stop(); }, 1100);
      return;
    }

    if (d.audioCategory === "music" && Number.isFinite(d.volume)) {
      audio.volume(d.volume);
      return;
    }

    if (done) return;

    switch (d.eventName) {
      case "loadProgress":
        if (Number.isFinite(d.loadFraction)) {
          target = Math.max(0, Math.min(100, d.loadFraction * 100));
        }
        break;
      case "startInitFunctionOrder":
      case "initFunctionInvoking":
        setStatus("Initializing world");
        break;
      case "startDataFileEntries":
        setStatus("Mounting data files");
        break;
      case "onDataFileEntry":
        setStatus("Streaming assets");
        break;
      case "performMapLoadFunction":
        setStatus("Building map");
        break;
    }
  });

  function raf() {
    shown += (target - shown) * 0.12;
    if (Math.abs(target - shown) < 0.3) shown = target;
    fill.style.width = shown + "%";
    pctEl.textContent = Math.floor(shown);
    requestAnimationFrame(raf);
  }
  requestAnimationFrame(raf);
})();
