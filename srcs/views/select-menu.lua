-- befuncky effect cartoonize

require "srcs.entities.Player"
require "srcs.rendering.Render"
require "srcs.rendering.huds.StarContainer"
require "srcs.rendering.buttons.FoodzContainer"
require "srcs.rendering.buttons.Selector"
require "srcs.rendering.LimbsSelector"
require "srcs.rendering.Colors"
require "srcs.rendering.RadarGrid"
require "srcs.Translator"
require "srcs.MatchUtils"
require "srcs.AI.AI"

local sm = require "srcs.sound.SoundManager"
local pm = require "srcs.PurchaseManager"
local composer = require "composer"
local widget = require "widget"
local scene = composer.newScene()
local goBtn
local backBtn
local background
local vsTxt
local selectTxt = {}
local selector
local selectorBackground
local foodzContainer
local nextScene
local pos = {
    x = 5,
    y = 0
  }

local player1 = {
  player = nil,
  headGroup = nil,
  handsGroup = nil,
  shoesGroup = nil,
  selectionGroup = nil,
  radar = nil,
  selector = nil
}

local player2 = {
  player = nil,
  headGroup = nil,
  handsGroup = nil,
  shoesGroup = nil,
  selectionGroup = nil,
  radar = nil,
  selector = nil,
  starContainer = nil
}

local currentPlayer

