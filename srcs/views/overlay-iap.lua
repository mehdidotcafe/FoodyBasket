require "srcs.rendering.Colors"
require "srcs.Store"

local composer = require("composer")
local widget = require("widget")
local pm = require("srcs.PurchaseManager")

local scene = composer.newScene()
local scrollView
local background
local buyTxt
local backBtn
local group

local store = Store:new()

function scene:create(event)
  local sceneGroup = self.view
  local pm = require("srcs.PurchaseManager")
  local height = 4 * display.actualContentHeight / 5
  local width = 3 * display.actualContentWidth / 5
  local divHeight = height / 4
  local margin = divHeight / 5
  local foodzContainer = event.params.container
  local s = Store:new()
  group = display.newGroup(width, height)
  group.y = display.contentCenterY
  group.x = display.contentCenterX

  background = display.newImageRect("img/uis/foodz-buy-container.png", width, height)
  scrollView = widget.newScrollView(
    {
        y = background.height / 10,
        x = 0,
        width = width - 20,
        height = height - height / 3,
        horizontalScrollDisabled = true,
        hideBackground = true,
        listener = nil
    })
    scrollView.isVisible = false

    local function onBuyClick(obj, event)
      Render:confirmPopup(sceneGroup, Translator:parse("buyPoints", {obj.points, obj.price}), 2 * display.actualContentWidth / 3, 2 * display.actualContentHeight / 3, function()
        pm:onBuyClick(obj, function(state)

          if state == "purchased" then
            foodzContainer:setPointsEffect()
          else
            Render:basicPopup(sceneGroup, Translator:translate("failBilling"), 2 * display.actualContentWidth / 3, 2 * display.actualContentHeight / 3)
          end
        end)
      end)
    end

    buyTxt = display.newText{
      text = string.upper(Translator:translate("buy")) .. " FOODZ",
      font = native.newFont("font/GROBOLD", height / 14),
      x = background.width / 6,
      y = -background.height / 2 + background.height / 6
    }
    buyTxt.isVisible = false
    backBtn = Render:basicButton("img/uis/arrow-left", function()
      composer.hideOverlay("fade", 100)
    end, 9.5 * (background.width / 10) / 10, background.width / 10)
    backBtn.y = buyTxt.y - backBtn.height / 4
    backBtn.x = -background.width / 2.5
    backBtn.isVisible = false
    group:insert(background)
    group:insert(scrollView)
    for i = 1, #s.products do
      if s.products[i] ~= nil then
        local div = Render:buyUi({price = s.products[i].localizedPrice, points = pm.buyablePoints[i].points, id = s.products[i].productIdentifier}, i, scrollView.width, divHeight, onBuyClick)
        div.y = (i - 1) * (div.height + margin) + div.height / 2
        scrollView:insert(div)
      end
    end
    group:insert(buyTxt)
    group:insert(backBtn)
    sceneGroup:insert(group)
end

function scene:hide()
end

function scene:show(event)
  if event.phase == "will" then
    Render:popFromBackground(background, function()
      scrollView.isVisible = true
      buyTxt.isVisible = true
      backBtn.isVisible = true
    end)
  end
end

function scene:destroy()
end


scene:addEventListener("create", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("show", scene)
scene:addEventListener("destroy", scene)

return scene
