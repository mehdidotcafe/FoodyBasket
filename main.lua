-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- include the Corona "composer" module
local composer = require "composer"

system.activate( "multitouch" )

-- load menu screen
composer.gotoScene("srcs.views.loader")
