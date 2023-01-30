require "srcs.rendering.Render"

World = {
  backgroundFirst = nil,
  chars = {},
  stage = nil,
  scene = nil,
  currTimer = nil,
  axis = nil
}

local onComplete

local function doTransition(char, waves)
  char.isMoving = true
  char.currTransition = transition.moveTo(char.img, {
    y = char.img.y - math.random(10, 30),
    transition = easing.continuousLoop,
    onComplete = onComplete(char, waves),
    time = math.random(300, 600)
  })
end

onComplete = function(nchar, waves)
  return
    function()
      nchar.isMoving = false
      nchar.wave = nchar.wave + 1
      nchar.currTransition = nil
      if nchar.wave < waves and math.random(1, 3) ~= 3 then
        doTransition(nchar, waves)
      else
        nchar.wave = 0
      end
    end
end


function World:new()
  if self.stage == nil then
    self.stage = display.getCurrentStage()
  end
  return self
end

function World:setBackground(path, sceneGroup)
  local char
  local startY = 160
  local startX = display.screenOriginX
  local offsetY = 25
  local offsetX = 25
  if self.backgroundFirst ~= nil then
    self.backgroundFirst:removeSelf()
    self.backgroundFirst = nil
  end
  if self.backgroundSecond ~= nil then
    self.backgroundSecond:removeSelf()
    self.backgroundSecond = nil
  end
  self.backgroundFirst = display.newImageRect("assets/courts/basic.png", display.actualContentWidth, display.actualContentHeight)
  self.backgroundFirst.anchorX = 0
  self.backgroundFirst.anchorY = 0
  self.backgroundFirst.x = 0 + display.screenOriginX
  self.backgroundFirst.y = 0 + display.screenOriginY
  -- self.fruitsName = {"giraffe", "monkey", "panda", "parrot", "penguin", "rabbit", "snake"}
  -- for j = 0, 25 do
  --   for i = 0, 9 do
  --     char = {
  --       img = display.newImageRect("assets/fruits/" .. self.fruitsName[math.random(1, #self.fruitsName)] .. ".png", display.actualContentWidth / 15, display.actualContentWidth / 15),
  --       isMoving = false,
  --       currTransition = nil,
  --       wave = 0
  --     }
  --     char.img.x = startX + j * offsetX + math.random(-char.img.width /  15, char.img.width / 15)
  --     char.img.y = startY - i * offsetY + char.img.height / 2 - math.random(-char.img.width / 15, char.img.width / 15)
  --     self.chars[#self.chars + 1] = char
  --     sceneGroup:insert(1, char.img)
  --   end
  -- end
  -- self.backgroundSecond = display.newImageRect("assets/courts/tribune-second.png", display.actualContentWidth, display.actualContentHeight)
  -- self.backgroundSecond.anchorX = 0
  -- self.backgroundSecond.anchorY = 0
  -- self.backgroundSecond.x = 0 + display.screenOriginX
  -- self.backgroundSecond.y = 0 + display.screenOriginY
  if sceneGroup == nil then sceneGroup = self.stage end
  -- sceneGroup:insert(1, self.backgroundSecond)
  sceneGroup:insert(1, self.backgroundFirst)
end

function World:createAxis()
  self.axis = {
    right = Render.createContainer(1,2 * display.actualContentHeight - display.actualContentHeight / 1.5, display.actualContentWidth, -display.actualContentHeight - 1),
    rightNext = Render.createContainer(1,2 * display.actualContentHeight, display.actualContentWidth + 20, -display.actualContentHeight - 1),
    rightNextPlayer = Render.createContainer(1,2 * display.actualContentHeight, display.actualContentWidth + 20, -display.actualContentHeight),
    left = Render.createContainer(1, 2 * display.actualContentHeight - display.actualContentHeight / 1.5, -1, -display.actualContentHeight - 1),
    leftNext = Render.createContainer(1, 2 * display.actualContentHeight, -21, -display.actualContentHeight - 1),
    leftNextPlayer = Render.createContainer(1, 2 * display.actualContentHeight, -21, -display.actualContentHeight),
    top = Render.createContainer(display.actualContentWidth, 1, 0, -display.actualContentHeight - 1),
    bot = Render.createContainer(2 * display.actualContentWidth, 1, display.actualContentWidth / 2 - display.actualContentWidth, 5 * display.actualContentHeight / 6),
    center = {}
  }
  self.axis.center.x = self.axis.right.x / 2
end

function World:addAxisToPhysics()
  local masks = require("srcs.entities.physics.entitiesMask")
  -- self.axis.right.type = "World"
  -- self.axis.left.type = "World"
  -- self.axis.top.type = "World"

  self.axis.bot.type = "World"
  physics.addBody(self.axis.right, "static",  { friction=0.5, bounce=0.3 , filter=masks["worldLimit"]})
  physics.addBody(self.axis.rightNext, "static",  { friction=0.5, bounce=0.3 , filter=masks["worldLimitBall"]})
  physics.addBody(self.axis.rightNextPlayer, "static",  { friction=0, bounce=2, filter=masks["worldLimitPlayer"]})
  physics.addBody(self.axis.left, "static",  { friction=0.5, bounce=0.3 , filter=masks["worldLimit"]})
  physics.addBody(self.axis.leftNext, "static",  { friction=0.5, bounce=0.3 , filter=masks["worldLimitBall"]})
  physics.addBody(self.axis.leftNextPlayer, "static",  { friction=0, bounce=2, filter=masks["worldLimitPlayer"]})
  physics.addBody(self.axis.top, "static",  { friction=0.5, bounce=0.3 , filter=masks["worldLimit"]})
  physics.addBody(self.axis.bot, "static",  { friction=0.5, bounce=0.3 , filter=masks["worldLimit"]})
end

function World:moveSomeChars(percentage, waves)
  -- local nb = #self.chars * percentage / 100
  -- local char
  --
  -- if waves == nil then waves = 1 end
  --
  -- if #self.chars == 0 then return end
  -- for i = 0, nb do
  --   char = self.chars[math.random(1, #self.chars)]
  --   if char.isMoving == false then
  --     doTransition(char, waves)
  --   end
  -- end
end

function World:moveSomeCharsWhile(time, percentage, waves)
  -- self:moveSomeChars(percentage)
  -- self.currTimer = timer.performWithDelay(time,
  -- function()
  --   self:moveSomeChars(percentage, waves)
  -- end, 0)
end

function World:destroy()
  if self.currTimer ~= nil then timer.cancel(self.currTimer) end
  self.currTimer = nil
  if self.backgroundFirst ~= nil then
    self.backgroundFirst:removeSelf()
    self.backgroundFirst = nil
  end
  if self.backgroundSecond ~= nil then
    self.backgroundSecond:removeSelf()
    self.backgroundSecond = nil
  end
  for i = 1, #self.chars do
    if self.chars[i].currTransition ~= nil then transition.cancel(self.chars[i].currTransition) end
    self.chars[i].currTransition = nil
    self.chars[i].img:removeSelf()
    self.chars[i].img = nil
    self.chars[i] = nil
  end
  self.chars = {}
end
