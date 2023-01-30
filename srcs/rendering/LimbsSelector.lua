LimbsSelector = {
  player = nil,
  currentOption = "",
  limbs = {
    bodies = {
      index = 1,
      length = 0,
      paths = {"assets/bodies/basic.png", "assets/bodies/basic1.png", "assets/bodies/basic2.png"}
    },
    shoes = {
      index = 1,
      length = 0,
      paths = {"assets/shoes/basic.png", "assets/shoes/basic1.png", "assets/shoes/basic2.png"}
    }
  },
  sceneGroup = nil
}

function LimbsSelector:new()
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.currentOption = "shoes"
  for i, v in ipairs(_self.limbs.bodies.paths) do
    _self.limbs.bodies.length = i
  end
  for i, v in ipairs(_self.limbs.shoes.paths) do
    _self.limbs.shoes.length = i
  end
  return _self
end

function LimbsSelector:onBodyClick()
  self.currentOption = "bodies"
end

function LimbsSelector:onShoesClick()
  self.currentOption = "shoes"
end

function LimbsSelector:getOppositeOri(player)
  local ori = player:getOrientation()

  if ori == "left" then
    ori = "right"
  else
    ori = "left"
  end
  return ori
end

function LimbsSelector:onArrowRight(group)
  local limb = self.limbs[self.currentOption]
  local ori = self:getOppositeOri(self.player)

  limb.index = limb.index + 1
  if limb.index > limb.length then
    limb.index = 1
  end
  if self.currentOption == "bodies" then
    self.player:setBody(limb.paths[limb.index], ori)
  elseif self.currentOption == "shoes" then
    self.player:setShoes(limb.paths[limb.index], ori)
  end
  self.player:insertToContainer(group)
end

function LimbsSelector:onArrowLeft(group)
  local limb = self.limbs[self.currentOption]
  local ori = self:getOppositeOri(self.player)
  local length = 0

  limb.index = limb.index - 1
  if limb.index < 1 then
    limb.index = limb.length
  end
  if self.currentOption == "bodies" then
    self.player:setBody(limb.paths[limb.index], ori)
  elseif self.currentOption == "shoes" then
    self.player:setShoes(limb.paths[limb.index], ori)
  end
  self.player:insertToContainer(group)
end

function LimbsSelector:setPlayer(p)
  self.player = p
end
