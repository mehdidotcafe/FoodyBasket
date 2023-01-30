AI = {
  DEF_LVL = 1,
  MAX_LVL = 10,
  player = nil,
  opp = nil,
  tree = nil,
}

local world = World:new()
local isShoting = false
local isWaitingShoot = false
local hadJump = false
local shootAfterTimer = nil
local resetHadJumpTimer = nil
local waitingShootTimer = nil
local randomness = 0
local rules = require("srcs.Rules")
local isStealing = false

function AI:new(player, opp, r)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.player = player
  _self.opp = opp
  if r == nil then r = 10 end
  randomness = r
  _self:initTree()
  return _self
end

function AI:createNode(fx, left, right)
  local node = {
    fx=fx,
    left=left,
    right=right
  }

  return node
end

function resetHadJump()
  hadJump = false
  resetHadJumpTimer = nil
end

function isWake(ball, controlled, opponent, time)
  return controlled:isWake(60) == true or controlled:isOnSomething() == false
end

function doWake(ball, controlled, opponent, time)
  controlled:wakeUp()
end

function isFree(ball, controlled, opponent, time)
  return ball.owner == nil
end

function isFarerThanOpponent(ball, controlled, opponent, time)
  local c = controlled:getPos()
  local o = opponent:getPos()
  local b = ball:getPos()

  return math.abs(o.x - b.x) + math.abs(o.y - b.y) <= math.abs(c.x - b.x) + math.abs(c.y - b.y)
end

function isAtMid(ball, controlled, opponent, time)
  return controlled:getPos().x > world.axis.center.x - 10 and controlled:getPos().x < world.axis.center.x + 10
end

function isOrientedToGoMid(ball, controlled, opponent, time)
  return (controlled:getOrientation() == "left" and controlled:getPos().x < world.axis.center.x)
          or (controlled:getOrientation() == "right" and controlled:getPos().x > world.axis.center.x)
end

function isOrientedToOpp(ball, controlled, opponent, time)
  return (controlled:getOrientation() == "left" and controlled:getPos().x < opponent:getPos().x)
          or (controlled:getOrientation() == "right" and controlled:getPos().x > opponent:getPos().x)
end

function isOrientedToBall(ball, controlled, opponent, time)
  return (controlled:getOrientation() == "left" and controlled:getPos().x < ball:getPos().x + ball.diameter)
          or (controlled:getOrientation() == "right" and controlled:getPos().x > ball:getPos().x  - ball.diameter)
end

function isOrientedToBasket(ball, controlled, opponent, time)
  return (controlled:getOrientation() == "left" and controlled.baskets[1]:getOrientation() == "right")
    or (controlled:getOrientation() == "right" and controlled.baskets[1]:getOrientation() == "left")
end

function doChangeOrientation(ball, controlled, opponent, time)
  if controlled:getOrientation() == "right" then
    controlled:move(1)
  else
    controlled:move(-1)
  end
end

function doGoForward(ball, controlled, opponent, time)
  if isSomethingBefore(ball, controlled, opponent, time) == true then
    doJump(ball, controlled, opponent, time)
  else
    if controlled:getOrientation() == "right" then
      controlled:move(-1)
    else
      controlled:move(1)
    end
  end
end

function isNearBall(ball, controlled, opponent, time)
  return controlled:canTakeBall(ball)
end

function doTake(ball, controlled, opponent, time)
  controlled:take(ball)
end

function doSteal(ball, controlled, opponent, time)
  if isStealing == true then return end
  isStealing = true
  timer.performWithDelay(300, function() isStealing = false end)
  if 10 - randomness < math.random(1, 10) then
    controlled:stealBall(opponent)
  end
end

function isOwningBall(ball, controlled, opponent, time)
  return ball.owner == controlled
end

function isOppBefore(ball, controlled, opponent, time)
  local cPos = controlled:getPos()
  local oPos = opponent:getPos()
  local bPos = controlled.baskets[1]:getPos()

  if cPos.x < bPos.x and
    cPos.x > oPos.x and cPos.x + controlled:getWidth() < oPos.x - opponent:getWidth() / 2 then
      return true
  elseif cPos.x > bPos.x and cPos.x < oPos.x and cPos.x - controlled:getWidth() > oPos.x + opponent:getWidth() / 2 then
      return true
  end
  return false
end

function isAbleToTake(ball, controlled, opponent, time)
  local cPos = controlled:getPos()
  local oPos = opponent:getPos()

  return  (controlled:getOrientation() == "left" and cPos.x < oPos.x and cPos.x + controlled:getWidth() > oPos.x) or
          (controlled:getOrientation() == "right" and cPos.x > oPos.x and cPos.x - opponent:getWidth() < oPos.x)
