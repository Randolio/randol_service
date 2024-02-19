fx_version 'cerulean'
game 'gta5'

author 'Randolio'
description 'Community Service'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
}

client_scripts {
    'bridge/client/**.lua',
    'cl_service.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/**.lua',
    'sv_service.lua'
}

lua54 'yes'
