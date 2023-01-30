require "srcs.entities.Ball"
require "srcs.rendering.buttons.PressButton"
require "srcs.rendering.huds.MatchHUD"
require "srcs.entities.World"
require "srcs.entities.Basket"
require "srcs.AI.AI"
require "srcs.Timer"
require "srcs.MatchUtils"
require "srcs.Translator"
require "srcs.System"
require "srcs.control.Keyboard"

local STATS_MID = 5

local widget = require("widget")
local composer = require("composer")
local rules = require("srcs.Rules")
local pm = require("srcs.PurchaseManager")
local sm = require "srcs.sound.SoundManager"
local scene = composer.newScene()

local ai = nil
local player1 = nil
local ball = nil
local world = nil
local leftBasket = nil
local rightBasket = nil
local runtime = 0
local matchHUD = nil

local leftButton = nil
local rightButton = nil
local jumpButton = nil
local shootButton = nil
local shootButtonDisabled = nil
local dunkButton = nil
local pauseButton = nil

local buttonsContainer = nil

local isOver
local afterShootTimer = nil
local basketTimer = nil

local isLoadingEnd = false
local matchIsOver = false

-- obj of the score to beat
local toBeat = nil

local locas = {
  p1 = nil,
  ball = nil
}

local state = "starting"

local function getDeltaTime()
  local temp = system.getTimer()
  local dt = (temp-runtime) / (1000/60)
  runtime = temp
  return dt
end

function scene:onShootSuccess(owner, origin, points)
  state = "shoot-overlay"
  local p
  local orientation
  local txt = Render:txtShadow("font/GROBOLD", 75, string.upper(origin) .. " ", 5, 0, 0, Colors:getColor("white"))
  local points = Render:txtShadow("font/GROBOLD", 30, points .. " " .. string.upper(Translator:translate("points")) .. " ", 5,  0, 40, Colors:getColor("red"))
  local group = display.newContainer(300, 300)

  world:moveSomeChars(100, 40)
  self.view:insert(group)
  group:insert(txt)
  group:insert(points)

  local function onEnd()
    group:removeSelf()
    txt:removeSelf()
    points:removeSelf()
    group = nil
    txt = nil
    points = nil
  end

  sm:play("cheer")
  Render:basicScale(group, onEnd)
  state = "finished"
end

function scene:onReplay()
  local params = MatchUtils.createPlayers({player = player1, from = player1.oriOrigin})

  isOver = true
  composer.removeScene(composer.getSceneName("current"))
  composer.gotoScene("srcs.views.arena", {
    params = params
  })
  return true
end

function scene:setStartPositions()
  state = "starting"
  local startPos = {
    ball = {
      x = display.contentCenterX,
      y = 0,
    },
    player1 = {
      x = display.contentCenterX - (ball.diameter / 2 + player1:getWidth() / 2) - 50,
      y = world.axis.bot.y - 100
    }
  }

  player1:setPos(startPos.player1)
  ball:setPos(startPos.ball)
  state = "finished"
end

function scene:initPlayers(p1)
  player1 = Player:new("left", 1)
  player1:setHands(p1.hands, "disable")
  player1:setHead(p1.head, "disable")
  player1:setShoes(p1.shoes, "disable")
  player1:setName(p1.name, p1.shortName)
  player1.stats = p1.stats
  -- set to true when load is ended
  player1:setVisibility(false)
end

local function onShoot()
  player1:shoot()
end

local function onDunk()
  if leftBasket:playerCanDunk(player1) == true or rightBasket:playerCanDunk(player1) then
    player1:dunk()
  end
end

local function onJump()
  player1:jump()
end

local function onLeftArrow()
  player1:goToLeft()
end

local function onRightArrow()
  player1:goToRight()
end


