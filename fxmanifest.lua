fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rodz-piloto'
author 'Rodz Development | MRI'
version '1.2.0'
description 'Sistema de Piloto Aéreo - Qbox | MRI | QBCore'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/*.lua',
    'config.lua'
}

client_scripts {
    'shared/utils.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/utils.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/planes/*.png',
    'html/img/planes/*.jpg',
    'html/img/planes/*.webp'
}

-- Framework detectado automaticamente em runtime: Qbox (qbx_core) | QBCore (qb-core) | MRI
dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql'
}