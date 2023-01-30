require "srcs.rendering.containers.PlayerContainer"
require "srcs.entities.World"
local Size = require "srcs.rendering.Size"

local headWidth, headHeight = Size:headBox()
local shoesWidth, shoesHeight = Size:shoesBox()

Player = {
  lvl = 0,
  instance = 0,

  width = 50,
  height = (50 + 13),

  name = nil,
  container = nil,
  ball = nil,
  baskets = nil,
  scoreChangeListeners = nil,
  score = 0,
  maxStrength = 50,
  currStrengthListeners = nil,
  currStrength = nil,
  hasLooseBall = false,
  isTaking = false,
  isDunking = false,
  dunkTimer = nil,
  looseTimer = nil,
  takeTimer = nil,
  oriOrigin = nil,
  margins = {
    x = headWidth / 3,
    y = (headHeight + shoesHeight) / 3
  },
  strengthCeil = 2.8,
  stats = nil,
  STATS_MID = 5,
  control = nil,
  currTextParticles = nil
}

local rules = require("srcs.Rules")
local sm = require("srcs.sound.SoundManager")
local world = World:new()
local AFTER_SHOOT_DELAY = 600

function Player:resetLooseBall()
  self.looseTimer = nil
  self.hasLooseBall = false
end

function Player:new(orientation, instance)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.oriOrigin = orientation
  _self.instance = instance
  _self.container = PlayerContainer:new(orientation, _self)
  _self.scoreChangeListeners = {}
  _self.currStrengthListeners = {}
  _self.baskets = {}
  _self:setCurrStrength(0)
  return _self
end

function Player:addToPhysics()
  self.container:addToPhysics()
end

function Player:getCenter()
  return self.container:getCenter()
end

function Player:isOnSomething(ceil)
  return self.container:isOnSomething(ceil)
end

function Player:jump()
  local jumpValue = 20 + (self.stats[4] - self.STATS_MID) / 3

  if self:canJump() == true and self.container.isFlipping ~= true then
    local bX, bY = self:getCenter()
    self.container.head:getSprite():applyLinearImpulse(0, -jumpValue, bX, bY)
    self.container.shoes:setTransition("jump")
  elseif self:isOnSomething() == true then
    self:wakeUp()
  end
end

function Player:canJump(margin)
  return self.container:canJump(margin)
end

function Player:getHeadPath()
  return self.container:getHeadPath()
end

function Player:getHandsPath()
  return self.container:getHandsPath()
end

function Player:getBodyPath()
  return self.container:getBodyPath()
end

function Player:getShoesPath()
  return self.container:getShoesPath()
end

function Player:getContainer()
  return self.container.container
end

function Player:getWidth()
  return self.container.head:getSprite().width
end

function Player:getHeadHeight()
  return self.container.head:getSprite().height
end

function Player:getHeight()
  return self.container.head:getSprite().height + self.container.shoes:getSprite().height
end

function Player:getPos()
  return self.container:getPos()
end

function Player:getTopRightPos()
  local pos = self:getPos()
  local coeff = self:getOrientationAsCoeff()

  pos.x = pos.x + self:getWidth() / 2 * coeff
  pos.y = pos.y - self:getHeadHeight() / 2
  return pos
end

function Player:getBotPos()
  return self.container:getBotPos()
end

function Player:getBallPosFromShoot()
  local pos = self:getPos()
  local rota = math.rad(self.container.head:getSprite().rotation)

  local npos = {
    x = 0,
    y = pos.y - self.container.head:getSprite().height / 2
  }

  if self.container.orientation == "right" then
    npos.x = pos.x - self.container.head:getSprite().width / 2 - (self.container.head:getSprite().width / 2 * math.sin(rota)) - self.ball.diameter / 2 - 5
  elseif self.container.orientation == "left" then
    npos.x = pos.x + self.container.head:getSprite().width / 2 + (self.container.head:getSprite().width / 2 * math.sin(rota)) + self.ball.diameter / 2 + 5
  end
  return npos
end

function Player:getOrientation()
  return self.container.orientation
end

function Player:getOrientationAsCoeff()
  return self.container.orientation == "left" and 1 or -1
end

function Player:setChar(path, from)
  self:setName(path.name)
  self:setHead(path, from)
end

function Player:setName(name)
  self.name = name
