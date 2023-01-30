require "srcs.rendering.containers.BasketContainer"
require "srcs.entities.World"

Basket = {
  container = nil,
  owner = nil,
  shootSuccessListeners = nil,
  -- stillIn to known if ball's part still overlaying with basket's hitbox
  stillIn = false,
  wasIn = false
}

local world = World:new()
local rules = require("srcs.Rules")

function Basket:new(path, orientation)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self

  _self.container = BasketContainer:new(path, orientation)
  _self.shootSuccessListeners = {}
  return _self
end

function Basket:getOuterContainer()
  return self.container.outerContainer:getSprite()
end

function Basket:getInnerContainer()
  return self.container.innerContainer:getSprite()
end

function Basket:addToPhysics()
  self.container:addToPhysics()
end

function Basket:setOwner(o)
  self.owner = o
  o:setBasket(self)
end

function Basket:isInRectX(rect, x)
  return rect.x <= x and rect.x + rect.width > x
end

function Basket:isInRectY(rect, y)
  return rect.y <= y and rect.y + rect.height > y
end

function Basket:checkBasket(ball)
  local rect = self.container:getBasketBoudingRect()
  local bCoords = ball:getCenter()
  local points

  if rules.matchOver == true or ball.fromBelow == true then return end
  if ball:getContainer().getLinearVelocity == nil then return end
  if ball.shootPos.x >= rect.x and ball.shootPos.x <= rect.x + rect.width and ball.origin ~= "DUNK" then return end

  if self:isInRectX(rect, bCoords.x - ball.diameter / 2) and self:isInRectX(rect, bCoords.x + ball.diameter / 2) and
     self:isInRectY(rect, bCoords.y - ball.diameter / 2) and self:isInRectY(rect, bCoords.y + ball.diameter / 2)
    then
        if self.owner ~= nil then
          if self.wasIn == false and self.stillIn == false then
            self.wasIn = true
            self.stillIn = true
            local vx, vy = ball.container:getLinearVelocity()
            if vy > 0 then
              points = rules:getPoints(self.container.orientation, ball.shootPos.x, ball.origin)
              self.owner:incrScore(points)
              self:notifyShootSuccess(ball.origin, points)
            else
              ball.fromBelow = true
            end
          end
        end
  elseif (self:isInRectX(rect, bCoords.x - ball.diameter / 2) or self:isInRectX(rect, bCoords.x + ball.diameter / 2)) and
     (self:isInRectY(rect, bCoords.y - ball.diameter / 2) or self:isInRectY(rect, bCoords.y + ball.diameter / 2)) and self.wasIn == true
  then
    self.stillIn = true
  else
    self.wasIn = false
    self.stillIn = false
  end
end

function Basket:subscribeShootSuccess(obj)
  self.shootSuccessListeners[table.getn(self.shootSuccessListeners) + 1] = obj
end

function Basket:notifyShootSuccess(origin, points)
  for key, obj in ipairs(self.shootSuccessListeners) do
    obj:onShootSuccess(self.owner, origin, points)
  end
end

function Basket:destroy()
  self.container:destroy()
  self.container = nil
end

function Basket:getPostGlobalWidth()
  return self.container:getPostGlobalWidth()
end

function Basket:getPos()
  return self.container:getPos()
end

function Basket:getOrientation()
  return self.container.orientation
end

function Basket:playerCanDunk(player, ceil)
  local bPos = self:getPos()
  local pPos = player:getPos()

  if ceil == nil then ceil = 20 end
  ceil = ceil + ceil * (player:getStatsConst()[5] * 20) / 100
  if self:getOrientation() == "left" then
    return player:getOrientation() == "right" and player.ball ~= nil and bPos.x + bPos.width / 2 < pPos.x - player:getWidth() / 2
    and bPos.x + bPos.width / 2 + ceil > pPos.x - player:getWidth() / 2
  else
    return player:getOrientation() == "left" and player.ball ~= nil and bPos.x - bPos.width / 2 > pPos.x + player:getWidth() / 2
    and bPos.x - bPos.width / 2 - ceil < pPos.x + player:getWidth() / 2
  end
end
function Basket:insertTopNetToContainer(c)
  self.container:insertTopNetToContainer(c)
end

function Basket:insertBotNetToContainer(c)
  self.container:insertBotNetToContainer(c)
end

function Basket:resetShoot()
  self.wasIn = false
  self.stillIn = false
end

function Basket:setVisibility(value)
  self.container:setVisibility(value)
end

function Basket:weldPlayer(player)
end
