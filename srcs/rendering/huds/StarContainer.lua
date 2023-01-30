require "srcs.rendering.Render"

StarContainer = {
  stars = nil,
  leftArrow = nil,
  readOnly = true,
  rightArrow = nil,
  onClick = nil,
  container = nil,
  starSide = 0,
  margin = 0,
  width = 0,
  index = 0
}

function StarContainer:new(width, starsNb, index, onClick, readOnly)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.stars = {}
  if readOnly ~= nil then _self.readOnly = readOnly end
  _self.onClick = onClick
  _self.index = index
  _self.width = width
  _self:init(width, starsNb)
  return _self
end

function StarContainer:setIndex(idx)
  self.index = idx
  self:deleteStars()
  self:createStars()
end

function StarContainer:init(width, starsNb)
  self.starSide = width / 7
  self.margin = self.starSide / 10
  self.starSide = 8 * self.starSide / 10
  self.leftArrow = Render:basicButton("img/uis/arrow-left", function()
    if self.index > 1 then
      self.onClick("left", self.index)
      self.index = self.index - 1
      self:deleteStars()
      self:createStars()
    end
  end, self.starSide * 2, self.starSide * 2)
  self.rightArrow = Render:basicButton("img/uis/arrow-right", function()
    if self.index < starsNb then
      self.onClick("right", self.index)
      self.index = self.index + 1
      self:deleteStars()
      self:createStars()
    end
  end, self.starSide * 2, self.starSide * 2)
  if self.readOnly == true then
    self.leftArrow.isVisible = false
    self.rightArrow.isVisible = false
  end
  self.container = display.newContainer(width + width / 4, self.starSide * 2.5)
  self.leftArrow.x = -self.container.width / 2 + self.rightArrow.width / 2
  self.rightArrow.x = self.container.width / 2 - self.rightArrow.width / 1.5
  self.leftArrow.y = self.leftArrow.height / 20
  self.rightArrow.y = self.rightArrow.height / 20
  self.container:insert(self.leftArrow)
  self.container:insert(self.rightArrow)
  self:createStars()
end

function StarContainer:setPos(pos)
  self.container.x = pos.x
  self.container.y = pos.y
end

function StarContainer:createStars()
  local startX = self.leftArrow.x + self.leftArrow.width / 2 + self.margin * 2

  for i = 0, math.floor(self.index / 2) - 1 do
    star = display.newImageRect("img/uis/star.png", self.starSide, self.starSide)
    star.y = 0
    star.x = startX + i * (self.starSide + self.margin * 2) + self.starSide / 2
    self.stars[#self.stars + 1] = star
    self.container:insert(star)
  end
  if self.index % 2 == 1 then
    star = display.newImageRect("img/uis/star-half.png", self.starSide / 2, self.starSide)
    star.y = 0
    star.x = startX + #self.stars * (self.starSide + self.margin * 2) + self.starSide / 4
    self.stars[#self.stars + 1] = star
    self.container:insert(star)
  end
end

function StarContainer:deleteStars()
  for i = 1, #self.stars do
    self.stars[i]:removeSelf()
    self.stars[i] = nil
  end
end

function StarContainer:insertTo(container)
  container:insert(self.container)
end

function StarContainer:destroy()
  self:deleteStars()
  self.leftArrow:removeSelf()
  self.rightArrow:removeSelf()

  self.leftArrow = nil
  self.rightArrow = nil
  self.stars = nil
end
