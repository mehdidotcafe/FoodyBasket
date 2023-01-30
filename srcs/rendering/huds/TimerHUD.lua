require "srcs.rendering.Colors"

TimerHUD = {
  container = nil,
  timeContainer = nil,
  timeTxt = nil,
  shootClockContainer = nil,
  shootClockTxt = nil
}

function TimerHUD:new(width, height, x, marginY, needTime)
  local _self = {}
  local rect
  local rect2

  setmetatable(_self, self)
  self.__index = self

  if x == nil then
    x = 0
  end

  _self.container = display.newContainer(width, height + marginY + 4 + height / 3)
  _self.container.y = display.screenOriginY + _self.container.height / 2
  _self.container.x = x

  _self.timeContainer = display.newRoundedRect(0, -_self.container.height / 2 + height / 2 + marginY, width, height, 10)
  _self.timeContainer:setFillColor(Colors:getColor("yellow"))
  _self.container:insert(_self.timeContainer)
  _self.timeTxt = display.newText{
    text = "0:00",
    font = native.newFont("font/Kroftsmann", 25),
    y = -_self.container.height / 2 + height / 2 + marginY
  }
  _self.timeTxt:setFillColor(Colors:getColor("red"))
  _self.container:insert(_self.timeTxt)

  _self.shootClockContainer = display.newRoundedRect(0, _self.timeContainer.y + _self.timeContainer.height / 2 + 4 + height / 6,  width / 3, height / 3, 5)
  _self.shootClockContainer:setFillColor(Colors:getColor("yellow"))
  _self.container:insert(_self.shootClockContainer)

  _self.shootClockTxt = display.newText{
    text = "0:00",
    font = native.newFont("font/Kroftsmann", 15),
    y = _self.shootClockContainer.y
  }
  _self.shootClockTxt:setFillColor(Colors:getColor("red"))
  _self.container:insert(_self.shootClockTxt)
  if needTime == false then
    _self.shootClockContainer.isVisible = false
    _self.shootClockTxt.isVisible = false
  end
  return _self
end

function TimerHUD:onTimeChange(time)
  if time % 60 < 10 then
    self.timeTxt.text = math.floor(time / 60) .. ':0' .. math.floor(time % 60)
  else
    self.timeTxt.text = math.floor(time / 60) .. ':' .. math.floor(time % 60)
  end
end

function TimerHUD:onShootClockChange(time)
  if time % 60 < 10 then
    self.shootClockTxt.text = math.floor(time / 60) .. ':0' .. math.floor(time % 60)
  else
    self.shootClockTxt.text = math.floor(time / 60) .. ':' .. math.floor(time % 60)
  end
end

function TimerHUD:insertToContainer(c)
  c:insert(self.container)
end

function TimerHUD:destroy()
  if self.timeTxt.removeSelf ~= nil then
    self.timeTxt:removeSelf()
    self.timeTxt = nil
    self.timeContainer:removeSelf()
    self.timeContainer = nil
    self.shootClockTxt:removeSelf()
    self.shootClockTxt = nil
    self.shootClockContainer:removeSelf()
    self.shootClockContainer = nil
    self.container:removeSelf()
    self.container = nil
  end
end
