require "srcs.rendering.limbs.Body"
require "srcs.rendering.limbs.Hands"
require "srcs.rendering.limbs.Shoes"
require "srcs.rendering.limbs.Head"
require "srcs.entities.World"

local Size = require "srcs.rendering.Size"
local sm = require "srcs.sound.SoundManager"
local world = World:new()

local headWidth, headHeight = Size:headBox()

local PLAYER_DIMS = {
  height = (Size.head.height + Size.shoes.height),
  width = Size.head.width,
  head = {
    offY = 0
  },
  hands = {
    offY =  2 * headHeight / 5
  },
  shoes = {
    offY = headHeight
  }
}

PlayerContainer = {
  head = nil,
  hands = nil,
  shoes = nil,
  animation = nil,
  orientation = nil,
  joint = nil,
  lhjoint = nil,
  rhjoint = nil,
  addedInPhysics = false,
  isFlipping = nil,
  bounceTransition = nil,
  wrapper = nil,
  followTimer = nil
}

function PlayerContainer:new(orientation, wrapper)
  local _self = {}
  local width, height

  setmetatable(_self, self)
  self.__index = self

  width, height = Size:headBox()
  _self.head = Head:new(width, height, PLAYER_DIMS.head.offY - Size.head.height / 2  + Size.head.height / 2, nil)
  width, height = Size:shoesBox()
  _self.shoes = Shoes:new(width, height, PLAYER_DIMS.shoes.height, 0, PLAYER_DIMS.shoes.offY - Size.shoes.height / 2 + Size.shoes.height / 2, nil)
  width, height = Size:handsBox()
  _self.hands = Hands:new(width, height, 0, PLAYER_DIMS.hands.offY - Size.hands.height  + Size.hands.height / 2, nil)
  _self.wrapper = wrapper

  _self:setOrientation(orientation, "disable")
  _self.isFlipping = false
  _self.instance = wrapper.instance

  return _self
end

function PlayerContainer:getShoesRotation()
  return self.shoes:getSprite().rotation % 360
end

function PlayerContainer:getHeadRotation()
  return self.head:getSprite().rotation % 360
end

function PlayerContainer:rotationSup(rot, value)
  return rot > value and 360 - value > rot
end

function PlayerContainer:canJump(ceil)
  local height = self.shoes:getBoundingBox().height
  local width = self.shoes:getBoundingBox().width
  local x = self.shoes:getBoundingBox().x - width / 2
  local y = self.shoes:getBoundingBox().y + height / 2

  if ceil == nil then
    ceil = 5
  end

  local targetX = x + width
  local targetY = y + ceil

  local hits = physics.rayCast(x - 1, y, targetX + 1, targetY, "unsorted")

  if hits ~= nil then
    for k, hit in ipairs(hits) do
      if hit.object.entity ~= self then
        return true
      end
    end
  end
  x = self.shoes:getBoundingBox().x + width / 2
  targetX = x - width
  local hits = physics.rayCast(x + 1, y, targetX - 1, targetY, "unsorted")
  if hits ~= nil then
    for k, hit in ipairs(hits) do
      if hit.object.entity ~= self then
        return true
      end
    end
  end
  return false
end

function PlayerContainer:isOnSomething(ceil)
  return self:canJump(ceil)
end

function PlayerContainer:getPos()
  local pos = {
    x = self.head:getSprite().x,
    y = self.head:getSprite().y
  }

  return pos
end

function PlayerContainer:getBotPos()
  local pos = {
    x = self.shoes:getSprite().x,
    y = self.shoes:getSprite().y + self.shoes:getSprite().height / 2
  }

  return pos
end

function PlayerContainer:getHeadPath()
  return self.head.path
end

function PlayerContainer:getHandsPath()
  return self.hands.path
end

function PlayerContainer:getShoesPath()
  return self.shoes.path
end

function PlayerContainer:setHead(path, from)
  self.head:setPath(path)
  self.head:setOrientation(self.orientation, from)
  self:insertToContainer()
end

