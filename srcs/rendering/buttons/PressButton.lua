local widget = require("widget")
local display = require("display")

PressButton = {
  button = nil,
  releaseListeners = nil,
  isPressed = false,
  pressTime = 0,
  toAdd = 1
}

function PressButton:new(table)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self

  local function onRelease(event)
    for key, obj in ipairs(_self.releaseListeners) do
      obj:onReleaseChange(_self.pressTime)
    end
    _self.pressTime = 0
    _self.isPressed = false
  end

  local function onPress(event)
    _self.isPressed = true
    _self.pressTime = 0
  end

  local function onMove(event)
    local bX, bY = _self.button:localToContent(_self.button.width / 2, _self.button.width / 2)

    if event.x <  bX - _self.button.width / 2 or event.x > bX + _self.button.width / 2 or
       event.y < bY - _self.button.height / 2 or event.y > bY + _self.button.height / 2 then
         onRelease(event)
    end
  end

  local function onEvent(event)
    if event.phase == "began" then
      onPress(event)
    elseif event.phase == "ended" then
      onRelease(event)
    elseif event.phase == "cancelled" then
      onRelease(event)
    elseif event.phase == "moved" then
      onMove(event)
    end
  end

  _self.releaseListeners = {}
  _self.button = widget.newButton{
    defaultFile = table.defaultFile,
    overFile = table.overFile,
    width= table.width,
    height= table.height,
    x = table.x,
    y = table.y,
    fontSize = table.fontSize,
    onEvent = onEvent
  }
  if table.player ~= nil then
    _self:subscribeReleaseChange(table.player)
  end
  if table.toAdd ~= nil then
    _self.toAdd = table.toAdd
  end
  return _self
end

function PressButton:subscribeReleaseChange(obj)
  self.releaseListeners[table.getn(self.releaseListeners) + 1] = obj
end

function PressButton:update()
  if self.isPressed == true then
    self.pressTime = self.pressTime + self.toAdd
    for key, obj in ipairs(self.releaseListeners) do
      obj:onPressContinue(self.pressTime)
    end
  end
end

function PressButton:destroy()
  self.button:removeSelf()
  self.button = nil
end
