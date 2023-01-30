require("srcs.Translator")

local composer = require("composer")

local scene = composer.newScene()

local continueBtn = nil
local replayBtn = nil
local quitBtn = nil
local option = ""

function scene:create(event)
  local sceneGroup = self.view
  local parent = event.parent
  local rect = display.newRect(display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
  local toPrint = {}

  rect:setFillColor(0, 0.4)
  sceneGroup:insert(rect)
  local function onContinue()
    option = "continue"
    composer.hideOverlay( "fade", 400 )
    return true
  end

  local function onQuit()
    option = "quit"
    composer.hideOverlay( "fade", 400 )
  end

  local function onReplay()
    option = "replay"
    composer.hideOverlay( "fade", 400 )
    return true
  end

  local width = 300 / 2.3
  local height = 157 / 2.3

  continueBtn = Render.createBasicUI{
		label=Translator:translate("continue"),
		width=width, height=height,
		onRelease = onContinue
	}
  toPrint[#toPrint + 1] = continueBtn

  replayBtn = Render.createBasicUI{
		label=Translator:translate("replay"),
    width=width, height=height,
		onRelease = onReplay
	}
  if event.params.needReplay ~= true then replayBtn.isVisible = false else  toPrint[#toPrint + 1] = replayBtn end

  quitBtn = Render.createBasicUI{
		label=Translator:translate("quit"),
    width=width, height=height,
		onRelease = onQuit
	}
  toPrint[#toPrint + 1] = quitBtn

  local marginX = 50
  local marginY = 85

  for i = 1, #toPrint do
    toPrint[i].x = display.contentCenterX + (i - #toPrint / 2 ) * marginX - width / 4
    toPrint[i].y = display.contentCenterY + (i - #toPrint / 2 ) * marginY - height / 2
    sceneGroup:insert(toPrint[i])
  end
end

function scene:hide(event)
  local sceneGroup = self.view
  local phase = event.phase
  local parent = event.parent

  if phase == "will" then
    Render:unbounce(replayBtn)
		Render:unbounce(continueBtn)
		Render:unbounce(quitBtn)
    replayBtn:removeSelf()
    continueBtn:removeSelf()
    quitBtn:removeSelf()

    replayBtn = nil
    continueBtn = nil
    quitBtn = nil

    if option == "continue" then
      parent:resume()
    elseif option == "replay" then
      parent:onReplay()
    elseif option == "quit" then
      parent:quit()
    end
  end
end

function scene:show(event)
  if event.phase == "did" then
    Render:infiniteBounce(replayBtn, 3, 1000)
		Render:infiniteBounce(continueBtn, 3, 1000, 50)
		Render:infiniteBounce(quitBtn, 3, 1000, 130)
    Render:popFromBackground(replayBtn)
    Render:popFromBackground(continueBtn)
    Render:popFromBackground(quitBtn)
  end
end

function scene:destroy(event)
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