end

function isJumping(ball, controlled, opponent, time)
  return (not controlled:canJump())
end

function isAtShootRange(ball, controlled, opponent, time)
  return getRequiredStrengthToShoot(controlled, true) <= controlled.maxStrength * 1.2
end

function getRequiredStrengthToShoot(controlled, needMaxStrength)
  local strength = 0
  local strengthNoise = 0
  local maxStrength = controlled.maxStrength + (controlled.stats[1] - controlled.STATS_MID) * 3
  distance = math.abs(controlled:getPos().x - controlled.baskets[1]:getPos().x)
  -- percentage
  strength = distance * 0.33
  -- add noise depending on AI lvl
  strengthNoise = strength / 100 * (30 - (controlled.lvl + 1) * 2)
  -- add randomness
  strength = strength + math.random(-strengthNoise, strengthNoise)
  if needMaxStrength == nil then
    strength = math.min(maxStrength, strength)
  end
  return strength
end

function doShoot(ball, controlled, opponent, time)

  if isShoting == true then return end
  local strength
  local count = 0
  local distance
  isShoting = true
  local function waitShoot()
    isWaitingShoot = false
    waitingShootTimer = nil
  end

  local function shootAfter(e)
    count = count + controlled.stats[1] * 2
    controlled:setCurrStrength(count)
    strength = getRequiredStrengthToShoot(controlled)
    if count >= strength then
      controlled:shoot()
      controlled:setCurrStrength(0)
      timer.cancel(shootAfterTimer)
      shootAfterTimer = nil
      isWaitingShoot = true
      isShoting = false
      waitingShootTimer = timer.performWithDelay(500, waitShoot)
    end
  end

    shootAfterTimer = timer.performWithDelay(1000 / 35, shootAfter, 0)
end

function doJump(ball, controlled, opponent, time)
  if controlled:canJump() == true and hadJump == false then
    hadJump = true
    controlled:jump()
    resetHadJumpTimer = timer.performWithDelay(200, resetHadJump)
  end
end

function doJumpAndShoot(ball, controlled, opponent, time)
  if isJumping(ball, controlled, opponent, time) == false then
    doJump(ball, controlled, opponent, time)
  end
  doShoot(ball, controlled, opponent, time)
end

function isBelowBall(ball, controlled, opponent, time)
  return ball:getPos().y + ball.diameter * 2 < controlled:getPos().y
end

function isBallXInsidePlayerX(ball, controlled, opponent, time)
  return ball:getPos().x >= controlled:getPos().x - controlled:getWidth() / 2 and
         ball:getPos().x <= controlled:getPos().x + controlled:getWidth() / 2
end

function isBelowLeftBasket(ball, controlled, opponent, time, lBasket, rBasket)
  local bPos = lBasket:getPos()
  local cPos = controlled:getPos()
  return (cPos.x + controlled:getWidth() / 2 > bPos.x - bPos.width / 2 and cPos.x + controlled:getWidth() / 2 < bPos.x + bPos.width / 2)
        or (cPos.x - controlled:getWidth() / 2 > bPos.x - bPos.width / 2 and cPos.x - controlled:getWidth() / 2 < bPos.x + bPos.width / 2)
end

function isBelowRightBasket(ball, controlled, opponent, time, lBasket, rBasket)
  local bPos = rBasket:getPos()
  local cPos = controlled:getPos()
  return (cPos.x + controlled:getWidth() / 2 > bPos.x - bPos.width / 2 and cPos.x + controlled:getWidth() / 2 < bPos.x + bPos.width / 2)
        or (cPos.x - controlled:getWidth() / 2 > bPos.x - bPos.width / 2 and cPos.x - controlled:getWidth() / 2 < bPos.x + bPos.width / 2)
end

function isOrientedToLeft(ball, controlled, opponent, time)
  return controlled:getOrientation() == "left"
end

function isOrientedToRight(ball, controlled, opponent, time)
  return controlled:getOrientation() == "right"
end

function doNothing(ball, controlled, opponent, time)
  controlled:setDefaultAnimation()
end

function randomChoice(ceil)

  local function innerRandomChoice(ball, controlled, opponent, time)
    return math.random() < ceil
  end

  return innerRandomChoice
end

function isJumpNeeded(ball, controlled, opponent, time)
  return opponent:getPos().y + opponent:getHeight() < controlled:getPos().y
end