function setButtonsOnMobile()
  local alphaValue = 0.9

  shootButton = PressButton:new{
    defaultFile="img/uis/shoot-button-marged.png",
    overFile="img/uis/shoot-button-marged-pressed.png",
    width=264 / 3.5,
    height=282 / 3.5,
    player = player1,
    toAdd = player1.strengthCeil + (player1.stats[3] - STATS_MID) / 8
  }
  shootButton.button.alpha = alphaValue

  shootButtonDisabled = widget.newButton{
    defaultFile="img/uis/shoot-button-marged-pressed.png",
    width=264 / 3.5,
    height=282 / 3.5
  }
  shootButtonDisabled.alpha = alphaValue

  dunkButton = widget.newButton{
    defaultFile="img/uis/dunk-button-marged.png",
    overFile="img/uis/dunk-button-marged-pressed.png",
    width=264 / 3.5,
    height=282 / 3.5,
    onPress = onDunk
  }
  dunkButton.alpha = alphaValue


  leftButton = PressButton:new{
    defaultFile="img/uis/arrow-left-marged.png",
    overFile="img/uis/arrow-left-marged-pressed.png",
    width=264 / 3.5,
    height=282 / 3.5
  }
  leftButton.button.alpha = alphaValue

  rightButton = PressButton:new{
    defaultFile="img/uis/arrow-right-marged.png",
    overFile="img/uis/arrow-right-marged-pressed.png",
    width=264 / 3.5,
    height=282 / 3.5
  }
  rightButton.button.alpha = alphaValue

  jumpButton = widget.newButton{
    defaultFile="img/uis/jump-button-marged.png",
    overFile="img/uis/jump-button-marged-pressed.png",
    width=264 / 3.5,
    height=282 / 3.5,
    onPress = onJump
  }
  jumpButton.alpha = alphaValue
end


function setButtonsOnDesktop()
  Keyboard:init()

  shootButton = Keyboard:create("s", {player = player1, toAdd = player1.strengthCeil + (player1.stats[3] - STATS_MID) / 8})
  dunkButton = Keyboard:create("d", {onPress = onDunk})
  leftButton = Keyboard:create("left")
  rightButton = Keyboard:create("right")
  jumpButton = Keyboard:create("up", {onPress = onJump})
end

function setButtonsPosOnMobile()
  leftButton.button.x = leftButton.button.width / 2
  rightButton.button.x = leftButton.button.x + leftButton.button.width
  rightButton.button.y  = rightButton.button.height / 2
  buttonsContainer:insert(rightButton.button)
  buttonsContainer:insert(leftButton.button)
  jumpButton.x = display.actualContentWidth - jumpButton.width / 2
  shootButton.button.x = jumpButton.x - shootButton.button.width
  shootButtonDisabled.x = shootButton.button.x
  shootButtonDisabled.y = shootButton.button.y
  dunkButton.x = shootButton.button.x
  dunkButton.isVisible = false
  buttonsContainer:insert(shootButton.button)
  buttonsContainer:insert(shootButtonDisabled)
  buttonsContainer:insert(dunkButton)
  buttonsContainer:insert(jumpButton)
end


