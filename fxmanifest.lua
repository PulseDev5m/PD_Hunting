fx_version 'cerulean'
game 'gta5'

author 'Pulse Development'
Name 'PD_HuntingScript'
description 'Advanced Hunting System with Goals & Discord Rewards'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'

