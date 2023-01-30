require "srcs.rendering.SpriteSheetManager"

local assets = require "srcs.Assets"

Head = {
  path = nil,
  ssm = nil,
  stats = nil
}

function Head:new(width, height, offX, offY)
  local _self = {}

  local INFOS = {
    numFrames = 1,
    sequences = {
      {name="default", start=1, count=1, priority=0},
      {name="walk", start=1, count=1, priority=0}
    }
  }

  setmetatable(_self, self)
  self.__index = self
  _self.ssm = SpriteSheetManager:new(width, height, offX, offY, INFOS)
  return _self
end

function Head:setPath(path)
  self.path = path
  self.stats = path.stats
  self.ssm:setPath(assets:fromName(path.name, "head"))
end

function Head:getSprite()
  return self.ssm.sprite
end

function Head:setAnimation(animation)
  self.ssm:setAnimation(animation)
end

function Head:getAnimation()
  return self.ssm.currentAnimation
end

function Head:setOrientation(orientation, from, cb)
  self.ssm:setOrientation(orientation, from, cb)
end

function Head:insertToContainer(container)
  container:insert(self:getSprite())
end

function Head:getOuter()
  return self.ssm:getOuter()
end

function Head:destroy()
  if self.frontKickTimer ~= nil then
    timer.cancel(self.frontKickTimer)
  end
  self.ssm:destroy()
  self.ssm = nil
  self.stats = nil
end

function Head:getTransition()
  return self.ssm.oriManager.transition
end