end

function Player:setLvl(lvl)
  self.lvl = lvl
end

function Player:setHead(path, from)
  self.container:setHead(path, from)
end

function Player:setHands(path, from)
  self.container:setHands(path, from)
end

function Player:setShoes(path, from)
  self.container:setShoes(path, from)
end

function Player:setPos(pos)
  self.container:setPos(pos)
end

function Player:setOrientation(ori, effect)
  if effect ~= "disable" then
    sm:play("flip")
  end
  self.container:setOrientation(ori, effect)
end

function Player:setDefaultAnimation()
  self.container.hands:setAnimation("default")
end

function Player:isWake(ceil)
  if ceil == nil then
    ceil = 45
  end
  return (math.abs(self:getRotation()) % 360) < ceil
end

function Player:move(vec)
  vec = vec + (self.stats[2] - self.STATS_MID) / 10 * vec
  if self.container.isFlipping == true then
    return
  end
  if (vec > 0 and self.container.orientation ~= "left") then
    self:setOrientation("left")
  elseif (vec < 0 and self.container.orientation ~= "right") then
    self:setOrientation("right")
  elseif self.container.isFlipping == false then
    local vx, vy = self.container.head:getSprite():getLinearVelocity()
    if math.abs(vx) < 150 + (self.stats[2] - self.STATS_MID) * 2 then
      local coeff = 1
      if self:isOnSomething() == false then
        coeff = 3
      end
      local bX, bY = self:getCenter()

      self.container.head:getSprite():applyLinearImpulse(vec / coeff, 0, bX, bY)
      self.container.hands:setTransition("walk")
      self.container.shoes:setTransition("walk")
    end
  end
end

function Player:canShoot()
  local hits
  local pos = self:getPos()
  local hPosX

  pos.y = pos.y - self.container.head:getSprite().height / 2
  if self.ball == nil then
    return false
  end
  if self:getOrientation() == "left" then
    hits = physics.rayCast(pos.x, pos.y, pos.x + self.ball.diameter + self.container.head:getSprite().width / 2, pos.y, "unsorted")
    if hits == nil then
      return true
    end
    for i,v in ipairs( hits ) do
      if v.object.entity ~= self.container then
        return false
      end
    end
  else
    hits = physics.rayCast(pos.x, pos.y, pos.x - self.ball.diameter - self.container.head:getSprite().width / 2, pos.y, "unsorted")
    if hits == nil then
      return
    end
    for i,v in ipairs( hits ) do
      if v.object.entity ~= self.container then
        return false
      end
    end
  end
  return true
end

function Player:shoot()
  local maxStrength = self.maxStrength + (self.stats[1] - self.STATS_MID) * 3
  local force = {
    x = maxStrength * self.currStrength / 100,
    y = (-maxStrength * self.currStrength / 100 - 130) / 1.1
  }
  local oris = {
    left = 1,
    right = -1
  }

  if self:canShoot() == false or self.container.isFlipping == true then
    self:setCurrStrength(0)
    return
  end

  physics.pause()
  if self.container.orientation == "right" then
    force.x = force.x * -1
  end
  self.container:untakeBall(self.ball)
  self.ball:setShootPos(self.container.head:getSprite().x  + (self.container.head:getSprite().width / 2 * oris[self.container.orientation]), self.container.head:getSprite().y - self.container.head:getSprite().height)
  self.ball:onUntake(self:getBallPosFromShoot())
  physics.start()
  self.container.hands:setTransition("shoot")
  self.ball:applyForce(force)
  self.ball.lastCollidePlayer = self.container
  self.ball = nil
  self:setCurrStrength(0)
  self.looseTimer = timer.performWithDelay(AFTER_SHOOT_DELAY, function()self:resetLooseBall() end)
end

