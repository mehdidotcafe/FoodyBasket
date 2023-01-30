AsideText = {
  txt = nil,
  currTransition = nil,
  currTimer = nil,
  player = nil
}

function AsideText:new(text, nplayer, timer)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.txt = display.newText{
    font = native.newFont('font/GROBOLD', 16),
    text = text
  }
  _self.txt:setFillColor(Colors:getColor("red"))
  _self.player = nplayer
  if timer ~= nil then
    _self:initTimeout(timer)
  end
  return _self
end

function AsideText:update()
  if self.txt ~= nil then
    local pos = self.player:getTopRightPos()
    local coeff = self.player:getOrientationAsCoeff()
    self.txt.x = pos.x + self.txt.width / 4 * coeff
    self.txt.y = pos.y - self.txt.height / 4
  end
end

function AsideText:insertToContainer(c)
  c:insert(self.txt)
end

function AsideText:initTimeout(timerValue)
  self.currTimer = timer.performWithDelay(timerValue, function()
    self.currTransition = Render:fadeAndDestroy(self, self.txt)
  end)
end

function AsideText:destroy()
  if self.currTimer ~= nil then timer.cancel(self.currTimer) end
  if self.currTransition ~= nil then transition.cancel(self.currTransition) end
  self.currTimer = nil
  if self.txt ~= nil then
    self.txt:removeSelf()
    self.txt = nil
  end
end