function scene:create(event)
  -- composer.removeHidden(true)
  local sceneGroup = self.view
  local alphaValue = 0.9
  buttonsContainer = Render.createGroup(display.actualContentWidth, 282 / 3.5, 0, display.actualContentHeight - (282 / 3.5))
  rules.needShootClock = false

  self:initPlayers(event.params.player1)

  isOver = false
  world = World:new()
  world.scene = sceneGroup

  if System.isMobile() then setButtonsOnMobile()
  else setButtonsOnDesktop() end

  local function onPause()

    scene:pause()
    composer.showOverlay("srcs.views.match-pause", {
      params = {
        needReplay = true
      },
      isModal = true
    })
    return true
  end

  Runtime:addEventListener("applicationSuspend", onPause)

  pauseButton = Render:basicButton("img/uis/pause-button", onPause, 25, 27)
  pauseButton.x = display.screenOriginX + display.actualContentWidth - 15
  pauseButton.y = display.screenOriginY + 18
  -- on met a false par defaut car le chargement n'est pas fini
  pauseButton.isVisible = false

  ball = Ball:new("assets/balls/basic.png")
  ball:setVisibility(false)

  world:createAxis()
  world:setBackground("assets/courts/inside.png", sceneGroup)
  leftBasket = Basket:new("assets/baskets/basic.png", "left")
  rightBasket = Basket:new("assets/baskets/basic.png", "right")

  leftBasket:insertTopNetToContainer(sceneGroup)
  rightBasket:insertTopNetToContainer(sceneGroup)
  sceneGroup:insert(leftBasket:getInnerContainer())
  sceneGroup:insert(rightBasket:getInnerContainer())

  toBeat = pm.db:getArenaScore()
  if toBeat == nil or toBeat.score == nil then
    toBeat = nil
  end
  matchHUD = MatchHUD:new(270, 38, display.contentCenterX, 4, player1, toBeat, false, false)
  matchHUD:insertToContainer(sceneGroup)
  player1:insertToContainer(sceneGroup)
  sceneGroup:insert(ball:getContainer())

  leftBasket:insertBotNetToContainer(sceneGroup)
  rightBasket:insertBotNetToContainer(sceneGroup)

  sceneGroup:insert(leftBasket:getOuterContainer())
  sceneGroup:insert(rightBasket:getOuterContainer())

  if System.isMobile() then setButtonsPosOnMobile() end
  sceneGroup:insert(buttonsContainer)
  sceneGroup:insert(pauseButton)

  locas.p1 = Render:localization("assets/heads/" .. event.params.player1.head.name .. ".png")
  locas.ball = Render:localization("assets/balls/basic.png")

  locas.p1.y = locas.p1.height / 2
  locas.ball.y = locas.ball.height / 2
  locas.p1.isVisible = false
  locas.ball.isVisible = false
  sceneGroup:insert(locas.p1)
  sceneGroup:insert(locas.ball)

  sm:play("buzzer")
end

function setButtonsVisibility(p)
  local ret = leftBasket:playerCanDunk(p) == true or rightBasket:playerCanDunk(p) == true
  if ret then
    dunkButton.isVisible = true
    shootButton.button.isVisible = false
    shootButtonDisabled.isVisible = false
  else
    dunkButton.isVisible = false
    if p.ball ~= nil then
      shootButton.button.isVisible = true
      shootButtonDisabled.isVisible = false
    else
      shootButton.button.isVisible = false
      shootButtonDisabled.isVisible = true
    end
  end
  return ret
end


function scene:loop()
  local delta = getDeltaTime()
  local canDunk = nil

  if System.isMobile() == true then
    canDunk = setButtonsVisibility(player1)
  end
  MatchUtils.setDunkIconVisibility(player1, matchHUD.p1Container, canDunk)
  if isLoadingEnd == false then pauseButton.isVisible = false else pauseButton.isVisible = true end

  if state == "finished" then
    Render:setLocaPos(player1:getPos(), nil, ball:getPos(), locas)
    shootButton:update()
    if leftButton.isPressed == true then
      player1:move(-1)
    elseif rightButton.isPressed == true then
      player1:move(1)
    else
      player1:setDefaultAnimation()
    end
  end

  player1:take(ball)
end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase

  local function onEnterFrame()
    if isOver == false and state == "finished" and rules.matchOver ~= true then
      self:loop()
    end
  end

  if phase == "will" then
    sm:stopBgMusic()
    self:setStartPositions()
    physics.start()
    physics.setTimeStep(1 / 35)
    world:addAxisToPhysics()
    leftBasket:addToPhysics()
    leftBasket:setOwner(player1)
    rightBasket:addToPhysics()
    rightBasket:setOwner(player1)
    player1:addToPhysics()
    ball:addToPhysics()
    rules:initMatchTimer(matchHUD.timeContainer, 120)

    player1:subscribeScoreChange(matchHUD.p1Container)
    player1:subscribeCurrStrengthChange(matchHUD.p1Container)
    leftBasket:subscribeShootSuccess(self)
    rightBasket:subscribeShootSuccess(self)
    ball:subscribeOnCollide(rules)
    rules:subscribeEndMatch(self)
    leftBasket:setVisibility(true)
    rightBasket:setVisibility(true)
    player1:setVisibility(true)
		ball:setVisibility(true)
  elseif phase == "did" then
    world:moveSomeCharsWhile(400, 20, 2)
    sm:play("buzzer")
    rules:startMatchTimer()
    Runtime:addEventListener("enterFrame", onEnterFrame)
    basketTimer = timer.performWithDelay(5, function()
      if state == "finished" then
        rightBasket:checkBasket(ball)
        leftBasket:checkBasket(ball)
      end
    end, 0)
    isLoadingEnd = true
  end
