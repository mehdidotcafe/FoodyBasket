local assets = require "srcs.Assets"

Hands = {
  left = nil,
  right = nil,
  orientation = nil,
  lContainer = nil,
  lContainerStartX = 0,
  lContainerStartY = 0,
  rContainer = nil,
  rContainerStartX = 0,
  rContainerStartY = 0,
  width = 0,
  height = 0,
  collideListeners = {},
  oriManager = nil,
  transitionIndex = 1,
  strengthMove = 20,
  stats = nil
}

function Hands:new(width, height, offX, offY)
  local _self = {}

  local INFOS = {
    numFrames = 2,
    sequences = {
      {name="left", start=1, count=1, priority=0},
      {name="right", start=2, count=1, priority=0},
    }
  }

  setmetatable(_self, self)
  self.__index = self
  _self.height = height
  _self.width = width
  _self.left = {}
  _self.right = {}
  _self.lContainer = display.newGroup()
  _self.rContainer = display.newGroup()
  _self.lContainer.x = offX - width
  _self.lContainer.y = offY
  _self.lContainerStartX = _self.lContainer.x
  _self.lContainerStartY = _self.lContainer.y
  _self.rContainer.x = offX + width
  _self.rContainer.y = offY
  _self.rContainerStartX = _self.rContainer.x
  _self.rContainerStartY = _self.rContainer.y
  _self["left"].ssm = SpriteSheetManager:new(width, height, 0, 0, INFOS)
  _self["right"].ssm = SpriteSheetManager:new(width, height, 0, 0, INFOS)

  -- _self:setCollisionListener()
  return _self
end

function Hands:setPath(path)
  self.path = path
  self.stats = path.stats
  self["left"].ssm:setPath(assets:fromName(path.name, "hand"))
  self["right"].ssm:setPath(assets:fromName(path.name, "hand"))
  self["left"].ssm:setAnimation("left")
  self["right"].ssm:setAnimation("right")
  self.rContainer:insert(self.right.ssm.sprite)
  self.lContainer:insert(self.left.ssm.sprite)
end

function Hands:getSprite()
  local sprites = {
    -- left = self["left"].ssm.sprite,
    -- right = self["right"].ssm.sprite
    left = self.lContainer,
    right = self.rContainer
  }

  return sprites
end

function Hands:getOuterLeft()
  return {-self.width / 2, -self.height / 2, self.width / 2, -self.height / 2, self.width / 2, self.height / 2, -self.width / 2, self.height / 2}
end

function Hands:getOuterRight()
  return {-self.width / 2, -self.height / 2, self.width / 2, -self.height / 2, self.width / 2, self.height / 2, -self.width / 2, self.height / 2}
end

function Hands:getAnimation()
  return self["left"].ssm.currentAnimation
end

function Hands:setAnimation(animation, isForced)
  self["left"].ssm:setAnimation(animation, isForced)
  self["right"].ssm:setAnimation(animation, isForced)
end

function Hands:setOrientation(orientation, from)
  self["left"].ssm:setOrientation(orientation, from)
  self["right"].ssm:setOrientation(orientation, from)
  self.orientation = orientation
end

function Hands:insertLeftHandToContainer(container)
  container:insert(self:getSprite()["left"])
end

function Hands:insertRightHandToContainer(container)
  container:insert(self:getSprite()["right"])
end

function Hands:destroy()
  self["left"].ssm:destroy()
  self["right"].ssm:destroy()
  self["left"].ssm = nil
  self["right"].ssm = nil
end

function Hands:getOuter()
  return {left = nil, right = nil}
  -- return {left = self:getOuterLeft(), right = self:getOuterRight()}
end

function Hands:notifyOnCollide(event, from)
  for key, obj in ipairs(self.collideListeners) do
    obj:onHandsCollide(event, from)
  end
end

function Hands:subscribeOnCollide(obj)
  self.collideListeners[table.getn(self.collideListeners) + 1] = obj
end

function Hands:setCollisionListener()
  local sprites = self:getSprite()

  local function collide(from)
    local function inner(event)
      self:notifyOnCollide(event, from)
    end
    return inner
  end

  sprites["left"].collision = collide("left")
  sprites["right"].collision = collide("right")
end

function Hands:applyAngularImpulse(l, r)
  self["left"].ssm.sprite:applyAngularImpulse(l)
  self["right"].ssm.sprite:applyAngularImpulse(r)
end

function Hands:setWalkTransition()
  local function toShoe(shoe, coeff)
    local function resetTransition()
      shoe.isTransitionning = false
      shoe.currTran = nil
    end

    shoe.isTransitionning = true
    shoe.currTran = transition.to(shoe, {
      time = 250,
      x = shoe.x + 20 * coeff,
      y = shoe.y - 15,
      rotation = -80 * coeff,
      onCancel = resetTransition,
      onComplete = resetTransition,
      transition = easing.continuousLoop
    })
  end

  if self.left.ssm.sprite.isTransitionning ~= true and self.left.ssm.sprite.isTransitionning ~= true then
    toShoe(self.left.ssm.sprite, self.transitionIndex * -1)
    toShoe(self.right.ssm.sprite, self.transitionIndex)
    self.transitionIndex = self.transitionIndex * -1
  end
