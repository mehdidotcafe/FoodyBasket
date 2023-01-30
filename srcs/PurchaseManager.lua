local sm = require("srcs.sound.SoundManager")

require"srcs.Store"
require "srcs.db.DB"

local s = require("srcs.Store")

PurchaseManager = {
  db = nil,
  assets = require "srcs.Assets",
  unlockedChars = {},
  buyablePoints = {
    {
    points = 10000,
    id = "1"
    },
    {
      points = 30000,
      id = "2"
    },
    {
      points = 100000,
      id = "3"
    },
    {
      points = 200000,
      id = "4"
    },
    {
      points = 500000,
      id = "5"
    }
  },
  points = 0
}

function PurchaseManager:getCharFromName(char)
  for key, obj in ipairs(self.assets.chars) do
    if obj.name == char.name then
      return obj
    end
  end
  return nil
end

function PurchaseManager:getShoesFromName(shoes)
  for key, obj in ipairs(self.assets.shoes) do
    if obj.name == shoes.name then
      return obj
    end
  end
  return nil
end

function PurchaseManager:getHandsFromName(hands)
  for key, obj in ipairs(self.assets.hands) do
    if obj.name == hands.name then
      return obj
    end
  end
  return nil
end

function PurchaseManager:init()
  local it
  self.db = DB:new()

  self.points = self.db:getPoints()
  if self.points == -1 then
    self.db:createPoints(0)
  end
  it = self.db:getUnlockedCollection("chars", function(char)
    if self:getCharFromName(char) ~= nil then
      self:getCharFromName(char).isUnlocked = true
    end
  end)
  if it == 0 then
    self.db:unlockChar(self.assets.chars[1].name)
    self.db:unlockChar(self.assets.chars[2].name)
    self.assets.chars[1].isUnlocked = true
    self.assets.chars[2].isUnlocked = true
  end
  it = self.db:getUnlockedCollection("shoes", function(char)
    self:getShoesFromName(char).isUnlocked = true
  end)
  if it == 0 then
    self.db:unlockShoes(self.assets.shoes[1].name)
    self.db:unlockShoes(self.assets.shoes[2].name)
    self.assets.shoes[1].isUnlocked = true
    self.assets.shoes[2].isUnlocked = true
  end
  it = self.db:getUnlockedCollection("hands", function(hand)
    self:getHandsFromName(hand).isUnlocked = true
  end)
  if it == 0 then
    self.db:unlockHands(self.assets.hands[1].name)
    self.assets.hands[1].isUnlocked = true
  end
end

function PurchaseManager:incrScore(add)
  self.points = self.points + add
  self.db:setPoints(self.points)
end

function PurchaseManager:unlockChar(char, fx)
  if self.points >= char.price then
    self:incrScore(-char.price)
    self.db:unlockChar(char.name)
    self:getCharFromName(char).isUnlocked = false
    fx("complete")
  else
    fx("not-enough-points")
  end
end

function PurchaseManager:unlockShoes(shoes, fx)
  if self.points >= shoes.price then
    self:incrScore(-shoes.price)
    self.db:unlockShoes(shoes.name)
    self:getShoesFromName(shoes).isUnlocked = false
    fx("complete")
  else
    fx("not-enough-points")
  end
end

function PurchaseManager:unlockHands(hands, fx)
  if self.points >= hands.price then
    self:incrScore(-hands.price)
    self.db:unlockHands(hands.name)
    self:getHandsFromName(hands).isUnlocked = false
    fx("complete")
  else
    fx("not-enough-points")
  end
end

function PurchaseManager:onBuyClick(obj, cb)

  local function innerCb(state)
    if state == "purchased" then
      self:incrScore(obj.points)
      sm:play("buy")
      s:consume(obj.id)
    end
    cb(state)
  end
  s:purchase(obj.id, innerCb)
end

return PurchaseManager
