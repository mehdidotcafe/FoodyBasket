require "srcs.rendering.SpriteSheetManager"
require "srcs.rendering.Render"
require "srcs.entities.World"
local sm = require "srcs.sound.SoundManager"
local width = math.floor(70 / 1.2)
local height = math.floor(99 / 1.2)

local BASKET_DIMS = {
  panel = {
    x = 0,
    width = width / 5.8,
    height = height
  },
  basket = {
    x = 0,
    width = 1,
    trueWidth = width / 1.32,
    y = height  / 1.23,
    height = height / 19.8
  },
  net = {
    height = height / 3.7,
    width = width / 10
  }
}

BasketContainer = {
  outerContainer = nil,
  innerContainer = nil,
  panel = nil,
  basket = nil,
  post = nil,
  pos = nil,
  orientation = nil,

  topLinks = nil,
  topJoints = nil,
  topRim = nil,

  botLinks = nil,
  botJoints = nil,
  botRim = nil
}

local masks = require("srcs.entities.physics.entitiesMask")

local world = World:new()

  function BasketContainer:new(path, orientation)
  local _self = {}
  _self.pos = {
    y = world.axis.bot.y - 175 - height / 2,
    x = 0
  }
  local INFOS = {
    numFrames = 2,
    sequences = {
      {name="outer", start=1, count=1},
      {name="inner", start=2, count=1}
    }
  }
  local path = "assets/baskets/basicnew.png"
  local limit = display.actualContentWidth

  setmetatable(_self, self)
  self.__index = self

  _self.topLinks = {}
  _self.botLinks = {}
  _self.topJoints = {}
  _self.botJoints = {}
  _self.topRim = display.newRect( 0, display.screenOriginY + _self.pos.y, BASKET_DIMS.basket.trueWidth, 5)
  _self.botRim = display.newRect( 0, display.screenOriginY + _self.pos.y, BASKET_DIMS.basket.trueWidth, 5)
  if orientation == "left" then
    _self.pos.x = world.axis.left.x + width / 2
    _self.basket = Render.createContainer(BASKET_DIMS.basket.width, BASKET_DIMS.basket.height + 5, BASKET_DIMS.basket.x + BASKET_DIMS.basket.trueWidth + BASKET_DIMS.panel.width - BASKET_DIMS.basket.width, 0)
    _self.panel = Render.createContainer(BASKET_DIMS.panel.width + 2, BASKET_DIMS.panel.height, BASKET_DIMS.panel.x, _self.pos.y - BASKET_DIMS.panel.height / 2)
    _self.panel.rotation = 2
    _self.topRim.x = _self.basket.x - BASKET_DIMS.basket.trueWidth / 2
    _self.botRim.x = _self.basket.x - BASKET_DIMS.basket.trueWidth / 2
  elseif orientation == "right" then
    _self.pos.x = world.axis.right.x - width / 2
    _self.basket = Render.createContainer(BASKET_DIMS.basket.width, BASKET_DIMS.basket.height + 5, limit - BASKET_DIMS.basket.trueWidth - BASKET_DIMS.basket.x - BASKET_DIMS.panel.width, 0)
    _self.panel = Render.createContainer(BASKET_DIMS.panel.width + 2, BASKET_DIMS.panel.height, limit - BASKET_DIMS.panel.width - BASKET_DIMS.panel.x - 2, _self.pos.y - BASKET_DIMS.panel.height / 2)
    _self.topRim.x = _self.basket.x + BASKET_DIMS.basket.trueWidth / 2
    _self.botRim.x = _self.basket.x + BASKET_DIMS.basket.trueWidth / 2
    _self.panel.rotation = -2
  end
  _self.outerContainer = SpriteSheetManager:new(width, height, _self.pos.x, display.screenOriginY + _self.pos.y + 5, INFOS, nil)
  _self.innerContainer = SpriteSheetManager:new(width, height, _self.pos.x, display.screenOriginY + _self.pos.y + 5, INFOS, nil)

  _self.outerContainer:setPath(path)
  _self.outerContainer:setOrientation(orientation, "disable")
  _self.outerContainer:setAnimation("outer")

  _self.innerContainer:setPath(path)
  _self.innerContainer:setOrientation(orientation, "disable")
  _self.innerContainer:setAnimation("inner")

  _self.orientation = orientation

  _self.topRim.y = display.screenOriginY + _self.pos.y + BASKET_DIMS.basket.y / 2.6 + 2
  _self.basket.y = _self.topRim.y - _self.topRim.height / 2
  _self.botRim.y = display.screenOriginY + _self.pos.y + BASKET_DIMS.basket.y / 2.6 + 15
  _self.topRim.isVisible = false
  _self.botRim.isVisible = false

  _self.panel.collision = function(container, e)
    local ceil = 75
    local vx, vy = e.other:getLinearVelocity()

    if e.phase == "began" and (math.abs(vx) > ceil or math.abs(vy) > ceil) and sm:isPlaying("board") ~= true then sm:play("board") end
  end
  _self.panel:addEventListener("collision")


  return _self
