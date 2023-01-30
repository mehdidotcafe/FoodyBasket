require "srcs.rendering.SpriteSheetManager"

Body = {
  path = nil,
  ssm = nil
}

function Body:new(width, height, offX, offY, onClick)
  local INFOS = {
    numFrames = 1,
    sequences = {
      {name="default", start=1, count=1, priority=0},
      {name="walk", start=1, count=1, priority=0}
    }
  }
  local o = {}

  setmetatable(o, self)
  self.__index = self
  o.ssm = SpriteSheetManager:new(width, height, offX, offY, INFOS, onClick)
  return o
end

function Body:setPath(path)
  self.path = path
  self.ssm:setPath(path)
end

function Body:getSprite()
  return self.ssm.sprite
end

function Body:setAnimation(animation)
  self.ssm:setAnimation(animation)
end

function Body:setOrientation(orientation, from)
  self.ssm:setOrientation(orientation, from)
end

function Body:insertToContainer(container)
  container:insert(1, self:getSprite())
end

function Body:destroy()
  self.ssm:destroy()
  self.ssm = nil
end
