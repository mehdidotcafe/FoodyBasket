require "srcs.Store"

local composer = require("composer")
local pm = require "srcs.PurchaseManager"
local sm = require "srcs.sound.SoundManager"
local DB = require "srcs.db.DB"
local scene = composer.newScene()
local bg = display.newRect(display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
local logo

-- composer.recycleOnSceneChange = true

function scene:create(event)
  local sceneGroup = self.view
  local s

  bg:setFillColor(41 / 255, 21  / 255, 78  / 255)
  logo = display.newImageRect("img/loader-background.png", display.actualContentHeight * 1600 / 900, display.actualContentHeight)
  logo.x = display.contentCenterX
  logo.y = display.contentCenterY
  sceneGroup:insert(bg)
  sceneGroup:insert(logo)

  require "srcs.Translator"
  Translator:init()

  s = Store:new()
  pm:init()
  sm:init()

  s:load(#pm.buyablePoints)

  local function epilogue()
    composer.gotoScene("srcs.views.menu", {
      time = 200,
      effect = "fade"
    })
  end

  timer.performWithDelay(2000, epilogue)
end

function scene:show(event)
  if event.phase == "will" then
    transition.from(logo, {
      time = 200,
      alpha = 0,
    })
  end
end

function scene:hide()
end

function scene:destroy()
  logo:removeSelf()
  logo = nil
  bg:removeSelf()
  bg = nil
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