end

function BasketContainer:addToPhysics()
  local type = "static"
  local masks = require("srcs.entities.physics.entitiesMask")
  local params = {friction=0.9, bounce=0.6, filter=masks["basket"]}

  self.basket.type = "Basket"
  self.panel.type = "Basket"

  physics.addBody(self.basket, type, params)
  physics.addBody(self.panel, type, params)
  self:addNetToPhysics()
end

function BasketContainer:getBasketBoudingRect()
  local rect = {
    y = self.topRim.y - self.topRim.height / 2,
    width = self.botRim.width + self.panel.width,
    height = self.botRim.height + BASKET_DIMS.net.height + (self.botRim.y - self.topRim.y)
  }

  if self.orientation == "left" then rect.x = display.screenOriginX else
    rect.x = display.screenOriginX + display.actualContentWidth - rect.width end
  return rect
end

function BasketContainer:removeNetFromPhysics(links, joints, rim)
  for key, obj in ipairs(joints) do
    obj:removeSelf()
  end
  for key, obj in ipairs(links) do
    physics.removeBody(obj)
    obj:removeSelf()
  end
  physics.removeBody(rim)
  rim:removeSelf()
  links = nil
  joints = nil
  rim = nil
end

function BasketContainer:destroy()
  self:removeNetFromPhysics(self.topLinks, self.topJoints, self.topRim)
  self:removeNetFromPhysics(self.botLinks, self.botJoints, self.botRim)
  physics.removeBody(self.basket)
  physics.removeBody(self.panel)
  self.basket:removeSelf()
  self.basket = nil
  self.panel:removeSelf()
  self.panel = nil
  self.outerContainer = nil
  self.innerContainer = nil
end

function BasketContainer:getPos()
  return {
    width = BASKET_DIMS.basket.trueWidth,
    height = BASKET_DIMS.basket.height,
    x= self.pos.x,
    y= self.pos.y
  }
end

function BasketContainer:insertNetToContainer(c, rim, links)
  c:insert(rim)

  for i = 1,10 do
    links[i] = display.newImageRect("img/rope.png", BASKET_DIMS.net.width, BASKET_DIMS.net.height)
    c:insert(links[i])
    links[i].isVisible = false
  end
end

function BasketContainer:setVisibility(value)
  for i =1, #self.topLinks do
    self.topLinks[i].isVisible = value
  end
  for i =1, #self.botLinks do
    self.botLinks[i].isVisible = value
  end
end

function BasketContainer:insertTopNetToContainer(c)
  self:insertNetToContainer(c, self.topRim, self.topLinks)
end

function BasketContainer:insertBotNetToContainer(c)
  self:insertNetToContainer(c, self.botRim, self.botLinks)
end