function PlayerContainer:setHands(handPath, from)

  self.hands:setPath(handPath)
  self.hands:setOrientation(self.orientation, from)
  self:insertToContainer()
end

function PlayerContainer:setShoes(path, from)
  self.shoes:setPath(path)
  self.shoes:setOrientation(self.orientation, from)
  self:insertToContainer()
end

function PlayerContainer:setOrientation(orientation, effect)

  local flipDuration = 100
  local function onFlippingEnd()
    self.isFlipping = false
  end

  if self.orientation ~= orientation and self.isFlipping ~= true then
    self.isFlipping = true
    self.hands:setOrientation(orientation, effect)
    self.shoes:setOrientation(orientation, effect)
    if self.head.path ~= nil then
      self.head:setOrientation(orientation, effect, onFlippingEnd)
    end
    self.orientation = orientation
    timer.performWithDelay(flipDuration, onFlippingEnd)
  end
end

function PlayerContainer:setAnimation(animation)
  if self.animation ~= animation then
    self.animation = animation
    if self.head ~= nil then
      self.head:setAnimation(animation)
    end
    self.hands:setAnimation(animation)
    self.shoes:setAnimation(animation)
  end
end

function PlayerContainer:unbounceBall(ball)
  if self.followTimer ~= nil then Runtime:removeEventListener("enterFrame", self.followTimer) end
  if self.bounceTransition ~= nil then
    transition.cancel(self.bounceTransition)
  end
  self.followTimer = nil
  ball.isBouncing = false
end

function PlayerContainer:bounceBall(ball)
  local hasJump = false

  if ball.isBouncing == true then
    return
  end

  local function subBounceBall()

    local function callback()
      if self.bounceTransition ~= nil and ball.isBouncing == true then
        subBounceBall()
      end
    end

    if world.axis == nil or self:canJump() == false
    then
      timer.performWithDelay(50, callback)
    else
      local wx, wy = world.axis.bot:localToContent(0, 0)

      ball.y = self.head:getSprite().y
      self.bounceTransition = transition.to(ball, {
        transition = easing.continuousLoop,
        y = ball.y + self.head:getSprite().height / 2 + self.shoes:getBoundingBox().height - ball.height / 2,
        time = 250,
        onComplete = callback
      })
    end
  end

  local function followPlayer()
    if self:canJump() == false then
      hasJump = true
      if self.bounceTransition ~= nil then
        transition.cancel(self.bounceTransition)
        self.bounceTransition = nil
      end
      ball.y = self.head:getSprite().y
    elseif hasJump == true then
      hasJump = false
      subBounceBall()
    end
    if self.orientation == "left" then
      ball.x = self.head:getSprite().x + self.head:getSprite().width / 4 + 5
    else
      ball.x = self.head:getSprite().x - self.head:getSprite().width / 4 - 5
    end
  end

  ball.isBouncing = true
  self.followTimer = followPlayer
  followPlayer()
  Runtime:addEventListener("enterFrame", followPlayer)
  subBounceBall()
end

function PlayerContainer:getWidth()
  return self.head:getSprite().width
end

function PlayerContainer:getHeight()
  return self.head:getSprite().height
end

function PlayerContainer:takeBall(ball)
  local bc = ball:getContainer()

  ball:setPos({x = self:getWidth() / 2 - ball.diameter / 2, y = 0})
  self:bounceBall(ball:getContainer())
end

function PlayerContainer:untakeBall(ball)
  self.hands:setAnimation("default", true)
  self:unbounceBall(ball:getContainer())
end

function PlayerContainer:hitted(y, x, force)
  local c = self.head:getSprite()

  if x < c.x then
    c:applyForce(300 + force, -100 - force, c.x - self:getWidth() / 2, y)
    c:applyTorque(180 + force)
  else
    c:applyForce(-300 - force, -100 - force, c.x + self:getWidth() / 2, y)
    c:applyTorque(-180 - force)
  end
end