function Player:setBasket(b)
  self.baskets[#self.baskets + 1] = b
end

function Player:getClosestBasket(baskets)
  local pX = self:getPos().x
  local closest = nil

  for key, value in ipairs(baskets) do
    if closest == nil or math.abs(closest:getPos().x - pX) > math.abs(value:getPos().x - pX) then
      closest = value
    end
  end
  return closest
end

function Player:dunk()
  local bX, bY = self:getCenter()
  local basket = self:getClosestBasket(self.baskets)
  local pos = basket:getPos()
  local ball = self.ball
  local oldY
  local margin

  if self.isDunking == true or self.container.isFlipping == true then return end

  if self.container.orientation == "right" then margin = self:getPos().x - self:getWidth() / 2 - basket.container.topRim.x
  else margin = basket.container.topRim.x - (self:getPos().x + self:getWidth() / 2)  end


  local function ballDunk()
    local value = -100

    if self:getOrientation() == "left" then value = -value end
    if self.ball == nil then
      Runtime:removeEventListener("enterFrame", ballDunk)
      self.dunkTimer = nil
      self.isDunking = false
    elseif self.ball:getPos().y + self.ball.diameter / 2 < pos.y - pos.height / 2 then
      self.container.hands:setTransition("dunk")
      self:untake({x=0, y=500}, margin, true)
      ball.origin = "DUNK"
      self.dunkTimer = nil
      Runtime:removeEventListener("enterFrame", ballDunk)
      self.isDunking = false
      basket:weldPlayer(self)
    elseif oldY <= self:getPos().y then
      self.isDunking = false
      self.dunkTimer = nil
      Runtime:removeEventListener("enterFrame", ballDunk)
    end
    oldY = self:getPos().y
  end

  if self:getOrientation() == "left" then x = 200 else x = -200 end
  oldY = self:getPos().y
  self:clearForces(true)
  self:resetHands()
  self.container.head:getSprite():applyLinearImpulse(0, -38, bX, bY)
  self.isDunking = true
  self.container.shoes:setTransition("jump")
  Runtime:addEventListener("enterFrame", ballDunk)
end

function Player:canTakeBall(ball)
  local pPos = self:getPos()
  local bPos = ball:getPos()
  local orientation = self.container.orientation

  if (rules:getMatchClockRemainTime() ~= 0 or rules.isSuddentDeath == true) and rules:getShootClockRemainTime() ~= 0 and self.hasLooseBall == false then
    if orientation == "left" and bPos.x > pPos.x - self:getWidth() / 2 and pPos.x + (self:getWidth() / 2) + self.margins.x >= bPos.x - ball.diameter / 2 and
    pPos.y + self:getHeight() / 2 > bPos.y and pPos.y - self:getHeight() / 2 < bPos.y
    then
      return true
    elseif orientation == "right" and bPos.x <= pPos.x + self:getWidth() / 2 and bPos.x + (ball.diameter / 2) + self.margins.x >= pPos.x - (self:getWidth() / 2) and
    pPos.y + self:getHeight() / 2 > bPos.y and pPos.y - self:getHeight() / 2 < bPos.y
    then
      return true
    end
  end
  return false
end

function Player:resetHands()
  local left = self.container.hands:getSprite()["left"]
  local right = self.container.hands:getSprite()["right"]

  left:setLinearVelocity(0, 0)
  left.angularVelocity = 0
  right:setLinearVelocity(0, 0)
  right.angularVelocity = 0
  self.container:resetHandsPos()
end

function Player:handsTake()
  self.container.hands:setTransition("take")
end

function Player:handsDunk()
  self.container.hands:setTransition("after-dunk")
end

function Player:take(ball, forced)
  local bPos = ball:getPos()
  local lh

  if (ball.owner == nil and self:canTakeBall(ball) == true and self.container.isFlipping ~= true and self.looseTimer == nil) or forced == true then
    self.ball = ball
    ball:onTake(self, forced)
    self.container:takeBall(ball)
    if forced ~= true then
      self:handsTake()
    end
    self.takeTimer = nil
  end
end

function Player:canHit(other)
  local p1pos
  local p2pos

  p1pos = self:getPos()
  p2pos = other:getPos()
  if self:getOrientation() == "left" then
    return p1pos.x < p2pos.x and p1pos.x + self:getWidth() / 2 + self.margins.x >= p2pos.x - other:getWidth() / 2
          and p1pos.y >= p2pos.y - other:getHeight() / 2 and p1pos.y < p2pos.y + other:getHeight() / 2
  else
    return p1pos.x > p2pos.x and p1pos.x - self:getWidth() / 2 - self.margins.x <= p2pos.x + other:getWidth() / 2
    and p1pos.y >= p2pos.y - other:getHeight() / 2 and p1pos.y < p2pos.y + other:getHeight() / 2
  end
end

function Player:stealBall(other)
  local p1pos
  local p2pos

  p1pos = self:getPos()
  p2pos = other:getPos()

  self:handsTake()
  if self:canHit(other) == true then
    other:hitted(p1pos.y + 10, p1pos.x, self.stats[1] * 4)
    if other.ball ~= nil then
      other:untake({y = -100, x = 0})
    end
  end
end

function Player:canLooseBall(positions)
  local hits
  local pos = self:getPos()
  local width = self:getWidth() / 4
  local height = self:getHeight() / 2

  pos.x = pos.x + width
  pos.y = pos.y - self:getHeight() / 2
  for k, vector in pairs(positions)
  do
    hits = physics.rayCast(pos.x, pos.y, pos.x + (width + self.ball.diameter) * vector.x, pos.y + (height + self.ball.diameter) * vector.y, "closest")
    if hits == nil then
      return {y=pos.y + height * vector.y, x=pos.x + width * vector.x}, vector
    end
  end
  return nil, nil
end

function Player:canUntake(pos)
   local hits = physics.rayCast(self:getPos().x, self:getPos().y, pos.x, pos.y, "unsorted")

   if hits == nil then return true end
   for i, v in ipairs(hits) do
     if self.container:isPlayerObject(v.object) == false then
       return false
     end
   end
   return true
end

function Player:untake(force, margin, forced)
  local pos = {
    x = self:getPos().x,
    y = self:getPos().y
  }
  local pos2 = {
    x = self:getPos().x,
    y = self:getPos().y
  }

  local function looseBallAtPos(p)
    self.container:untakeBall(self.ball)
    self.ball:onUntake(p)
    if force ~= nil then
      self.ball.container:setLinearVelocity(force)
    end
    self.ball = nil
    self.hasLooseBall = true
    self.looseTimer = timer.performWithDelay(AFTER_SHOOT_DELAY, function()self:resetLooseBall() end)
  end

  if margin == nil then margin = 10 end
  if self.container.orientation == "left" then
    pos2.x = pos.x - self:getWidth() / 2 - margin
    pos.x = pos.x + self:getWidth() / 2 + margin
  else
    pos2.x = pos.x + self:getWidth() / 2 + margin
    pos.x = pos.x - self:getWidth() / 2 - margin
  end

  pos.y = pos.y - self:getHeight() / 2
  if self.ball ~= nil and (self:canUntake(pos) == true or forced == true) then
    looseBallAtPos(pos)
  elseif self.ball ~= nil and (self:canUntake(pos2) == true or forced == true) then
    looseBallAtPos(pos2)
  end
  self:setCurrStrength(0)
end

function Player:resetBall()
  self.container:untakeBall(self.ball)
  self.ball:onUntake()
  self.ball = nil
  self:setCurrStrength(0)
end

function Player:incrScore(value)
  self.score = self.score + value
  self:notifyScoreChange()
end

function Player:setScore(score)
  self.score = score
  self:notifyScoreChange()
end

function Player:subscribeScoreChange(obj)
  self.scoreChangeListeners[table.getn(self.scoreChangeListeners) + 1] = obj
end

function Player:notifyScoreChange()
  for key, obj in ipairs(self.scoreChangeListeners) do
    obj:onScoreChange(self.score)
  end
end

function Player:subscribeCurrStrengthChange(obj)
  self.currStrengthListeners[table.getn(self.currStrengthListeners) + 1] = obj
end

function Player:notifyCurrStrengthChange()
  for key, obj in ipairs(self.currStrengthListeners) do
    obj:onCurrStrengthChange(self.currStrength, self.maxStrength)
  end
end

function Player:setCurrStrength(s)
  self.currStrength = math.min(s, 100)
  self:notifyCurrStrengthChange()
  if self.currStrength >= 100 then
    self:shoot()
  end
end

function Player:onReleaseChange(pressTime)
  if self.ball ~= nil then
    self:shoot()
  end
end

function Player:onPressContinue(pressTime)
  if self.ball ~= nil then
    self:setCurrStrength(pressTime)
  end
end

function Player:destroy()
  if self.currTextParticles ~= nil then
    self.currTextParticles:destroy()
    self.currTextParticles = nil
  end
  if self.ball ~= nil then
    self.container:unbounceBall(self.ball)
    self.ball = nil
  end
  if self.dunkTimer ~= nil then timer.cancel(self.dunkTimer) end
  if self.looseTimer ~= nil then timer.cancel(self.looseTimer) end
  if self.takeTimer ~= nil then timer.cancel(self.takeTimer) end
  self.container:destroy()
  self.container = nil
  self.name = nil
  self.baskets = nil
  self.scoreChangeListeners = nil
  self.currStrengthListeners = nil
  self.stats = nil
end

function Player:getRotation()
  return self.container:getRotation()
end

function Player:clearForces(resetRotation)
  self.container:clearForces(resetRotation)
end

function Player:resetRotation()
  self.container:resetRotation()
end

function Player:wakeUp()
  self.container:wakeUp()
end

function Player:hitted(y, x, force)
  -- if sm:isPlaying("cry") ~= true then
  --   sm:play("cry")
  -- end
  self.container:hitted(y, x, force)
end

function Player:insertToContainer(container)
  self.container:insertToContainer(container)
end

function Player:cancelFlipTransitions()
  self.container:cancelFlipTransitions()
end

function Player:onPause()
  if self.dunkTimer ~= nil then timer.pause(self.dunkTimer) end
  if self.looseTimer ~= nil then timer.pause(self.looseTimer) end
  if self.takeTimer ~= nil then timer.pause(self.takeTimer) end
end

function Player:onResume()
  if self.dunkTimer ~= nil then timer.resume(self.dunkTimer) end
  if self.looseTimer ~= nil then timer.resume(self.looseTimer) end
  if self.takeTimer ~= nil then timer.resume(self.takeTimer) end
end

function Player:die()
  if self.ball ~= nil then self:untake() end
  self.container.joint:removeSelf()
  self.container.lhjoint:removeSelf()
  self.container.rhjoint:removeSelf()

  self.container.joint = nil
  self.container.lhjoint = nil
  self.container.rhjoint = nil
end

function Player:setVisibility(v)
  self.container:setVisibility(v)
end

function Player:scale(v)
  self.container:scale(v)
end

function Player:win(sceneGroup)
  local txt = display.newText{
    parent = sceneGroup,
    font = native.newFont('font/GROBOLD', 12),
    text = "YES !"
  }
  txt:setFillColor(Colors:getColor("red"))

  self.container.hands:setTransition("win")
  self.currTextParticles = Render:textParticles(function()return self.container.head:getSprite().x +  self.container.head:getSprite().width / 3 end, function() return self.container.head:getSprite().y -  self.container.head:getSprite().height / 2 end, self.container.head:getSprite().width / 2, txt)
end

function Player:getStatsConst(stats)
  local head = (stats and stats.head) or self.container.head.stats
  local shoes = (stats and stats.shoes) or self.container.shoes.stats
  local hands = (stats and stats.hands) or self.container.hands.stats

  return {
    head[1] + hands[1] + shoes[1],
    head[2] + hands[2] + shoes[2],
    head[3] + hands[3] + shoes[3],
    head[4] + hands[4] + shoes[4],
    head[5] + hands[5] + shoes[5],
  }
end

function Player:getStats()
  self.stats = {
    self.container.head.stats[1] + self.container.hands.stats[1] + self.container.shoes.stats[1],
    self.container.head.stats[2] + self.container.hands.stats[2] + self.container.shoes.stats[2],
    self.container.head.stats[3] + self.container.hands.stats[3] + self.container.shoes.stats[3],
    self.container.head.stats[4] + self.container.hands.stats[4] + self.container.shoes.stats[4],
    self.container.head.stats[5] + self.container.hands.stats[5] + self.container.shoes.stats[5]
  }

  self.stats[1] = math.min(math.max(0, self.stats[1]), 10)
  self.stats[2] = math.min(math.max(0, self.stats[2]), 10)
  self.stats[3] = math.min(math.max(0, self.stats[3]), 10)
  self.stats[4] = math.min(math.max(0, self.stats[4]), 10)
  self.stats[5] = math.min(math.max(0, self.stats[5]), 10)
  return self.stats
end

function Player:canDunk()
  for i = 1, #self.baskets do
    if self.baskets[i]:playerCanDunk(self) == true then
      return true
    end
  end
  return false
end