function BasketContainer:createLinks(links, rim, joints, coeff, decY, decX, origin)
  local x = rim.x - rim.width / 2
  local y = rim.y + rim.height / 2
  local offsetsY = {3 * coeff, 0 * coeff, 1 * coeff , -1 * coeff, -1 * coeff, -1 * coeff, -1 * coeff, 1 * coeff, 1 * coeff, 3 * coeff}
  local joint
  local rotaValue = 20

  local function onCollision(container, e)
    if e.phase == "began" and sm:isPlaying("swish") ~= true then sm:play("swish") end
  end

  physics.addBody(rim, "static", { friction=0.5, filter=masks["basketNet"]} )
  rim.isSensor = true

  links[1].x = x + decX + links[1].width / 2 + 3
  links[1].rotation = -rotaValue / 1.5
  links[2].x = x + rim.width / 6 + decX + links[1].width / 2 - 2
  -- links[2].rotation = -10
  links[3].x = x + rim.width / 6 + decX + links[1].width / 2
  links[3].rotation = -rotaValue
  links[4].x = x + 2 * rim.width / 6 + decX + links[1].width / 2
  links[4].rotation = rotaValue
  links[5].x = x + 2 * rim.width / 6 + decX + links[1].width / 2
  links[5].rotation = -rotaValue
  links[6].x = x + 3 * rim.width / 6 + decX + links[1].width / 2
  links[6].rotation = rotaValue
  links[7].x = x + 3 * rim.width / 6 + decX + links[1].width / 2
  links[7].rotation = -rotaValue
  links[8].x = x + 4 * rim.width / 6 + decX + links[1].width / 2
  links[8].rotation = rotaValue
  links[9].x = x + 4 * rim.width / 6 + decX + links[1].width / 2 + 1
  -- links[9].rotation = 10
  links[10].x = x + 5 * rim.width / 6 + decX + links[1].width / 2 - 2
  links[10].rotation = rotaValue / 1.5
  for i = 1,10 do
    links[i].collision = onCollision
    links[i]:addEventListener("collision")
    joint = nil
			links[i].y = y + offsetsY[i] + links[i].height / 2 - rim.height / 2 + decY

      physics.addBody(links[i], { density=0.1, friction=0, bounce=1, filter= ((i == 1 or i == 10) and origin == "bot") and masks["basketNetLim"] or  masks["basketNet"]} )
			joints[#joints + 1] = physics.newJoint( "pivot", rim, links[i], links[i].x, links[i].y - links[i].height / 2)
      if i % 2 == 0 and i > 2 then
        joints[#joints + 1] = physics.newJoint( "weld", links[i - 3], links[i], links[i].x, links[i].y + links[i].height / 2)
        joint = joints[#joints]
      elseif i == 2 or i == 9 then
        joints[#joints + 1] = physics.newJoint( "weld", links[i], links[i - 1], links[i].x, links[i].y + links[i].height / 2)
        joint = joints[#joints]
      end
      if joint ~= nil then
        joint.dampingValue = 1
        joint.frequency = 0.1
      end
	end
  joints[#joints + 1] = physics.newJoint( "weld", links[2], links[3], (links[2].x + links[3].x) / 2, links[2].y)
  joints[#joints + 1] = physics.newJoint( "weld", links[4], links[5], (links[4].x + links[5].x) / 2, links[4].y)
  joints[#joints + 1] = physics.newJoint( "weld", links[6], links[7], (links[6].x + links[7].x) / 2, links[6].y)
  joints[#joints + 1] = physics.newJoint( "weld", links[8], links[9], (links[8].x + links[9].x) / 2, links[8].y)
end

function BasketContainer:addNetToPhysics()
  self:createLinks(self.topLinks, self.topRim, self.topJoints, 1, -6.5, 0, "top")
  self:createLinks(self.botLinks, self.botRim, self.botJoints, -1, -10, 1, "bot")
  self.topJoints[#self.topJoints + 1] = physics.newJoint( "weld", self.topLinks[1], self.botLinks[1], self.botLinks[1].x - 20, self.botLinks[1].y)
  self.topJoints[#self.topJoints + 1] = physics.newJoint( "weld", self.topLinks[10], self.botLinks[10], self.botLinks[10].x + 20, self.botLinks[10].y)
end
