PressKey = {
  releaseListeners = nil,
  isPressed = false,
  pressTime = 0,
  onPress = nil,
  toAdd = 1
}

function PressKey:new(table)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.releaseListeners = {}
  if table ~= nil and table.player ~= nil then
    _self:subscribeReleaseChange(table.player)
  end
  if table ~= nil and table.toAdd ~= nil then
    _self.toAdd = table.toAdd
  end
  if table ~= nil and table.onPress ~= nil then
    _self.onPress = table.onPress
  end
  return _self
end

function PressKey:onEvent(event)

  local function onRelease(event)
    for key, obj in ipairs(self.releaseListeners) do
      obj:onReleaseChange(self.pressTime)
    end
    self.pressTime = 0
    self.isPressed = false
  end

  local function onPress(event)
    self.isPressed = true
    self.pressTime = 0
    if self.onPress ~= nil then
      self.onPress()
    end
  end

  if event.phase == "down" then
    onPress(event)
  elseif event.phase == "up" then
    onRelease(event)
  end
end

function PressKey:subscribeReleaseChange(obj)
  self.releaseListeners[table.getn(self.releaseListeners) + 1] = obj
end

function PressKey:update()
  if self.isPressed == true then
    self.pressTime = self.pressTime + self.toAdd
    for key, obj in ipairs(self.releaseListeners) do
      obj:onPressContinue(self.pressTime)
    end
  end
end

function PressKey:destroy()
  self.onPress = nil
end
