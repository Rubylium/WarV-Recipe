let kills = [];
let lastShown = -1;
let lastAdded = -1;
let killsShowing = 0;
var $killFeedContainer = null;
var $killFeedElement = null;

var tagBody = "(?:[^\"'>]|\"[^\"]*\"|'[^']*')*";

var tagOrComment = new RegExp(
  "<(?:" +
  "!--(?:(?:-*[^->])*--+|-?)" +
  "|script\\b" +
  tagBody +
  ">[\\s\\S]*?</script\\s*" +
  "|style\\b" +
  tagBody +
  ">[\\s\\S]*?</style\\s*" +
  "|/?[a-z]" +
  tagBody +
  ")>",
  "gi"
);
function removeTags(html) {
  var oldHtml;
  do {
    oldHtml = html;
    html = html.replace(tagOrComment, "");
  } while (html !== oldHtml);
  return html.replace(/</g, "&lt;");
}

const fakeNames = [
  "Cody",
  "Shaun Becker",
  "Catherine",
  "Bob",
  "Snowy",
  "Summer",
  "John Smith",
];
$(function () {
  $killFeedContainer = $(".kill-feed");
  $killFeedElement = $(".kill-feed > div").hide();

  window.addEventListener("message", function (event) {
    if (event.data.type === "kill") {
      let killer = removeTags(event.data.killer);
      if (killer === "")
        killer = fakeNames[Math.floor(Math.random() * fakeNames.length)];
      let victim = removeTags(event.data.victim);
      if (victim === "")
        victim = fakeNames[Math.floor(Math.random() * fakeNames.length)];
      const weapon = event.data.weapon;
      const headshot = event.data.headshot;
      const killerTeam = event.data.killerTeam;
      const victimTeam = event.data.victimTeam;
      const myTeam = event.data.myTeam;
      addKill(killer, victim, weapon, headshot, killerTeam, victimTeam, myTeam);
    }
  });
  // $(document).on("contextmenu", function (e) {
  //     e.preventDefault();
  //   });
});

const handleKillFeed = () => {
  const killToShow = kills.find((k) => k.shown === false);
  const index = kills.indexOf(killToShow);
  if (killToShow === null || killToShow === undefined || index === -1) {
    return;
  }
  killToShow.shown = true;
  kills[index] = killToShow;
  kills.splice(index, 1);

  var $newFeedElement = $killFeedElement.clone();
  if (killToShow.weapon === "suicide") {
    $newFeedElement
      .find(".weapons img:first-child")
      .attr("src", "./imgs/suicide_skull.png");
    $newFeedElement.find(".victim").css("color", "#d1d1d1");
    $newFeedElement.find(".victim").text(killToShow.killer + " Mistakes were made.");
  } else {
    if (killToShow.headshot == false) {
      $newFeedElement
        .find(".weapons img:first-child")
        .attr("src", "./imgs/" + killToShow.weapon + ".png");
    } else {
      $newFeedElement
        .find(".weapons img:first-child")
        .attr("src", "./imgs/death_headshot.png");
    }

    if (killToShow.killerTeam === killToShow.myTeam) {
      $newFeedElement.find(".killer").css("color", "#5fb2ff");
    } else {
      $newFeedElement.find(".killer").css("color", "#ff5f5f");
    }

    if (killToShow.victimTeam === killToShow.myTeam) {
      $newFeedElement.find(".victim").css("color", "#5fb2ff");
    } else {
      $newFeedElement.find(".victim").css("color", "#ff5f5f");
    }

    $newFeedElement.find(".killer").text(killToShow.killer);
    $newFeedElement.find(".victim").text(killToShow.victim);
  }


  $killFeedContainer.append(
    $newFeedElement
      .show()
      .delay(3000)
      .fadeOut(1000, function () {
        $(this).remove();
      })
  );

  //kills.splice(index, 1);
  //console.log(kills.length);
  //console.log(`kill ${kills[index]?.killer ?? 'doesnt exist'} vs ${killToShow.killer}`);
};
const addKill = (k, v, w, h, killerTeam, victimTeam, myTeam) => {
  kills.push({
    killer: k,
    victim: v,
    weapon: w,
    headshot: h,
    killerTeam: killerTeam,
    victimTeam: victimTeam,
    myTeam: myTeam,
    shown: false,
    time: Date.now(),
  });
};

window.setInterval(() => {
  handleKillFeed();
}, 50);