end

function scene:onEndTime()
  local endMatchListener = {}

  sm:play("buzzer")
  matchIsOver = true
  function endMatchListener:onBallCollide(event)
    if (event == nil or event.other.type == "Player" or event.other.type == "World") and ball ~= nil then
      ball:unsubscribeOnCollide(endMatchListener)
      scene:matchEnd()
    end
  end

  if ball.owner ~= nil or ball.unresolvedCollideCount ~= 0 then
    self:matchEnd()
  else
    ball:subscribeOnCollide(endMatchListener)
  end
end

function scene:matchEnd()
  local points = 100
  local nimg

  world:moveSomeChars(100, 40)
  player1:setDefaultAnimation()
  rules:overMatch()
  matchHUD:hideSubGUIs()
  points = points + (player1.score * 3)

  if toBeat == nil or player1.score > toBeat.score then
    pm.db:setArenaScore(player1.score, player1.name)
    points = points + 400
  end
  transition.moveTo(buttonsContainer, {
    delay = 200,
    time = 100,
    y = display.actualContentHeight + buttonsContainer.height / 2
  })
  transition.moveTo(pauseButton, {
    delay = 200,
    time = 100,
    y = -pauseButton.height - 20
  })
  composer.showOverlay("srcs.views.match-end", {
      effect = "fade",
      time = 200,
      params = {
        points = points,
        player1 = player1,
        container = matchHUD
      },
      isModal = true
  })
end

function scene:pause()
  state = "paused"
  if afterShootTimer ~= nil then timer.pause(afterShootTimer) end
  player1:onPause()
  physics.pause()
  rules:pauseMatchTimer()
  rules:pauseShootClock()
end

function scene:resume()
  state = "finished"
  if afterShootTimer ~= nil then timer.resume(afterShootTimer) end
  player1:onResume()
  isOver = false
  physics.start()
  rules:resumeMatchTimer()
  rules:resumeShootClock()
end

function scene:quit(newPath)
  local path = "srcs.views.menu"
  local to = composer.getSceneName("current")

  if newPath ~= nil then path = newPath end
  composer.removeScene(composer.getSceneName("current"))
  composer.gotoScene(path, {
    params = {
      to = to,
      nbChars = 1
    }
  })
end

function scene:continue()
  local to = composer.getSceneName("current")

  composer.removeScene(composer.getSceneName("current"))
  composer.gotoScene("srcs.views.select-menu", {
    params = {
      to = to,
      nbChars = 1
    }
  })
end

function scene:hide(event)
  local sceneGroup = self.view
  local phase = event.phase
end

function scene:destroy(event)
  local sceneGroup = self.view

  isOver = true
  if afterShootTimer ~= nil then timer.cancel(afterShootTimer) end
  if basketTimer ~= nil then timer.cancel(basketTimer) end
  ball:destroy()
  leftBasket:destroy()
  rightBasket:destroy()
  player1:destroy()
  world:destroy()
  matchHUD:destroy()
  rules:destroy()
  pauseButton:removeSelf()
  locas.p1:removeSelf()
  locas.ball:removeSelf()
  if System.isMobile() == true then
    jumpButton:removeSelf()
    leftButton:destroy()
    rightButton:destroy()
    shootButton:destroy()
    shootButtonDisabled:removeSelf()
    leftButton = nil
    rightButton = nil
    jumpButton = nil
    shootButton = nil
    shootButtonDisabled = nil
    dunkButton = nil
  else
    Keyboard:destroy()
  end
  physics.stop()

  isLoadingEnd = false
  pauseButton = nil
  ball = nil
  leftBasket = nil
  rightBasket = nil
  player1 = nil
  world = nil
  matchHUD = nil
  afterShootTimer = nil
  basketTimer = nil
  runtime = 0
  locas = {}
  state = "starting"
  matchIsOver = false
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
