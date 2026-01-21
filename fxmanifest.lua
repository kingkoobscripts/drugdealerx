fx_version "cerulean"
game "gta5"

author "SwisserAI"
description "DrugDealerX - Multi-Framework Drug System - Generated with SwisserAI - https://ai.swisser.dev"
version "1.2.0"

dependency "ox_lib"

ui_page "html/ui.html"

files {
    "html/ui.html",
    "html/style.css",
    "html/script.js"
}

shared_scripts {
    "@ox_lib/init.lua",
    "config/main.lua",
    "shared/bridge.lua"
}

client_scripts {
    "client/main.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/main.lua"
}