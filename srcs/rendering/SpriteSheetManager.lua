require "srcs.rendering.Render"
require "srcs.rendering.Orientation"

local assets = require "srcs.Assets"

SpriteSheetManager = {
  sprite = nil,
  is = nil,
  width = 0,
  height = 0,
  offY = 0,
  offX = 0,
  oldY = 0,
  oldX = 0,
  infos = nil,
  currentAnimation = nil,
  currentSequence = nil,
  path = nil,
  oriManager = nil,
  transition = nil
}

function SpriteSheetManager:getSequenceByName(name)
  for key, obj in ipairs(self.infos.sequences) do
    if obj.name == name then
      return obj
    end
  end
  return nil
end

function SpriteSheetManager:new(width, height, offX, offY, infos)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.currentAnimation = "default"
  _self.width = width
  _self.height = height
  _self.offX = offX
  _self.offY = offY
  _self.oldX = offX
  _self.oldY = offY
  _self.infos = infos
  _self.oriManager = Orientation:new()
  return _self
end

function SpriteSheetManager:setPath(path)
  if self.sprite ~= nil then
    self.oldX = self.sprite.x
    self.oldY = self.sprite.y
    self.sprite:removeSelf()
    self.sprite = nil
    self.currentAnimation = "default"
  end
  self:initSpriteSheet(path)
end

function SpriteSheetManager:initSpriteSheet(path)

  local opts = {numFrames = self.infos.numFrames, width = self.width, height = self.height, sheetContentHeight = self.height, sheetContentWidth = self.width * self.infos.numFrames}

  local function onSeqEnd(e)
    if e.phase == "ended" then
      if self.currentSequence ~= nil and self.currentSequence.onEnd ~= nil then
        self.currentSequence:onEnd()
      end
      self.currentAnimation = nil
    end
  end

  self.path = path
  self.is = graphics.newImageSheet(path, opts)
  self.sprite = display.newSprite(self.is, self.infos.sequences)
  self.sprite:addEventListener("sprite", onSeqEnd)
  self.sprite.y = self.oldY
  self.sprite.x = self.oldX
  self:setAnimation("default")
end

function SpriteSheetManager:setAnimation(animation, isForced)
  local seq = self:getSequenceByName(animation)
  local currSeq = nil

  if seq == nil then return end
  if self.currentAnimation ~= animation then
    currSeq = self:getSequenceByName(self.currentAnimation)

    if currSeq == nil or currSeq.priority <= seq.priority or isForced == true then
      if self.currentSequence ~= nil and self.currentSequence.onEnd ~= nil then
        self.currentSequence:onEnd()
      end
      self.currentAnimation = animation
      self.currentSequence = seq
      if seq.onPlay ~= nil then
        seq:onPlay()
      end
      self.sprite:setSequence(animation)
      self.sprite:play()
    end
  end
end

function SpriteSheetManager:setOrientation(orientation, from, cb)
  self.oriManager:change(self.sprite, orientation, from, cb)
end

function SpriteSheetManager:getSprite()
  return self.sprite
end

function SpriteSheetManager:destroy()
  self.sprite:removeSelf()
  self.spirte = nil
  self.is = nil
end

function SpriteSheetManager:getOuter(idx)
  if idx == nil then
    idx = 1
  end
  if self.is ~= nil then
    return graphics.newOutline(20, self.is, idx)
  end
end