function PlayerContainer:clearForces(resetRotation)
  local elem = self.shoes:getSprite()

  self.shoes:getSprite().angularVelocity = 0
  self.shoes:getSprite():setLinearVelocity(0, 0)
  self.head:getSprite().angularVelocity = 0
  self.head:getSprite():setLinearVelocity(0, 0)
  self.hands:getSprite()["left"].angularVelocity = 0
  self.hands:getSprite()["left"]:setLinearVelocity(0, 0)
  self.hands:getSprite()["right"].angularVelocity = 0
  self.hands:getSprite()["right"]:setLinearVelocity(0, 0)
  if resetRotation == true then
    self.head:getSprite().rotation = 0
    self.hands:getSprite()["left"].rotation = 0
    self.hands:getSprite()["right"].rotation = 0
    self.shoes:getSprite().rotation = 0
  end
end

function PlayerContainer:clearForcesHead(resetRotation)
  local elem = self.head:getSprite()

  elem.angularVelocity = 0
  elem:setLinearVelocity(0, 0)
  if resetRotation == true then
    elem.rotation = 0
  end
end

function PlayerContainer:removePhysics()
  physics.removeBody(self.head:getSprite())
  physics.removeBody(self.shoes:getSprite())
  physics.removeBody(self.hands:getSprite()["left"])
  physics.removeBody(self.hands:getSprite()["right"])
end

function PlayerContainer:destroy()
  if self.addedInPhysics == true then
    self:removePhysics()
    if self.joint ~= nil then
      self.joint:removeSelf()
      self.joint = nil
    end
    if self.lhjoint ~= nil then
      self.lhjoint:removeSelf()
      self.lhjoint = nil
    end
    if self.rhjoint ~= nil then
      self.rhjoint:removeSelf()
      self.rhjoint = nil
    end
    self.addedInPhysics = false
  end
  self.head:destroy()
  self.head = nil
  self.shoes:destroy()
  self.shoes = nil
  self.hands:destroy()
  self.hands = nil
  if self.followTimer ~= nil then
    Runtime:removeEventListener("enterFrame", self.followTimer)
    self.followTimer = nil
  end
end

function PlayerContainer:insertToContainer(container)

  if container == nil then
    container = display.getCurrentStage()
  end
  container:insert(self.hands:getSprite()["right"]);
  if self.head:getSprite() ~= nil then
    if self.shoes:getSprite() ~= nil then
      container:insert(self.shoes:getSprite());
    end
    container:insert(self.head:getSprite());
  end
  container:insert(self.hands:getSprite()["left"]);
end

function PlayerContainer:getMass()
  return self.head:getSprite().mass
end

function PlayerContainer:getCenter()
  local x, y = self.head:getSprite():getMassWorldCenter()
  local x2, y2 = self.shoes:getSprite():getMassWorldCenter()
  local hM = self.head:getSprite().mass
  local sM = self.shoes:getSprite().mass


  local bX = (hM * x + sM * x2) / (hM + sM)
  local bY = (hM * y + sM * y2) / (hM + sM)

  return bX, bY
end

