require "srcs.rendering.Render"
local widget = require "widget"
local assets = require "srcs.Assets"

Selector = {
  rayon = nil,
  coeff = nil,
  idx = 1,
  deg = 0,
  nodes = nil,
  botArrow = nil,
  topArrow = nil,
  rotaBtn = 20,
  nameContainer = nil,
  unlockBtn = nil,
  subGroup = nil,
  globalGroup = nil
}

function Selector:new(sceneGroup, player, pictures, onChange, onUnlock, orientation, collection)
  local _self = {}

  setmetatable(_self, self)
  _self.nodes = {}
  self.__index = self

  _self:createSelector(sceneGroup, player, pictures, onChange, onUnlock, orientation, collection)
  return _self
end

function Selector:createSelector(sceneGroup, player, pictures, onChange, onUnlock, orientation, collection)
  local tranCoeff
  local tranValue = 1.2
  local hasEnd = true

  local function scaleHead()
    transition.to(self.nodes[self.idx].head,{
      xScale = tranValue,
      yScale = tranValue,
      time = 100,
      onComplete = function()
        hasEnd = true
      end,
      onCancel = function()
        hasEnd = true
      end
    })
  end

  local function nextChar()
    if hasEnd == false then return end
    hasEnd = false
    self.nodes[self.idx].head.xScale = 1
    self.nodes[self.idx].head.yScale = 1
    self.idx = self.idx + 1
    if self.idx == table.getn(pictures) + 1 then self.idx = 1 end
    self.nameContainer:setLabel(pictures[self.idx].name:gsub("^%l", string.upper))
    if pictures[self.idx].isUnlocked == true then
      onChange(player, pictures[self.idx], true)
      player:insertToContainer(sceneGroup)
      self.unlockBtn.isVisible = false
    else
      onChange(player, pictures[self.idx], false)
      self.unlockBtn.isVisible = true
    end
    transition.to(self.subGroup, {
      rotation = self.subGroup.rotation - tranCoeff,
      time = 100,
      onComplete=scaleHead
    })
  end

  local function prevChar()
    if hasEnd == false then return end
    hasEnd = false
    self.nodes[self.idx].head.xScale = 1
    self.nodes[self.idx].head.yScale = 1
    self.idx = (self.idx - 1) % table.getn(pictures)
    if self.idx <= 0 then self.idx = table.getn(pictures) end
    self.nameContainer:setLabel(pictures[self.idx].name:gsub("^%l", string.upper))
    if pictures[self.idx].isUnlocked == true then
      onChange(player, pictures[self.idx], true)
      player:insertToContainer(sceneGroup)
      self.unlockBtn.isVisible = false
    else
      onChange(player, pictures[self.idx], false)
      self.unlockBtn.isVisible = true
    end
    transition.to(self.subGroup, {
      rotation = self.subGroup.rotation + tranCoeff,
      time = 100,
      onComplete=scaleHead
    })
  end

  local function unlock()
    onUnlock(e, player, pictures[self.idx], self.idx, self.unlockBtn)
  end


  self.rayon = sceneGroup.width / 2
  self.coeff = 360 / table.getn(pictures)
  self.globalGroup = display.newGroup()
  self.subGroup = display.newContainer(sceneGroup, self.rayon * 3, sceneGroup.height * 3)
  self.nameContainer = widget.newButton{
    defaultFile="img/uis/name-ui.png",
    width = display.actualContentWidth / 7,
    height = display.actualContentHeight / 10,
    labelColor = { default={Colors:getColor("red")}},
    label = "",
    font = native.newFont("font/GROBOLD")
  }
  self.unlockBtn = Render:basicButton("img/uis/unlock-button", unlock, 30, 32)
  tranCoeff = self.coeff

  self.botArrow = Render:basicButton("img/uis/arrow-bot-marged", nextChar, sceneGroup.height / 6, sceneGroup.height / 5.8, "swing")
  self.botArrow.y = sceneGroup.height / 4

  self.topArrow = Render:basicButton("img/uis/arrow-top-marged", prevChar, sceneGroup.height / 6, sceneGroup.height / 5.8, "swing")
  self.topArrow.y = -sceneGroup.height / 4

  self.nameContainer.y = sceneGroup.height / 8
  self.nameContainer.x = 30
  self.nameContainer:setLabel(pictures[1].name:gsub("^%l", string.upper))

  self.unlockBtn.y = self.nameContainer.y

  if orientation == "right" then
    self.subGroup.x = sceneGroup.width / 1.2
    self.subGroup.xScale = -1
    self.topArrow.x = self.subGroup.x - self.rayon
    self.botArrow.x = self.subGroup.x - self.rayon
    self.nameContainer.x = self.subGroup.x - self.rayon - 8
    self.unlockBtn.x = self.nameContainer.x - self.nameContainer.width / 2
    tranCoeff = -tranCoeff
    self.botArrow.rotation = -self.rotaBtn
    self.topArrow.rotation = self.rotaBtn
  else
    self.subGroup.x = -sceneGroup.width / 1.2
    self.botArrow.x = self.subGroup.x + self.rayon
    self.topArrow.x = self.subGroup.x + self.rayon
    self.nameContainer.x = self.subGroup.x + self.rayon + 8
    self.unlockBtn.x = self.nameContainer.x + self.nameContainer.width / 2
    self.botArrow.rotation = self.rotaBtn
    self.topArrow.rotation = -self.rotaBtn
  end

  local i
  for i = 1, table.getn(pictures) do
    local tmp = i
    self.nodes[i] = {}
    self.nodes[i].img = display.newImageRect(assets:asBig(pictures[i].name, collection), sceneGroup.height / 4.5, sceneGroup.height / 4.5)
    self.nodes[i].head = Render:charUi(self.nodes[i].img, sceneGroup.height / 3, sceneGroup.height / 4.1)

    self.nodes[i].head.x = math.cos(math.rad(self.deg)) * self.rayon
    self.nodes[i].head.y = math.sin(math.rad(self.deg)) * self.rayon
    self.nodes[i].head.rotation = self.deg
    self.subGroup:insert(self.nodes[i].head)
    if pictures[i].isUnlocked ~= true then
      Render:unlockEffect(self.nodes[i].img)
    end
    self.deg = self.deg + self.coeff
  end
  self.nodes[1].head.xScale = tranValue
  self.nodes[1].head.yScale = tranValue
  if pictures[1].isUnlocked == true then
    self.unlockBtn.isVisible = false
  end

  self.globalGroup:insert(self.subGroup)
  self.globalGroup:insert(self.botArrow)
  self.globalGroup:insert(self.topArrow)
  self.globalGroup:insert(self.nameContainer)
  self.globalGroup:insert(self.unlockBtn)
end

function Selector:getContainer()
  return self.globalGroup
end

function Selector:destroy()
  for key, value in pairs(self.nodes) do
    value.head:removeSelf()
    value.head = nil
    value.img:removeSelf()
    value.img = nil
  end
  self.nodes = nil

  self.topArrow:removeSelf()
  self.topArrow = nil

  self.botArrow:removeSelf()
  self.botArrow = nil

  self.nameContainer:removeSelf()
  self.nameContainer = nil

  self.unlockBtn:removeSelf()
  self.unlockBtn = nil

  self.subGroup:removeSelf()
  self.subGroup = nil

  self.globalGroup:removeSelf()
  self.globalGroup = nil
end
