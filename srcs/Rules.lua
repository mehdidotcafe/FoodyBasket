require "srcs.entities.World"
require "srcs.Timer"

local rules = {
  shootClock = nil,
  matchTimer = nil,
  currPlayer = nil,
  isOver = false,
  matchOver = false,
  needShootClock = true,
  isSuddentDeath = false,
  endShootClockListeners = {},
  changeShootClockListeners = {}
}

local world = World:new()

function rules:getPoints(basketOri, ballX, ballOri)
  if self.matchOver == true then return 0 end
  if ballOri == "DUNK" then return 3
  elseif basketOri == "left" then
    if ballX > world.axis.center.x then
      return 3
    else
      return 2
    end
  else
    if ballX < world.axis.center.x then
      return 3
    else
      return 2
    end
  end
end

function rules:startShootClock(player)
  local delay = 8

  if self.needShootClock ~= true then return end
  if self.matchOver == true then return end
  if self.shootClock ~= nil then
    self.shootClock:destroy()
  end
  self.shootClock = Timer:new(delay)
  self.shootClock:subscribeEndTime(self)
  self.shootClock:subscribeTimeChange(self)
  self.currPlayer = player
  self.shootClock:startTime()
end

function rules:initMatchTimer(container, delay)
  if delay == nil then delay = 60 end
  if self.matchTimer ~= nil then
    self.matchTimer:destroy()
  end
  self.matchTimer = Timer:new(delay, container)
end

function rules:startMatchTimer()
  self.matchTimer:startTime()
end

function rules:subscribeEndMatch(obj)
  self.matchTimer:subscribeEndTime(obj)
end

function rules:pauseShootClock()
  if self.shootClock ~= nil then
    self.shootClock:pause()
  end
end

function rules:clearShootClock()
  if self.shootClock ~= nil then
    self.shootClock:cancel()
    self.shootClock = nil
  end
  self.currPlayer = nil
end

function rules:pauseMatchTimer()
  if self.matchTimer ~= nil then
    self.matchTimer:pause()
  end
end

function rules:resumeShootClock()
  if self.shootClock ~= nil then
    self.shootClock:resume()
  end
end

function rules:resumeMatchTimer()
  if self.matchTimer ~= nil then
    self.matchTimer:resume()
  end
end

function rules:subscribeShootClockEnd(obj)
  self.endShootClockListeners[table.getn(self.endShootClockListeners) + 1] = obj
end

function rules:subscribeShootClockChange(obj)
  self.changeShootClockListeners[table.getn(self.changeShootClockListeners) + 1] = obj
end

function rules:notifyShootClockEnd()
  for key, obj in ipairs(self.endShootClockListeners) do
    obj:onEndShootClock(self.currPlayer)
  end
  self.currPlayer = nil
end

function rules:getShootClockRemainTime()
  if self.shootClock ~= nil and self.needShootClock == true then
    return self.shootClock.lim - self.shootClock.currentTime
  else
    return -1
  end
end

function rules:getMatchClockRemainTime()
  if self.matchTimer ~= nil then
    return self.matchTimer.lim - self.matchTimer.currentTime
  else
    return -1
  end
end

function rules:onEndTime()
  if self.ball.owner ~= nil or self.ball.unresolvedCollideCount ~= 0 then
    self:notifyShootClockEnd()
  else
    self.isOver = true
  end
end

function rules:onTimeChange(remainTime)
  for key, obj in ipairs(self.changeShootClockListeners) do
    obj:onShootClockChange(remainTime)
  end
end

function rules:destroy()
  if self.shootClock ~= nil then
    self.shootClock:destroy()
    self.shootClock = nil
  end
  if self.matchTimer ~= nil then
    self.matchTimer:destroy()
    self.matchTimer = nil
  end
  self.endShootClockListeners = {}
  self.changeShootClockListeners = {}
  self.matchOver = false
  self.needShootClock = true
  self.isSuddentDeath = false
end

function rules:onBallCollide(event)
  if event == nil then return end
  local type = event.other.type

  if self.isOver == true and self.matchOver == false then
    if type == "Player" or type == "World" then
      self:notifyShootClockEnd()
      self.isOver = false
    end
  end
end

function rules:overMatch()
  self:pauseClocks()
  self.matchOver = true
end

function rules:pauseClocks()
  if self.shootClock ~= nil then
    self.shootClock:pause()
  end
end

return rules