function scene:create(event)
  local sceneGroup = self.view
  local borderSelectorOffset = 8
  local nbChars = event.params.nbChars

  scene.buttonEnabled = false

  local function startGame()
    if scene.buttonEnabled ~= true then return end

    composer.gotoScene(nextScene, {
      params = MatchUtils.createPlayers({player = player1.player, from = "left"}, {player = player2.player, from = "right"})
    })
    return true
  end


  player1.selector = LimbsSelector:new()
  player1.player = Player:new("left", 1)
  player2.selector = LimbsSelector:new()
  player2.player = Player:new("right", 2)



  background = display.newImageRect("img/uis/background-select.png", display.actualContentWidth, display.actualContentHeight )
  background.y =  display.contentCenterY
  background.x = display.contentCenterX

  sceneGroup:insert(background)

  selector = display.newContainer(sceneGroup, 9 * display.actualContentWidth / 10 - borderSelectorOffset, 8.5 * display.actualContentHeight / 10  - borderSelectorOffset)
  selector.x = display.contentCenterX
  selector.y = display.screenOriginY + selector.height / 2 + 5
  selectorBackground = display.newImageRect("img/uis/char-selector.png", selector.width + borderSelectorOffset, selector.height + borderSelectorOffset)
  selectorBackground.x = selector.x
  selectorBackground.y = selector.y

  sceneGroup:insert(selectorBackground)
  sceneGroup:insert(selector)

  selectTxt[1] = Render:txtShadow("font/GROBOLD", 25, string.upper(Translator:translate("charSelectFirst")), 2, 0, -selector.height / 2 + 15 + 10, Colors:getColor("red"))
  selectTxt[2] = Render:txtShadow("font/GROBOLD", 25, string.upper(Translator:translate("charSelectSecond")), 2, 0, selectTxt[1].y + selectTxt[1].height / 2 + 15, Colors:getColor("red"))

  selector:insert(selectTxt[1])
  selector:insert(selectTxt[2])


  goBtn = Render.createBasicUI{
		label="Go !",
    width=300 / 2.5, height=157 / 2.5,
		onRelease = startGame,
		x = display.contentCenterX,
		y = display.screenOriginY + display.actualContentHeight - 35
	}

  backBtn = Render:basicButton("img/uis/back-button", function()
    if scene.buttonEnabled ~= true then return end
      composer.gotoScene("srcs.views.menu", {
        effect="fade",
        time = 200
      })
    end, 35, 37)
  backBtn.x = selector.x - selector.width / 2 + backBtn.width / 2
  backBtn.y = goBtn.y + 10

  -- local arrowDivCoeff = 14
  --
  -- player2.leftArrow = Render:basicButton("img/uis/left-arrow2-marged", function()
  --   if scene.buttonEnabled ~= true then return end
  --   local x = player2.stars[1].x
  --   local y = player2.stars[1].y
  --   player2.player:setLvl(math.max(player2.player.lvl - 1, 1))
  --   Render:deleteStars(player2.stars)
  --   player2.stars = Render:addStars(player2.player:getPos().y + player2.player:getHeight() / 2 + 20, player2.player:getPos().x, player2.player.lvl, selector, player2.stars)
  -- end, 264 / arrowDivCoeff, 279 / arrowDivCoeff)
  --
  -- player2.rightArrow = Render:basicButton("img/uis/right-arrow2-marged", function()
  --   if scene.buttonEnabled ~= true then return end
  --   local x = player2.stars[1].x - player2.stars[1].width / 2
  --   local y = player2.stars[1].y
  --   player2.player:setLvl(math.min(player2.player.lvl + 1, 10))
  --   Render:deleteStars(player2.stars)
  --   player2.stars = Render:addStars(player2.player:getPos().y + player2.player:getHeight() / 2 + 20, player2.player:getPos().x, player2.player.lvl, selector, player2.stars)
  -- end, 264 / arrowDivCoeff, 279 / arrowDivCoeff)

  sceneGroup:insert(goBtn)

  foodzContainer = FoodzContainer:new(550 / 5, 185 / 5, true)
  foodzContainer.group.x = selector.x + selector.width / 2 - foodzContainer.group.width / 2
  foodzContainer.group.y = backBtn.y
  foodzContainer:insertToContainer(sceneGroup)

  local function updatePlayerRadar(p, stats)
    local r

    if player1.player == p then
      r = player1.radar
    else
      r = player2.radar
    end
    if stats ~= nil then
      r:draw(stats)
    else
      r:draw(p:getStats())
    end
  end


  local function onChangeChar(p, t, isUnlocked)
    if isUnlocked ~= false then
      p:setHead(t, "right")
      p:setName(t.name)
      updatePlayerRadar(p)
    else
      updatePlayerRadar(p, p:getStatsConst({head = t.stats}))
    end
  end

  local function onChangeShoes(p, shoes, isUnlocked)
    if isUnlocked ~= false then
      p:setShoes(shoes, "right")
      updatePlayerRadar(p)
    else
      updatePlayerRadar(p, p:getStatsConst({shoes = shoes.stats}))
    end
  end

  local function onChangeHands(p, hands, isUnlocked)
    if isUnlocked ~= false then
      p:setHands(hands, "right")
      updatePlayerRadar(p)
    else
      updatePlayerRadar(p, p:getStatsConst({hands = hands.stats}))
    end
  end

  local function onUnlockSucces(p, thing, node, unlockBtn, fx)
    thing.isUnlocked = true
    fx(p, thing)
    p:insertToContainer(selector)
    foodzContainer:setPoints(pm.points)
    sm:play("buy")
  end

  local function setUnlockButtonVisibility(c, idx)
    if c.idx == idx then
      c.unlockBtn.isVisible = false
    end
  end

  local function onUnlockChar(event, p, char, idx, unlockBtn)
    local function onBuy(status)
      if status == "complete" then
        player1.headGroup.nodes[idx].img.fill.effect = nil
        player2.headGroup.nodes[idx].img.fill.effect = nil
        setUnlockButtonVisibility(player1.headGroup, idx)
        setUnlockButtonVisibility(player2.headGroup, idx)
        onUnlockSucces(p, char, node, unlockBtn, onChangeChar)
      else
        sceneGroup:insert(Render:basicPopup(sceneGroup, Translator:translate("notEnoughFoodz"), 2 * display.actualContentWidth / 3, display.actualContentHeight / 2))
      end
    end

    Render:confirmPopup(sceneGroup, Translator:parse("sureToBuy", {char.name, char.price}), 2 * display.actualContentWidth / 3, 2 * display.actualContentHeight / 3, function()
      pm:unlockChar(char, onBuy)
    end)
  end

  local function onUnlockShoes(event, p, shoes, idx, unlockBtn)
    local function onBuy(status)
      if status == "complete" then
        player1.shoesGroup.nodes[idx].img.fill.effect = nil
        player2.shoesGroup.nodes[idx].img.fill.effect = nil
        setUnlockButtonVisibility(player1.shoesGroup, idx)
        setUnlockButtonVisibility(player2.shoesGroup, idx)
        onUnlockSucces(p, shoes, node, unlockBtn, onChangeShoes)
      else
        sceneGroup:insert(Render:basicPopup(sceneGroup, Translator:translate("notEnoughFoodz"), 2 * display.actualContentWidth / 3, display.actualContentHeight / 2))
      end
    end

    Render:confirmPopup(sceneGroup, Translator:parse("sureToBuy", {shoes.name, shoes.price}), 2 * display.actualContentWidth / 3, 2 * display.actualContentHeight / 3, function()
      pm:unlockShoes(shoes, onBuy)
    end)
  end

  local function onUnlockHands(event, p, hands, idx, unlockBtn)
    local function onBuy(status)
      if status == "complete" then
        player1.handsGroup.nodes[idx].img.fill.effect = nil
        player2.handsGroup.nodes[idx].img.fill.effect = nil
        setUnlockButtonVisibility(player1.handsGroup, idx)
        setUnlockButtonVisibility(player2.handsGroup, idx)
        onUnlockSucces(p, hands, node, unlockBtn, onChangeHands)
      else
        sceneGroup:insert(Render:basicPopup(sceneGroup, Translator:translate("notEnoughFoodz"), 2 * display.actualContentWidth / 3, display.actualContentHeight / 2))
      end
    end

    Render:confirmPopup(sceneGroup,Translator:parse("sureToBuy", {hands.name, hands.price}), 2 * display.actualContentWidth / 3, 2 * display.actualContentHeight / 3, function()
      pm:unlockHands(hands, onBuy)
    end)
  end

  local function onGroupClick(player, group)
    local inner = function(e)
      if scene.buttonEnabled ~= true then return end
      player.headGroup:getContainer().isVisible = false
      player.handsGroup:getContainer().isVisible = false
      player.shoesGroup:getContainer().isVisible = false
      group:getContainer().isVisible = true
    end

    return inner
  end

  local function insertPlayer(player, oriX)
    player.radar = RadarGrid:new("img/uis/radar.png", 5, 50, 50, 5, {Translator:translate("strength"):upper(), Translator:translate("speed"):upper(), Translator:translate("shoot"):upper(), Translator:translate("jump"):upper(), Translator:translate("dunk"):upper()})
    player.radar.container.isVisible = false
    player.headGroup = Selector:new(selector, player.player, pm.assets.chars, onChangeChar, onUnlockChar, oriX, "head")
    selector:insert(player.headGroup:getContainer())
    player.shoesGroup = Selector:new(selector, player.player, pm.assets.shoes, onChangeShoes, onUnlockShoes, oriX, "shoe")
    player.shoesGroup:getContainer().isVisible = false
    selector:insert(player.shoesGroup:getContainer())
    player.handsGroup = Selector:new(selector, player.player, pm.assets.hands, onChangeHands, onUnlockHands, oriX, "hand")
    player.handsGroup:getContainer().isVisible = false
    selector:insert(player.handsGroup:getContainer())
    player.player:setHands(pm.assets.hands[1])
    player.player:setChar(pm.assets.chars[1])
    player.player:setShoes(pm.assets.shoes[1])
    player.player:insertToContainer(selector)
    player.selectionGroup = Render:selectionGroup(35, 37, onGroupClick(player, player.headGroup), onGroupClick(player, player.handsGroup), onGroupClick(player, player.shoesGroup))
    selector:insert(player.selectionGroup)
  end

  vsTxt = Render:txtShadow("font/GROBOLD", 100, "VS", 3, 0, pos.y + 5,  Colors:getColor("red"))
  selector:insert(vsTxt)
  insertPlayer(player1, "left")
  insertPlayer(player2, "right")
  player2.starContainer = StarContainer:new(player2.player:getWidth() * 2.75, AI.MAX_LVL, AI.DEF_LVL, function(origin, index)
    player2.player:setLvl(index)
  end, false)
  player2.starContainer:insertTo(selector)
  player2.player:setLvl(AI.DEF_LVL)
  sceneGroup:insert(backBtn)
