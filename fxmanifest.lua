fx_version 'cerulean'
game 'gta5'
author 'Torque'
lua54 'yes'

description 'Custom Vehicle Repair Points'
version '1.1.0'

shared_script '@ox_lib/init.lua'

ui_page 'html/ui.html'
files {
    'html/ui.html',
    'html/sounds/impact_wrench.ogg'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
