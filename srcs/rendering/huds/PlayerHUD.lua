require "srcs.rendering.huds.ProgressBar"

local widget = require( "widget" )
local assets = require "srcs.Assets"
require "srcs.rendering.Colors"


PlayerHUD = {
  player = nil,
  headImg = nil,
  scoreTxt = nil,
  container = nil,
  botContainer = nil,
  supContainer = nil,
  strengthContainer = nil,
  dunkImg = nil,
  score = nil
}

function PlayerHUD:new(width, height, x, marginY, player, pos, needPb)
  local _self = {}

  local headPosX = x - width / 2

  local subHeight = 20
  local container = display.newContainer(width + subHeight * 2, height + marginY + 30 + height / 5)
  local score

  setmetatable(_self, self)
  self.__index = self


  _self.container = container
  container.y = display.screenOriginY + container.height / 2
  container.x = x
  _self.player = player
  _self.supContainer = display.newImageRect("img/uis/player-hud-sup.png", width, height)
  container:insert(_self.supContainer)
  if _self.player ~= nil then
    _self.headImg = display.newImageRect(assets:asBig(_self.player.name, "head"), height, height)
    container:insert(_self.headImg)
  end
  _self.botContainer = display.newImageRect("img/uis/player-hud-bot.png", width, height)
  container:insert(_self.botContainer)


  if player ~= nil then
    if player.score < 10 then score = '0' .. player.score
    else score = player.score end
    _self.headImg.y = -container.height / 2 + _self.headImg.height / 2
    _self.headImg.x = -width / 5
  end

  _self.botContainer.y = -container.height / 2 + _self.botContainer.height / 2 + marginY
  _self.supContainer.y = -container.height / 2 + _self.supContainer.height / 2 + marginY
  if pos == "right" then
    container.xScale = -1
  end

  if _self.player ~= nil then
    _self.scoreTxt = display.newText{
      font = native.newFont("font/Kroftsmann", 30),
      text = score
    }
    _self.scoreTxt.y = -container.height / 2 + _self.botContainer.height / 2 + marginY
    _self.scoreTxt.x = 25
    container:insert(_self.scoreTxt)

    _self.strengthContainer = ProgressBar:new{
      height = subHeight,
      width = 8 * width / 10,
      y = _self.botContainer.y + _self.botContainer.height / 2 + 5 + height / 10,
      backgroundImg = {
        marginTop = 10,
        marginLeft = 10
      },
      bgRectColors = {Colors:getColor("orange")},
      filledRectColors = {Colors:getColor("red")}
    }
    container:insert(_self.strengthContainer.container)
    _self.strengthContainer:setProgress(0)
    _self.strengthContainer:insertToContainer(container)

    _self.dunkImg = display.newImageRect("img/uis/dunk-icon.png", subHeight * 1.5, subHeight * 1.5)
    _self.dunkImg.isVisible = false
    _self.dunkImg.y = _self.strengthContainer.container.y
    _self.dunkImg.x = _self.strengthContainer.container.x - _self.strengthContainer.container.width / 2 - _self.dunkImg.width / 2
    container:insert(_self.dunkImg)

    if needPb == false then
      _self.strengthContainer.container.isVisible = false
    end

    if pos == "right" then
      _self.scoreTxt.xScale = -1
    end

  end

  return _self
end

function PlayerHUD:onScoreChange(score)
  if score < 10 then
    self.scoreTxt.text = '0'.. score
  else
    self.scoreTxt.text = score
  end
end

function PlayerHUD:onCurrStrengthChange(currStrength)
  self.strengthContainer:setFillColor({1, 0, 0.2})
  self.strengthContainer:setProgress(currStrength / 100)
end

function PlayerHUD:insertToContainer(c)
  c:insert(self.container)
end

function PlayerHUD:destroy()
  if self.supContainer.removeSelf then
    self.supContainer:removeSelf()
    self.headImg:removeSelf()
    self.botContainer:removeSelf()
    self.scoreTxt:removeSelf()
    self.container:removeSelf()
  end

  self.supContainer = nil
  self.headImg = nil
  self.botContainer = nil
  self.scoreTxt = nil
  self.container = nil
end