end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase
  local nbChars = event.params.nbChars
  local nposX = pos.x
  local RADAR_MARGIN = 20

  local function setPlayerStarsVisi(s, v)
    for i = 1, #s do
      s[i].isVisible = v
    end
  end

  nextScene = event.params.to
  if phase == "will" then
    sm:stopBgMusic()
    foodzContainer:setPoints(pm.points)
     currentPlayer = player1
    --  transition.from(player1.headGroup, {
    --    time = 200,
    --    x = player1.headGroup.x - player1.headGroup.width
    --  })
     if nbChars == 1 then
       vsTxt.isVisible = false
       player2.headGroup:getContainer().isVisible = false
       player2.handsGroup:getContainer().isVisible = false
       player2.shoesGroup:getContainer().isVisible = false
       player2.selectionGroup.isVisible = false
       player2.starContainer.container.isVisible = false
       player2.player:setVisibility(false)
      --  setPlayerStarsVisi(player2.stars, false)
      --  player2.leftArrow.isVisible = false
      --  player2.rightArrow.isVisible = false
       player2.radar.container.isVisible = false
     else
       nposX = nposX - 70
       player2.player:setPos({x= -nposX, y= pos.y})
       player2.starContainer:setPos({x = -nposX, y = player2.player:getPos().y + player2.player:getHeight() / 2 + 20})
       player2.selectionGroup.x = -nposX
       player2.selectionGroup.y = pos.y - player2.player:getHeight() / 2 - player2.selectionGroup.height / 3
       player2.radar.container.x = selector.width / 2 - player2.radar.container.width - selector.width / 5
       player2.radar.container.y = player2.player:getPos().y + player2.player:getHeight() / 2 + player2.radar.height / 2 + 15 + RADAR_MARGIN
      --  player2.stars = Render:addStars(player2.player:getPos().y + player2.player:getHeight() / 2 + 20, player2.player:getPos().x, player2.player.lvl, selector, player2.stars)
       player2.radar.container.isVisible = true
       vsTxt.isVisible = true
       player2.headGroup:getContainer().isVisible = true
       player2.handsGroup:getContainer().isVisible = false
       player2.shoesGroup:getContainer().isVisible = false
       player2.selectionGroup.isVisible = true
       player2.starContainer.container.isVisible = true
       player2.player:setVisibility(true)
      --  setPlayerStarsVisi(player2.stars, true)
      --  player2.leftArrow.isVisible = true
      --  player2.rightArrow.isVisible = true
      --  player2.radar.container.isVisible = true
      --  player2.leftArrow.x = -nposX - 50
      --  player2.leftArrow.y = player2.stars[1].y
      --  player2.rightArrow.x = -nposX + 50
      --  player2.rightArrow.y = player2.stars[1].y
     end
     player1.radar.container.isVisible = true
     player1.player:setPos({x= nposX, y= pos.y})
     player1.selectionGroup.x = nposX
     player1.selectionGroup.y = pos.y - player1.player:getHeight() / 2 - player1.selectionGroup.height / 3
     player1.radar.container.x = -selector.width / 2 + player2.radar.container.width + selector.width / 5
     player1.radar.container.y = player1.player:getPos().y + player1.player:getHeight() / 2 + player1.radar.height / 2 + 15 + RADAR_MARGIN
     selector:insert(player1.radar:draw(player1.player:getStats()))
     selector:insert(player2.radar:draw(player2.player:getStats()))
      --  transition.from(player2.headGroup, {
      --    time = 200,
      --    x = player2.headGroup.x + player2.headGroup.width
      --  })
    --  end
  elseif phase == "did" then
    scene.buttonEnabled = true
    Render:infiniteBounce(goBtn, 3, 1000)
    -- Render:infiniteBounce(backBtn, 3, 1000)
  end
