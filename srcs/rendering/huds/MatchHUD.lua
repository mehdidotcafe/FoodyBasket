require "srcs.rendering.huds.PlayerHUD"
require "srcs.rendering.huds.TimerHUD"

MatchHUD = {
  width = 0,
  height = 0,
  x = 0,
  y = 0,
  container = nil,
  p1Container = nil,
  timeContainer = nil,
  p2Container = nil
}

function MatchHUD:new(width, height, x, y, player1, player2, needTime, needP2pb)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self

  _self.width = width
  _self.height = height
  _self.container = display.newGroup(_self.width, _self.height)
  _self.container.x = x
  _self.container.y = y
  _self.x = x
  _self.y = y
  _self:createContainers(player1, player2, needTime, needP2pb)
  return _self
end

function MatchHUD:createContainers(p1, p2, needTime, needP2pb)

  self.p1Container = PlayerHUD:new(math.ceil(2 * self.width / 5), self.height, 0 - math.ceil(self.width / 5) - math.ceil(self.width / 10), self.y, p1, "left")
  -- +10 on width for when the scale on match-end
  self.timeContainer = TimerHUD:new(math.ceil(2 * self.width / 5), self.height, 0, self.y, needTime)
  -- if p2 ~= nil then
    self.p2Container = PlayerHUD:new(math.ceil(2 * self.width / 5), self.height, 0 + math.ceil(self.width / 5) + math.ceil(self.width / 10), self.y, p2, "right", needP2pb)
  -- end

  self.timeContainer:insertToContainer(self.container)
  self.p1Container:insertToContainer(self.container)
  -- if p2 ~= nil then
    self.p2Container:insertToContainer(self.container)
  -- end
end

function MatchHUD:insertToContainer(c)
  c:insert(self.container)
end

function MatchHUD:hideSubGUIs()
  self.p1Container.strengthContainer.container.isVisible = false
  self.p1Container.dunkImg.isVisible = false
  -- self.timeContainer.timeTxt.isVisible = false
  self.timeContainer.shootClockContainer.isVisible = false
  self.timeContainer.shootClockTxt.isVisible = false
  if self.p2Container ~= nil and self.p2Container.strengthContainer ~= nil then
    self.p2Container.strengthContainer.container.isVisible = false
    self.p2Container.dunkImg.isVisible = false
  end
end

function MatchHUD:destroy()
  self.container:removeSelf()
  self.container = nil
  if self.p1Container ~= nil then
    self.p1Container:destroy()
    self.p2Container = nil
  end
  if self.timeContainer ~= nil then
    self.timeContainer:destroy()
    self.timeContainer = nil
  end
  if self.p2Container ~= nil then
    self.p2Container:destroy()
    self.p2Container = nil
  end
end