end

function Hands:setTakeTransition()
  local function toShoe(shoe, strengthX)
    local function resetTransition()
      shoe.isTransitionning = false
      shoe.currTran = nil
    end

    local ori = {left = 1, right = -1}

    shoe.isTransitionning = true
    shoe.currTran = transition.to(shoe, {
      time = 250,
      x = shoe.x + ori[self.orientation] * strengthX,
      y = shoe.y - ori[self.orientation] * 5,
      rotation = -85 * ori[self.orientation],
      onCancel = resetTransition,
      onComplete = resetTransition,
      transition = easing.continuousLoop
    })
  end
  local strengths = {left = {40, 20}, right = {20, 40}}

  if self.left.ssm.sprite.isTransitionning == true then
    transition.cancel(self.left.ssm.sprite.currTran)
    self.left.ssm.sprite.currTran = nil
    self.left.ssm.sprite.isTransitionning = false
    self.left.ssm.sprite.x = lContainerStartX
    self.left.ssm.sprite.y = lContainerStartY
    self.left.ssm.sprite.rotation = 0
  end
  if self.right.ssm.sprite.isTransitionning == true then
    transition.cancel(self.right.ssm.sprite.currTran)
    self.right.ssm.sprite.currTran = nil
    self.right.ssm.sprite.isTransitionning = false
    self.right.ssm.sprite.x = rContainerStartX
    self.right.ssm.sprite.y = rContainerStartY
    self.right.ssm.sprite.rotation = 0
  end
  if self.left.ssm.sprite.isTransitionning ~= true and self.left.ssm.sprite.isTransitionning ~= true then
    toShoe(self.left.ssm.sprite, strengths[self.orientation][1])
    toShoe(self.right.ssm.sprite, strengths[self.orientation][2])
  end
end

function Hands:setDunkTransition()
  local function toShoe(shoe, strengthX)
    local function resetTransition()
      shoe.isTransitionning = false
      shoe.currTran = nil
    end

    local ori = {left = 1, right = -1}

    shoe.isTransitionning = true
    shoe.currTran = transition.to(shoe, {
      time = 250,
      x = shoe.x + ori[self.orientation] * strengthX,
      y = shoe.y - ori[self.orientation] * 5,
      rotation = -85 * ori[self.orientation]
    })
  end
  local strengths = {left = {40, 20}, right = {20, 40}}

  -- if self.left.ssm.sprite.isTransitionning ~= true and self.left.ssm.sprite.isTransitionning ~= true then
    toShoe(self.left.ssm.sprite, strengths[self.orientation][1])
    toShoe(self.right.ssm.sprite, strengths[self.orientation][2])
  -- end
end

function Hands:setWinTransition()
  local function toShoe(shoe)
    local function resetTransition()
      shoe.isTransitionning = false
      shoe.currTran = nil
      toShoe(shoe)
    end

    local ori = {left = 1, right = -1}

    shoe.isTransitionning = true
    shoe.currTran = transition.to(shoe, {
      time = 600,
      x = shoe.x + 5 * ori[self.orientation],
      y = shoe.y - 40,
      rotation = -120 * ori[self.orientation],
      onComplete = resetTransition,
      transition = easing.continuousLoop
    })
  end

  local hands = {"left", "right"}

  for i = 1, #hands do
    if self[hands[i]].ssm.sprite.isTransitionning == true then
      transition.cancel(self[hands[i]].ssm.sprite.currTran)
      self[hands[i]].ssm.sprite.currTran = nil
      self[hands[i]].ssm.sprite.isTransitionning = false
      self.left.ssm.sprite.x = lContainerStartX
      self.left.ssm.sprite.y = lContainerStartY
      self.left.ssm.sprite.rotation = 0
    end
  end

  toShoe(self.left.ssm.sprite)
  toShoe(self.right.ssm.sprite)
end


function Hands:setShootTransition()
  local function toShoe(shoe)
    local function resetTransition()
      shoe.isTransitionning = false
      shoe.currTran = nil
    end

    shoe.isTransitionning = true
    shoe.currTran = transition.to(shoe, {
      time = 150,
      x = shoe.x + 30,
      y = shoe.y - 30,
      rotation = -180,
      onCancel = resetTransition,
      onComplete = resetTransition,
      transition = easing.continuousLoop
    })
  end

  if self.left.ssm.sprite.isTransitionning ~= true and self.left.ssm.sprite.isTransitionning ~= true then
    toShoe(self.left.ssm.sprite)
    toShoe(self.right.ssm.sprite)
  end
end


function Hands:setTransition(transition, data)
  if transition == "walk" then
    self:setWalkTransition(data)
  elseif transition == "take" then
    self:setTakeTransition(data)
  elseif transition == "shoot" then
    self:setTakeTransition(data)
  elseif transition == "dunk" then
    self:setTakeTransition(data)
  elseif transition == "win" then
    self:setWinTransition(data)
  elseif transition == "after-dunk" then
    self:setDunkTransition(data)
  end
end
