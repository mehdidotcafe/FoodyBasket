require "srcs.rendering.containers.BallContainer"
require "srcs.entities.World"
local sm = require "srcs.sound.SoundManager"

Ball = {
  diameter = 26,
  container = nil,
  isTaken = false,
  shootPos = {
    x = 0,
    y = 0
  },
  collideListeners = {},
  owner = nil,
  isResolvingCollide = false,
  lastCollidePlayer = nil,
  origin = nil,
  unresolvedCollideCount = 0,
  afterResolvingCollideFx = {}
}

local rules = require("srcs.Rules")

function Ball:new(path)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.container = BallContainer:new(_self.diameter)
  _self.container:setPath(path)

  _self:addCollideListener()
  return _self
end

function Ball:execAfterCollide()
  for key, fx in ipairs(self.afterResolvingCollideFx) do
    fx()
  end
  self.afterResolvingCollideFx = {}
end

function Ball:addCollideListener()
  local function onCollision(container, e)
    local type = e.other.type
    local ceil = 120
    local vx, vy

    if e.phase == "began" then
      vx, vy = self.container:getLinearVelocity()

      if (math.abs(vx) > ceil or math.abs(vy) > ceil) and sm:isPlaying("bounce") ~= true and type ~= "Player" then sm:play("bounce") end
      self.unresolvedCollideCount = self.unresolvedCollideCount + 1
    elseif e.phase == "ended" then
      self.unresolvedCollideCount = self.unresolvedCollideCount - 1
      if type == "Player" then
        self.fromBelow = false
        self.origin = "HEAD"
        self.shootPos.x = e.other.x
        self.shootPos.y = e.other.y
        if rules.currPlayer ~= e.other.entity and (rules.isOver ~= true or rules.isSuddentDeath == true) then
          rules:startShootClock(e.other.entity)
        end
      end
      self.isResolvingCollide = true
      self:notifyOnCollide(e)
      self.isResolvingCollide = false
    end
    return true
  end

  self:getContainer().collision = onCollision
  self:getContainer():addEventListener("collision")
end

function Ball:addToPhysics()
  local masks = require("srcs.entities.physics.entitiesMask")

  self:getContainer().type = "Ball"
  physics.addBody(self:getContainer(), "dynamic", { density=0.65, friction = 0.3, bounce=0.9, radius= self.diameter / 2, filter= masks["ball"]})
end

function Ball:isTaken()
  return self.owner ~= nil
end

function Ball:notifyOnCollide(event)
  for key, obj in ipairs(self.collideListeners) do
    -- on check si l'obj a pas ete supprime
    if obj ~= nil then
      obj:onBallCollide(event)
    end
  end
end

function Ball:subscribeOnCollide(obj)
  self.collideListeners[table.getn(self.collideListeners) + 1] = obj
  obj.ball = self
end

function Ball:unsubscribeOnCollide(toRemove)
  for key, obj in ipairs(self.collideListeners) do
    if obj == toRemove then
      self.collideListeners[key] = nil
      break
    end
  end
end

function Ball:onUntake(pos)
  if pos ~= nil then
    self.container:setPos(pos)
  end
  self:addToPhysics()
  self:addCollideListener()
  self.fromBelow = false
  self.owner = nil
  self.origin = "SHOOT"
end

function Ball:onTake(player, forcedReset)
  local function removeBody()
    self:getContainer():removeEventListener("collision")
    physics.removeBody(self:getContainer())
  end

  self.owner = player
  self.unresolvedCollideCount = 0
  if self.isResolvingCollide == true then
    timer.performWithDelay(1, removeBody)
  else
    removeBody()
  end
  if rules.currPlayer ~= player.container or forcedReset == true then
    rules:startShootClock(player.container)
  end
end

function Ball:getContainer()
  return self.container:getSprite()
end

function Ball:getPos()
  return self.container:getPos()
end

function Ball:setShootPos(x, y)
  self.shootPos.x = x
  self.shootPos.y = y
end

function Ball:setPos(pos)
  self.container:setPos(pos)
end

function Ball:applyForce(s)
  self.container:applyForce(s)
end

function Ball:getCenter()
  return self.container:getCenter()
end

function Ball:destroy()
  if self.owner == nil then
    physics.removeBody(self:getContainer())
  end
  self.container:destroy()
  self.container = nil
  self.collideListeners = nil
  self.unresolvedCollideCount = 0
end

function Ball:setVisibility(v)
  self.container:setVisibility(v)
end

function Ball:clearForces()
  self.unresolvedCollideCount = 0
  self.container:clearForces()
end