function isGoForwardWorthThanJump(ball, controlled, opponent, time)
  local bPos = ball:getPos()
  local cPos = controlled:getPos()

  local distX = math.abs(bPos.x - cPos.x)
  local percent = (10 - randomness) * 10 * distX / 100

  return distX + percent  > (cPos.y - bPos.y)
end

function isDunkPossible(ball, controlled, opponent, time)
  if (randomness + 3) < math.random(1, 7) then return false end
  if controlled.baskets[1]:getOrientation() == "right" then
    return controlled:getPos().x > opponent:getPos().x
  else
    return controlled:getPos().x < opponent:getPos().x
  end
end

function doDunk(ball, controlled, opponent, time)
  controlled:dunk()
end

function isAtDunkRange(ball, controlled, opponent, time)
  return controlled.baskets[1]:playerCanDunk(controlled, 10)
end

function isLevelHigher(level)
  local function innerRandomChoice(ball, controlled, opponent, time)
    return level <= controlled.lvl
  end

  return innerRandomChoice
end

function isSomethingBefore(ball, controlled, opponent, time)
  local pos = controlled:getPos()
  local rayWidth = 5
  local targetX

  if controlled:getOrientation() == "left" then
    pos.x = pos.x + controlled:getWidth() / 2
    targetX = pos.x + rayWidth
  else
    pos.x = pos.x - controlled:getWidth() / 2
    targetX = pos.x - rayWidth
  end
  local hits = physics.rayCast(pos.x, pos.y, targetX, pos.y)

  if hits == nil then return false end
  for k, hit in ipairs(hits) do
    if hit.object.entity ~= controlled.container and hit.object.type ~= "Ball" then
      return true
    end
  end
  return false
end

function isRemainTime(ball, controlled, opponent, time)
  return time > 1 or (rules.isSuddentDeath == true and rules:getShootClockRemainTime() > 1)
end

function isWinning(ball, controlled, opponent, time)
  return controlled.score > opponent.score
end

