Timer = {
  lim = 0,
  timeChangeListeners = nil,
  timerId = nil,
  onEndListeners = nil,
  currentTime = 0
}

function Timer:new(lim, obj)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self

  _self.lim = lim
  _self.timeChangeListeners = {}
  _self.onEndListeners = {}
  if obj ~= nil then
    _self:subscribeTimeChange(obj)
  end
  return _self
end

function Timer:incrTime()
  self.currentTime = self.currentTime + 1
  self:notifyTime()
end

function Timer:startTime()
  local function callback()
    self:incrTime()
    if self.currentTime == self.lim then
      self:notifyEndTime()
    else
      self.timerId = timer.performWithDelay(1000, callback)
    end
  end

  self:notifyTime()
  self.timerId = timer.performWithDelay(1000, callback)
end

function Timer:pause()
  timer.pause(self.timerId)
end

function Timer:resume()
  timer.resume(self.timerId)
end

function Timer:cancel()
  timer.cancel(self.timerId)
  self:notifyTime(0)
end

function Timer:setTime(lim)
  timer.cancel(self.timerId)
  self.lim = lim
  self.currentTime = 0
  self.timerId = 0
  self:startTime()
end

function Timer:subscribeTimeChange(obj)
  self.timeChangeListeners[table.getn(self.timeChangeListeners) + 1] = obj
end

function Timer:notifyTime(diff)
  if diff == nil then diff = self.lim - self.currentTime end
  for key, obj in ipairs(self.timeChangeListeners) do
    obj:onTimeChange(diff)
  end
end

function Timer:notifyEndTime()
  for key, obj in ipairs(self.onEndListeners) do
    obj:onEndTime()
  end
end

function Timer:subscribeEndTime(obj)
  self.onEndListeners[table.getn(self.onEndListeners) + 1] = obj
end

function Timer:destroy()
  timer.cancel(self.timerId)
  self.onEndListeners = {}
  self.timeChangeListeners = {}
end
