fx_version "cerulean"
game "gta5"
lua54 "yes"

author "WarV"
description "WarV UI"
version "0.1.0"

ui_page "web/build/index.html"

loadscreen "loadscreen/index.html"
loadscreen_manual_shutdown "yes"

files {
  "web/build/index.html",
  "web/build/index.css",
  "web/build/asset-manifest.json",
  "web/build/manifest.json",
  "web/build/static/js/*.js",
  "web/build/static/css/*.css",
  "web/build/assets/fonts/**/*.woff2",
  "web/build/assets/fonts/**/*.woff",
  "web/build/assets/fonts/*.woff2",
  "web/build/assets/images/*.png",
  "web/build/assets/images/*.jpg",
  "web/build/assets/images/*/*.png",
  "web/build/assets/images/*/*.jpg",
  "web/build/assets/images/*/*/*.png",
  "web/build/assets/images/*/*/*.jpg",
  "web/build/assets/images/**/*.png",
  "web/build/assets/images/menu/callingcards/*.gif",
  "web/build/assets/images/**/*.jpg",

  "loadscreen/index.html",
  "loadscreen/styles.css",
  "loadscreen/motion.css",
  "loadscreen/loading.js",
  "loadscreen/howler.min.js",
  "loadscreen/loading_screen.jpg",
  "loadscreen/fonts/*.woff2",
  "loadscreen/sounds/*.ogg",
}

client_scripts {
  "typescript/dist/client.js",
}