function AI:initTree()
  local currentNode = self:createNode(isWake)

  currentNode.right = self:createNode(doWake)

  currentNode.left = self:createNode(isFree)

  currentNode.left.right = self:createNode(isOwningBall)

  currentNode.left.left = self:createNode(isFarerThanOpponent)
  currentNode.left.left.right = self:createNode(isNearBall)
  currentNode.left.left.right.left = self:createNode(doTake)
  currentNode.left.left.right.right = self:createNode(isOrientedToBall)
  currentNode.left.left.right.right.left = self:createNode(isBallXInsidePlayerX)
  currentNode.left.left.right.right.left.left = self:createNode(isJumping)
  currentNode.left.left.right.right.left.left.left = self:createNode(doGoForward)
  currentNode.left.left.right.right.left.left.right = self:createNode(doJump)
  currentNode.left.left.right.right.left.right = self:createNode(doGoForward)
  currentNode.left.left.right.right.right = self:createNode(doChangeOrientation)

  currentNode.left.left.left = self:createNode(isWinning)
  currentNode.left.left.left.left = self:createNode(isAtMid)
  currentNode.left.left.left.left.left = self:createNode(isOrientedToBall)
  currentNode.left.left.left.left.left.left = self:createNode(doNothing)
  currentNode.left.left.left.left.left.right = self:createNode(doChangeOrientation)
  currentNode.left.left.left.left.right = self:createNode(isOrientedToGoMid)
  currentNode.left.left.left.left.right.left = self:createNode(doGoForward)
  currentNode.left.left.left.left.right.right = self:createNode(doChangeOrientation)
  currentNode.left.left.left.right = self:createNode(isOrientedToBall)
  currentNode.left.left.left.right.left = self:createNode(doGoForward)
  currentNode.left.left.left.right.right = self:createNode(doChangeOrientation)

  currentNode.left.right.left = self:createNode(isRemainTime)
  currentNode.left.right.left.right = self:createNode(isOrientedToBasket)
  currentNode.left.right.left.right.left = self:createNode(doJumpAndShoot)
  currentNode.left.right.left.right.right = self:createNode(doChangeOrientation)

  currentNode.left.right.left.left = self:createNode(isOppBefore)
  currentNode.left.right.left.left.left = self:createNode(isAtDunkRange)
  currentNode.left.right.left.left.left.left = self:createNode(doDunk)
  currentNode.left.right.left.left.left.right = self:createNode(isLevelHigher(5))
  currentNode.left.right.left.left.left.right.left = self:createNode(isAtShootRange)
  currentNode.left.right.left.left.left.right.left.left = self:createNode(doJumpAndShoot)
  currentNode.left.right.left.left.left.right.left.right = self:createNode(doGoForward)
  currentNode.left.right.left.left.left.right.right = self:createNode(doJumpAndShoot)

  currentNode.left.right.left.left.right = self:createNode(isBelowLeftBasket)
  currentNode.left.right.left.left.right.left = self:createNode(isOrientedToLeft)
  currentNode.left.right.left.left.right.left.left = self:createNode(doGoForward)
  currentNode.left.right.left.left.right.left.right = self:createNode(doChangeOrientation)
  currentNode.left.right.left.left.right.right = self:createNode(isBelowRightBasket)
  currentNode.left.right.left.left.right.right.left = self:createNode(isOrientedToRight)
  currentNode.left.right.left.left.right.right.left.left = self:createNode(doGoForward)
  currentNode.left.right.left.left.right.right.left.right = self:createNode(doChangeOrientation)

  currentNode.left.right.left.left.right.right.right = self:createNode(isOrientedToBasket)
  currentNode.left.right.left.left.right.right.right.right = self:createNode(doChangeOrientation)
  currentNode.left.right.left.left.right.right.right.left = self:createNode(isDunkPossible)
  currentNode.left.right.left.left.right.right.right.left.left = self:createNode(isAtDunkRange)
  currentNode.left.right.left.left.right.right.right.left.left.left = self:createNode(doDunk)
  currentNode.left.right.left.left.right.right.right.left.left.right = self:createNode(doGoForward)
  currentNode.left.right.left.left.right.right.right.left.right = self:createNode(isAtDunkRange)
  currentNode.left.right.left.left.right.right.right.left.right.left = self:createNode(doDunk)


  currentNode.left.right.left.left.right.right.right.left.right.right = self:createNode(isLevelHigher(5))
  currentNode.left.right.left.left.right.right.right.left.right.right.left = self:createNode(isAtShootRange)
  currentNode.left.right.left.left.right.right.right.left.right.right.left.left = self:createNode(doJumpAndShoot)
  currentNode.left.right.left.left.right.right.right.left.right.right.left.right = self:createNode(doGoForward)
  currentNode.left.right.left.left.right.right.right.left.right.right.right = self:createNode(doJumpAndShoot)

  currentNode.left.right.right = self:createNode(isOrientedToOpp)
  currentNode.left.right.right.left = self:createNode(isAbleToTake)
  currentNode.left.right.right.right = self:createNode(doChangeOrientation)
  currentNode.left.right.right.left.left = self:createNode(doSteal)
  currentNode.left.right.right.left.right = self:createNode(isJumping)
  currentNode.left.right.right.left.right.left = self:createNode(doNothing)
  currentNode.left.right.right.left.right.right = self:createNode(isGoForwardWorthThanJump)
  currentNode.left.right.right.left.right.right.left = self:createNode(doGoForward)
  currentNode.left.right.right.left.right.right.right = self:createNode(doJump)

  tree = currentNode
end

function AI:takeDecision(ball, time, leftBasket, rightBasket)
  local function inner(node, b, c, o, t)
    local ret

    ret = node.fx(b, c, o, t, leftBasket, rightBasket)
    if ret == true and node.left ~= nil then
      inner(node.left, b, c, o, t)
    elseif ret == false and node.right ~= nil then
      inner(node.right, b, c, o, t)
    end
  end
  if isWaitingShoot == false and self.player.isDunking == false then
    inner(tree, ball, self.player, self.opp, time)
  end
end

function AI:onPause()
  if shootAfterTimer ~= nil then timer.pause(shootAfterTimer) end
  if waitingShootTimer ~= nil then timer.pause(waitingShootTimer) end
  if resetHadJumpTimer ~= nil then timer.pause(resetHadJumpTimer) end
end

function AI:onResume()
  if shootAfterTimer ~= nil then timer.resume(shootAfterTimer) end
  if waitingShootTimer ~= nil then timer.resume(waitingShootTimer) end
  if resetHadJumpTimer ~= nil then timer.resume(resetHadJumpTimer) end
end

function AI:destroy()
  if shootAfterTimer ~= nil then timer.cancel(shootAfterTimer) end
  if waitingShootTimer ~= nil then timer.cancel(waitingShootTimer) end
  if resetHadJumpTimer ~= nil then timer.cancel(resetHadJumpTimer) end

  isShoting = false
  isWaitingShoot = false
  isStealing = false
  hadJump = false
  shootAfterTimer = nil
  waitingShootTimer = nil
  resetHadJumpTimer = nil
  randomness = 0
end
