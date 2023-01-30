TextParticles = {
  xFx = nil,
  yFx = nil,
  side = 0,
  txt = nil,
  index = 0,
  transitionTime = 400,
  currTransition = nil
}

function TextParticles:new(nx, ny, nside, ntxt)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.xFx = nx
  _self.yFx = ny
  _self.side = nside
  _self.txt = ntxt
  _self:start()
  return _self
end

function TextParticles:start()
  local segments = math.random(2, 4)

  local function init()
    self.txt.x = math.random(self.xFx(), self.xFx() + self.side)
    self.txt.y = self.yFx()
    self.index = 0
    self.currTransition = nil
  end

  local function onEndTransition()
    if self.index >= segments then
      init()
    else
      self.index = self.index + 1
    end
      self.currTransition = transition.to(self.txt,
      {
        x = math.random(self.xFx(), self.xFx() + self.side),
        y = self.txt.y - math.random(0, self.side) / (segments / 2),
        time = self.transitionTime,
        alpha = self.index + 1 >= segments and 0 or 1,
        onComplete = onEndTransition
      })
  end
  init()
  onEndTransition()
end

function TextParticles:destroy()
  if self.currTransition ~= nil then transition.cancel(self.currTransition) end
  self.currTransition = nil
  self.txt:removeSelf()
  self.txt = nil
end
