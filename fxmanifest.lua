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

-- version must match version.file
version '2.0'
vorp_checker 'yes'
-- can use color codes ^1
vorp_name '^5PyThor_StockMarket ^4version Check^3' 
-- path to the github repository, in here it must have a version.file file type where your change logs will be, also must be public repository
vorp_github 'https://github.com/PyThor97/PyThor_StockMarket'