end

function scene:hide(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == "will" then
    scene.buttonEnabled = false
    Render:unbounce(goBtn)
    -- player2.starContainer:destroy()
    -- player2.starContainer = nil
  end
end

function scene:destroy(event)
  local sceneGroup = self.view

  goBtn:removeSelf()
  goBtn = nil

  backBtn:removeSelf()
  backBtn = nil

  background:removeSelf()
  background = nil

  vsTxt:removeSelf()
  vsTxt = nil

  selectTxt[1]:removeSelf()
  selectTxt[2]:removeSelf()
  selectTxt = {}

  selector:removeSelf()
  selector = nil

  selectorBackground:removeSelf()
  selectorBackground = nil

  foodzContainer:destroy()
  foodzContainer = nil

  player1.selectionGroup[1]:removeSelf()
  player1.selectionGroup[1] = nil
  player1.selectionGroup[2]:removeSelf()
  player1.selectionGroup[2] = nil
  -- player1.selectionGroup[3]:removeSelf()
  -- player1.selectionGroup[3] = nil
  player1.selectionGroup:removeSelf()
  player1.selectionGroup = nil
  player1.headGroup:destroy()
  player1.headGroup = nil
  player1.handsGroup:destroy()
  player1.handsGroup = nil
  player1.shoesGroup:destroy()
  player1.shoesGroup = nil
  player1.player:destroy()
  player1.player = nil

  player2.selectionGroup[1]:removeSelf()
  player2.selectionGroup[1] = nil
  player2.selectionGroup[2]:removeSelf()
  player2.selectionGroup[2] = nil
  -- player2.selectionGroup[3]:removeSelf()
  -- player2.selectionGroup[3] = nil
  player2.selectionGroup:removeSelf()
  player2.selectionGroup = nil
  player2.headGroup:destroy()
  player2.headGroup = nil
  player2.handsGroup:destroy()
  player2.handsGroup = nil
  player2.shoesGroup:destroy()
  player2.shoesGroup = nil
  player2.starContainer:destroy()
  player2.starContainer = nil
  player2.player:destroy()
  player2.player = nil

end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
