require "srcs.rendering.Colors"
require "srcs.control.Keyboard"
require "srcs.Translator"

local composer = require "composer"
local widget = require "widget"
local scene = composer.newScene()
scene.buttonEnabled = false
local background
local backBtn
local buttons = {}

function scene:create(event)
  local sceneGroup = self.view
  local touches = {"left", "right", "jump", "shoot", "take"}
  local x
  local y
  background = display.newImageRect("img/uis/background-select.png", display.actualContentWidth, display.actualContentHeight )
  background.y =  display.contentCenterY
  background.x = display.contentCenterX

  backBtn = Render:basicButton("img/uis/back-button", function()
    if scene.buttonEnabled ~= true then return end
      composer.gotoScene("srcs.views.menu", {
        effect="fade",
        time = 200
      })
    end, 35, 37)
  backBtn.y = display.screenOriginY + display.actualContentHeight - 35
  backBtn.x = display.contentCenterX - display.actualContentWidth / 2 + backBtn.width / 2 + 10

  sceneGroup:insert(background)
  sceneGroup:insert(backBtn)

  for i = 1, #touches do
    y = display.contentCenterY - 150 + i * 50
    x = display.contentCenterX
    buttons[i] = {}
    buttons[i].first = widget.newButton{
      defaultFile="img/uis/name-ui.png",
      width = display.actualContentWidth / 7,
      height = display.actualContentHeight /  9,
      labelColor = { default={Colors:getColor("red")}},
      label = Translator:translate(touches[i]),
      font = native.newFont("font/GROBOLD"),
      x = x - 50,
      y = y
    }
    buttons[i].second = widget.newButton{
      defaultFile="img/uis/name-ui.png",
      width = display.actualContentWidth / 7,
      height = display.actualContentHeight /  9,
      labelColor = { default={Colors:getColor("red")}},
      label = "toto",
      font = native.newFont("font/GROBOLD"),
      x = x + 50,
      y = y
    }

    sceneGroup:insert(buttons[i].first)
    sceneGroup:insert(buttons[i].second)
  end
end

function scene:show(event)
  if event.phase == "did" then
    scene.buttonEnabled = true
  end
end

function scene:hide(event)
  if event.phase == "will" then
    scene.buttonEnabled = false
  end
end

function scene:destroy(event)
  background:removeSelf()
  background = nil

  backBtn:removeSelf()
  backBtn = nil
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
