require "srcs.System"
local widget = require("widget")
local display = require("display")
local composer = require("composer")
local pm = require("srcs.PurchaseManager")
local sm = require "srcs.sound.SoundManager"

FoodzContainer = {
  container = nil,
  txt = nil,
  points = 0,
  effectTimer = nil,
  group = nil,
  currTransition = nil
}

function FoodzContainer:new(width, height, canClick)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.group = display.newGroup(width, height)
  _self.container = display.newImageRect("img/uis/foodz-container.png", width, height)
  _self.group:insert(_self.container)
  _self.txt = display.newText{
    text = "",
    font = native.newFont("font/Kroftsmann", height / 2),
    x = -width / 8
  }
  _self.group:insert(_self.txt)

  local function showOverlay(event)
    if event.phase == "ended" and canClick == true then
      sm:play("click")
      composer.showOverlay("srcs.views.overlay-iap", {
        params = {
          container = _self
        },
        isModal = true
      })
    elseif event.phase == "began" and canClick == true and _self.currTransition == nil then
      _self.currTransition = transition.to(_self.group, {
				transition = easing.continuousLoop,
				xScale = 0.8,
				yScale = 0.8,
        onComplete = function()
          _self.currTransition = nil
        end,
				time = 300
			})
    end
  end

  if System.isMobile() then
    _self.container:addEventListener( "touch", showOverlay)
  end
  return _self
end

function FoodzContainer:setPoints(points)
  self.points = points
  self.txt.text = tostring(points)
end

function FoodzContainer:setPointsEffect()
  local function inner(e)
    local toAdd = math.min(pm.points - self.points, math.floor(math.random() * 10))

    if self.points + toAdd >= pm.points then
      timer.cancel(e.source)
      self.effectTimer = nil
    end
    self:setPoints(self.points + toAdd)
  end
  self.effectTimer = timer.performWithDelay(60, inner, 0)
end

function FoodzContainer:insertToContainer(c)
  c:insert(self.group)
end

function FoodzContainer:destroy()
  if self.effectTimer ~= nil then timer.cancel(self.effectTimer) end
  self.txt:removeSelf()
  self.txt = nil
  self.container:removeSelf()
  self.container = nil
  self.group:removeSelf()
  self.group = nil
  if self.currTransition ~= nil then transition.cancel(self.currTransition) end
  self.currTransition = nil
end