function PlayerContainer:addToPhysics()
  local masks = require("srcs.entities.physics.entitiesMask")
  local lhand = self.hands:getSprite()["left"]
  local rhand = self.hands:getSprite()["right"]
  local shoes = self.shoes:getSprite()
  local head = self.head:getSprite()
  local headMass
  local headArea

  lhand.type = "Player"
  lhand.entity = self
  rhand.type = "Player"
  rhand.entity = self
  shoes.type = "Player"
  shoes.entity = self
  head.type = "Player"
  head.entity = self

  physics.addBody(lhand, "dynamic", {density=0, friction = 1, bounce=0, outline=self.hands:getOuter()["left"], filter= masks["player" .. tostring(self.instance) .. "Hands"]})
  physics.addBody(head, "dynamic", {density=0.85, friction = 0.2, outline=self.head:getOuter(), bounce=0.1, filter= masks["player" .. tostring(self.instance)]})
  physics.addBody(shoes, "dynamic", {density=1.5, friction = 0.6, bounce=0, shape=self.shoes:getOuter(), filter= masks["player" .. tostring(self.instance)] })
  physics.addBody(rhand, "dynamic", {density=0, friction = 1, bounce=0, outline=self.hands:getOuter()["right"], filter= masks["player" .. tostring(self.instance) .. "Hands"] })

  headMass = self:getMass()
  headArea = headMass / 0.85
  physics.removeBody(head)
  physics.addBody(head, "dynamic", {density= 1.5 / headArea, friction = 0.2, outline=self.head:getOuter(), bounce=1, filter= masks["player" .. tostring(self.instance)]})
  local bX, bY = self:getCenter()
  self.joint = physics.newJoint("weld", head, shoes, bX, bY)
  self.lhjoint = physics.newJoint("weld", head, lhand, lhand.x, head.y - 1)
  self.rhjoint = physics.newJoint("weld", head, rhand, rhand.x, head.y - 1)
  self.joint.dampingRatio = 0.1
  self.joint.frequency = 1
  self.addedInPhysics = true
  shoes.isFixedRotation = true

  local function onCollide(elem, event)
    local vx, vy

    if event.phase == "ended" then
      vx, vy = event.target:getLinearVelocity()
      event.target:setLinearVelocity(vx / 4, vy / 4)
    end
  end

  local function onShoesCollide(elem, event)
    local vx, vy = elem:getLinearVelocity()
    if event.phase == "began" and math.abs(vy) > 100 then
      sm:play("foot" .. math.random(1, 2))
    end
    onCollide(elem, event)
  end

  shoes.collision = onShoesCollide
  shoes:addEventListener("collision")
  head.collision = onCollide
  head:addEventListener("collision")
end

function PlayerContainer:getRotation()
  return self.shoes:getSprite().rotation
end

function PlayerContainer:getShapeCenter()
  local head =  self.head:getSprite()
  local shoes = self.shoes:getSprite()
  local x
  local y

  if head.x > shoes.x then
    x = shoes.x + (head.x - shoes.x) / 2
  else
    x = head.x + (shoes.x - head.x) / 2
  end
  return x, (head.y + (shoes.height) / 2)
end

function PlayerContainer:setBodyActive(value)
  self.head:getSprite().isBodyActive = value
  self.hands:getSprite()["left"].isBodyActive = value
  self.hands:getSprite()["right"].isBodyActive = value
  self.shoes:getSprite().isBodyActive = value
end

function PlayerContainer:setAttribute(attr, value)
  self.head:getSprite()[attr] = value
  self.hands:getSprite()["left"][attr] = value
  self.hands:getSprite()["right"][attr] = value
  self.shoes:getSprite()[attr] = value
end

function PlayerContainer:setBodyType(type)
  self.head:getSprite().bodyType = value
  self.hands:getSprite()["left"].bodyType = value
  self.hands:getSprite()["right"].bodyType = value
  self.shoes:getSprite().bodyType = value
end

function PlayerContainer:wakeUp(noTransition)
  local height = self.head:getSprite().height + self.shoes:getSprite().height
  local x, y = self:getShapeCenter()

  if self.isFlipping == true then
    return
  end

  x = x + (height / 2 * math.cos(math.rad(self.shoes:getSprite().rotation)))
  self.isFlipping = true
  self:setBodyActive(false)
  self:clearForces()

  local function resetRotation()
    self.head:getSprite().rotation = 0
    self.hands:getSprite()["left"].rotation = 0
    self.hands:getSprite()["right"].rotation = 0
    self.shoes:getSprite().rotation = 0
  end


  local function onEnd()
    self.isFlipping = false
    self:setBodyActive(true)
  end

  if noTransition == nil then
    transition.to(self.head:getSprite(), {
      x = x,
      rotation = 0,
      time = 100
    })
    transition.to(self.hands:getSprite()["left"], {
      x = x,
      rotation = 0,
      time = 100
    })
    transition.to(self.hands:getSprite()["right"], {
      x = x,
      rotation = 0,
      time = 100
    })
    transition.to(self.shoes:getSprite(), {
      x = x,
      rotation = 0,
      time = 100,
      onComplete = onEnd
    })
  else
    self.head:getSprite().x = x
    self.head:getSprite().rotation = 0
    self.hands:getSprite()["left"].x = x
    self.hands:getSprite()["left"].rotation = 0
    self.hands:getSprite()["right"].x = x
    self.hands:getSprite()["right"].rotation = 0
    self.shoes:getSprite().rotation = 0
    self.shoes:getSprite().x = x
    onEnd()
  end
