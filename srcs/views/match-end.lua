local composer = require("composer")
local widget = require("widget")
require "srcs.rendering.Colors"

local scene = composer.newScene()
local foodzContainer
local pm = require("srcs.PurchaseManager")

function scene:create(event)
  local sceneGroup = self.view
  local rect = display.newRect(display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
  local player1Score = event.params.player1.score
  local player2Score = event.params.player2 and event.params.player2.score or 0
  local txt
  local winner = nil
  local printedTxt
  local replayButton
  local quitButton
  local conButton
  local fc
  local group
  local toPrint = {}

  self.option = ""

  group = display.newContainer(500, 400)
  rect:setFillColor(0, 0.2)
  sceneGroup:insert(rect)
  sceneGroup:insert(event.params.container.container)
  self.container = event.params.container.container
  if player1Score == player2Score then
    txt = string.upper(Translator:translate("draw"))
    fc = {Colors:getColor("white")}
    event.params.player1:die()
    if event.params.player2 then event.params.player2:die() end
  elseif player1Score > player2Score then
    txt = string.upper(Translator:translate("winner"))
    winner = event.params.player1.name
    fc = {Colors:getColor("red")}
    event.params.player1:win(sceneGroup)
    if event.params.player2 then event.params.player2:die() end
  else
    txt = string.upper(Translator:translate("winner"))
    winner = event.params.player2.name
    fc = {Colors:getColor("red")}
    event.params.player1:die()
    if event.params.player2 then event.params.player2:win(sceneGroup) end
  end

  foodzContainer = FoodzContainer:new(550 / 4.5, 185 / 4.5, false)
  -- foodzContainer.group.x = replayButton.x - replayButton.width / 2 - 20 - foodzContainer.group.width / 2
  -- foodzContainer.group.y = replayButton.y
  foodzContainer:setPoints(pm.points)
  toPrint[#toPrint + 1] = foodzContainer.group
  -- sceneGroup:insert(foodzContainer.group)


  replayButton = Render:basicButton("img/uis/replay-button", function(event)
      self.option = "replay"
      composer.hideOverlay()
    end, 40, 43)
  -- replayButton.x = display.contentCenterX - 30
  -- replayButton.y = display.contentCenterY + 80
  if event.params.needReplay == false then replayButton.isVisible = false else toPrint[#toPrint + 1] = replayButton end
  -- sceneGroup:insert(replayButton)

  conButton = Render:basicButton("img/uis/continue-button", function(event)
      self.option = "continue"
      composer.hideOverlay()
    end, 40, 43)
    toPrint[#toPrint + 1] = conButton
  -- conButton.x = replayButton.x + conButton.width + 20
  -- conButton.y = replayButton.y
  -- sceneGroup:insert(conButton)

  quitButton = Render:basicButton("img/uis/quit-button", function(event)
      self.option = "quit"
      composer.hideOverlay()
    end, 40, 43)
  -- quitButton.x = conButton.x + quitButton.width + 20
  -- quitButton.y = conButton.y
  if event.params.needQuit == false then quitButton.isVisible = false else toPrint[#toPrint + 1] = quitButton end
  -- sceneGroup:insert(quitButton)

  group.y = display.actualContentHeight / 2
  group.x = display.contentCenterX

  local marginX = 60

  for i = 1, #toPrint do
    toPrint[i].x = display.contentCenterX + (i - #toPrint / 2 ) * marginX - marginX / 2
    toPrint[i].y = display.contentCenterY + 80
    sceneGroup:insert(toPrint[i])
  end
  foodzContainer.group.x = foodzContainer.group.x - foodzContainer.group.width / 3

  sceneGroup:insert(group)
  pm:incrScore(event.params.points)

end

function setPointsToContainer(e)
  local toAdd = math.min(pm.points - self.points, math.floor(math.random() * 10))

  if self.points + toAdd >= pm.points then
    timer.cancel(e.source)
  end
  self:setPoints(self.points + toAdd)
end

function scene:hide(event)
  local parent = event.parent

  if event.phase == "did" then
    if self.option == "replay" then
      parent:onReplay()
    elseif self.option == "quit" then
      parent:quit()
    elseif self.option == "continue" then
      parent:continue()
    end
  end
end

function scene:show(event)
  if event.phase == "did" then
    transition.to(self.container, {
      transition = easing.outBack,
      time = 300,
      xScale = 2,
      yScale = 2,
      y = 50
    })
  else
    foodzContainer:setPointsEffect()
  end
end

function scene:destroy(event)
end

scene:addEventListener("create", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("show", scene)
scene:addEventListener("destroy", scene)

return scene
