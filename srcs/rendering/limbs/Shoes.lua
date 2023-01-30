require "srcs.rendering.SpriteSheetManager"
require "srcs.rendering.Orientation"

local sm = require("srcs.sound.SoundManager")
local assets = require "srcs.Assets"

Shoes = {
  path = nil,
  ssm = nil,
  oriManager = nil,
  width = 0,
  height = 0,
  transitionIndex = 1,
  container = nil,
  stats = nil
}

function Shoes:new(width, height, offX, offY)
  local _self = {}
  local INFOS = {
    numFrames = 2,
    sequences = {
      {name="left", start=1, count=1, priority=0},
      {name="right", start=2, count=1, priority=0}
    }
  }
  local leftOffX = 5
  local rightOffX = leftOffX + 10

  setmetatable(_self, self)
  self.__index = self
  _self.container = display.newGroup()
  _self.container.x = offX
  _self.container.y = offY
  _self.width = width
  _self.height = height
  _self.leftSsm = SpriteSheetManager:new(width, height, leftOffX, 0, INFOS)
  _self.rightSsm = SpriteSheetManager:new(width, height, rightOffX, 0, INFOS)
  _self.oriManager = Orientation:new()
  return _self
end

function Shoes:setPath(path)
  self.path = path
  self.stats = path.stats
  self.leftSsm:setPath(assets:fromName(path.name, "shoe"))
  self.rightSsm:setPath(assets:fromName(path.name, "shoe"))
  self.leftSsm:setAnimation("left")
  self.rightSsm:setAnimation("right")
  self.container:insert(self.rightSsm.sprite)
  self.container:insert(self.leftSsm.sprite)

end

function Shoes:getBoundingBox()
  return {
    x = self.container.x,
    y = self.container.y,
    width = self.width,
    height = self.height
  }
end

function Shoes:getSprite()
  return self.container
end

function Shoes:setJumpTransition()
  local function toShoe(shoe)

    local function resetTransition()
      shoe.isTransitionning = false
    end

    shoe.isTransitionning = true
    transition.to(shoe, {
      time = 500,
      rotation = 40,
      onCancel = resetTransition,
      onComplete = resetTransition,
      transition = easing.continuousLoop
    })
  end

  if self.leftSsm.sprite.isTransitionning ~= true and self.rightSsm.sprite.isTransitionning ~= true then
    toShoe(self.leftSsm.sprite)
    toShoe(self.rightSsm.sprite)
  end
end

function Shoes:setWalkTransition()
  local function toShoe(shoe, coeff)
    local function resetTransition()
      shoe.isTransitionning = false
    end

    shoe.isTransitionning = true
    transition.to(shoe, {
      time = 220,
      x = shoe.x + 20 * coeff,
      y = shoe.y - 10,
      rotation = -50 * coeff,
      onCancel = resetTransition,
      onComplete = resetTransition,
      transition = easing.continuousLoop
    })
  end

  if self.leftSsm.sprite.isTransitionning ~= true and self.rightSsm.sprite.isTransitionning ~= true then
    if sm:isPlaying("foot1") ~= true and sm:isPlaying("foot3") ~= true then
      sm:play("foot" .. (self.transitionIndex + 2))
    end
    toShoe(self.leftSsm.sprite, self.transitionIndex * -1)
    toShoe(self.rightSsm.sprite, self.transitionIndex)
    self.transitionIndex = self.transitionIndex * -1
  end
end

function Shoes:setTransition(transition)
  if transition == "jump" then
    self:setJumpTransition()
  elseif transition == "walk" then
    self:setWalkTransition()
  end
end

function Shoes:setOrientation(orientation, from, cb)
  self.oriManager:change(self.container, orientation, from, cb)
end

function Shoes:insertToContainer(container)
  container:insert(1, self.container)
end

function Shoes:destroy()
  self.leftSsm:destroy()
  self.leftSsm = nil

  self.rightSsm:destroy()
  self.rightSsm = nil
end

function Shoes:getOuter()
  return {-self.width / 2, -self.height / 2, self.width / 2, -self.height / 2, self.width / 2, self.height / 2, -self.width / 2, self.height / 2}
end
