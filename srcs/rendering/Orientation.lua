Orientation = {
  transition = nil
}

function Orientation:new()
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  return _self
end

function Orientation:change(sprite, orientation, from, cb)
  local function onEnd()
    self.transition = nil
    if cb ~= nil then
      cb()
    end
  end

  if orientation == "left" and sprite ~= nil then
    if from ~= nil and from ~= "left" and from ~= "disable" then
      sprite.xScale = -1
      onEnd()
    end
    if from == "disable" then
      sprite.xScale = 1
      onEnd()
    else
      self.transition = transition.to(sprite, {xScale = 1, time = 100, onComplete=onEnd, onCancel=onEnd})
    end
  elseif orientation == "right" and sprite ~= nil then
    if from ~= nil and from ~= "right" and from ~= "disable" then
      sprite.xScale = 1
      onEnd()
    end
    if from == "disable" then
      sprite.xScale = -1
      onEnd()
    else
      self.transition = transition.to(sprite, {xScale = -1, time = 100, onComplete=onEnd, onCancel=onEnd})
    end
  end
end
