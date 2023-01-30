require "srcs.rendering.SpriteSheetManager"

BallContainer = {
  ssm = nil
}

function BallContainer:new(diameter)
  local _self = {}
  local INFOS = {
    numFrames = 1,
    sequences  = {
      {name="default", start=1, count=1, priority=0}
    }
  }

  setmetatable(_self, self)
  self.__index = self
  _self.ssm = SpriteSheetManager:new(diameter, diameter, 0, 0, INFOS, nil)
  return _self
end

function BallContainer:setPath(path)
  self.ssm:setPath(path)
  self.ssm.sprite.type = "Ball"
  self.ssm.sprite.entity = self
end

function BallContainer:getSprite()
  return self.ssm.sprite
end

function BallContainer:getPos()
  local pos = {
    x = self.ssm.sprite.x,
    y = self.ssm.sprite.y
  }

  return pos
end

function BallContainer:setPos(pos)
  self.ssm.sprite.x = pos.x
  self.ssm.sprite.y = pos.y
end

function BallContainer:applyForce(s)
  self.ssm.sprite:applyForce(s.x, s.y, self.ssm.sprite.x, self.ssm.sprite.y)
end

function BallContainer:setLinearVelocity(s)
  self.ssm.sprite:setLinearVelocity(s.x, s.y)
end

function BallContainer:getLinearVelocity()
  return self.ssm.sprite:getLinearVelocity()
end

function BallContainer:getCenter()
  local rect = {
    x = self.ssm.sprite.x,
    y = self.ssm.sprite.y
  }

  return rect
end

function BallContainer:destroy()
  self.ssm:destroy()
  self.ssm = nil
end

function BallContainer:setVisibility(v)
  self.ssm.sprite.isVisible = v
end

function BallContainer:clearForces()
  self:getSprite():setLinearVelocity(0, 0)
  self:getSprite().angularVelocity = 0
end
