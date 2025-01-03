fx_version "cerulean"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game {'rdr3'}
lua54 'yes'

name 'PyThor_StockMarket'
author 'PyThor'
description 'In depth stock market system with missions'

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua',
    '@oxmysql/lib/MySQL.lua'
}

shared_scripts {
    'shared/*.lua'
}

dependencies {
    'vorp_core',
    'bcc-utils',
    'feather-menu'
}