end

function PlayerContainer:resetHandsPos()
  local pos = self:getPos()
  local lHand = self.hands:getSprite()["left"]
  local rHand = self.hands:getSprite()["right"]


  lHand.x = pos.x - self:getWidth() / 4
  lHand.y = pos.y + PLAYER_DIMS.hands.offY

  rHand.x = pos.x + self:getWidth() / 4
  rHand.y = pos.y  + PLAYER_DIMS.hands.offY
end

function PlayerContainer:setPos(pos)
  local head = self.head:getSprite()
  local shoes = self.shoes:getSprite()
  local lHand = self.hands:getSprite()["left"]
  local rHand = self.hands:getSprite()["right"]

  head.x = pos.x
  head.y = pos.y

  shoes.x = pos.x
  shoes.y = pos.y + head.height / 2 + shoes.height / 2

  lHand.x = pos.x - self:getWidth() / 4
  lHand.y = pos.y + PLAYER_DIMS.hands.offY

  rHand.x = pos.x + self:getWidth() / 4
  rHand.y = pos.y  + PLAYER_DIMS.hands.offY
end


function PlayerContainer:resetRotation()
  self.head:getSprite().rotation = 0
  self.hands:getSprite()["left"].rotation = 0
  self.hands:getSprite()["right"].rotation = 0
  self.shoes:getSprite().rotation = 0
end

function PlayerContainer:cancelFlipTransitions()
  local t1, t2 = self.hands:getTransition()

  if t1 ~= nil then
    transition.cancel(t1)
  end
  if t2 ~= nil then
    transition.cancel(t2)
  end
  t1 = self.head:getTransition()
  if t1 ~= nil then
    transition.cancel(t1)
  end
  t1 = self.shoes:getTransition()
  if t1 ~= nil then
    transition.cancel(t1)
  end
end

function PlayerContainer:isPlayerObject(o)
  return o == self.head:getSprite() or o == self.hands:getSprite()["left"] or
    o == self.hands:getSprite()["right"] or o == self.shoes:getSprite()
end

function PlayerContainer:setVisibility(v)
  self.head:getSprite().isVisible = v
  self.shoes:getSprite().isVisible = v
  self.hands:getSprite()["right"].isVisible = v
  self.hands:getSprite()["left"].isVisible = v
end

function PlayerContainer:scale(value)
  self.head:getSprite().width = self.head:getSprite().width * value
  self.head:getSprite().height = self.head:getSprite().height * value

  self.hands:getSprite()["left"].height = self.hands:getSprite()["left"].height * value
  self.hands:getSprite()["left"].width = self.hands:getSprite()["left"].width * value

  self.hands:getSprite()["right"].height = self.hands:getSprite()["right"].height * value
  self.hands:getSprite()["right"].width = self.hands:getSprite()["right"].width * value

  self.hands:getSprite()["left"].x = self.head:getSprite().x - self:getWidth() / 4 * value
  self.hands:getSprite()["right"].x = self.head:getSprite().x + self:getWidth() / 4 * value
  self.hands:getSprite()["left"].y = self.head:getSprite().y + PLAYER_DIMS.hands.offY * value
  self.hands:getSprite()["right"].y = self.head:getSprite().y + PLAYER_DIMS.hands.offY * value


  self.shoes:getSprite().width = self.shoes:getSprite().width * value
  self.shoes:getSprite().height = self.shoes:getSprite().height * value
  self.shoes:getSprite().y = self.head:getSprite().y + self.head:getSprite().height / 2 + self.shoes:getSprite().height / 2

end
