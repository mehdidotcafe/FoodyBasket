require "srcs.entities.Ball"
require "srcs.rendering.graphics.AsideText"
require "srcs.rendering.buttons.PressButton"
require "srcs.rendering.huds.MatchHUD"
require "srcs.entities.World"
require "srcs.entities.Basket"
require "srcs.AI.AI"
require "srcs.Timer"
require "srcs.Translator"
require "srcs.System"
require "srcs.MatchUtils"
require "srcs.control.Keyboard"

local STATS_MID = 5

local widget = require("widget")
local composer = require("composer")
local rules = require("srcs.Rules")
local pm = require("srcs.PurchaseManager")
local scene = composer.newScene()
local sm = require "srcs.sound.SoundManager"

local ai = nil
local ai2

local player1 = nil
local humanPlayerAside = nil
local player2 = nil
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
local dunkButton = nil
local pauseButton = nil
local takeButton = nil

local buttonsContainer = nil

local isOver
local afterShootTimer = nil
local basketTimer = nil

local isLoadingEnd = false
local matchIsOver = false

local humanPlayer = nil

local locas = {
  p1 = nil,
  p2 = nil,
  ball = nil
}

local state = "starting"

local function getDeltaTime()
  local temp = system.getTimer()
  local dt = (temp-runtime) / (1000/60)
  runtime = temp
  return dt
end

function scene:setShootPositions(playerHasBall)
  local playerMargin = {
    x = 120,
    y = 100
  }
  state = "setting-pos"
  local pos = {
    left = {
      x = display.contentCenterX - ball.diameter / 2 - playerMargin.x,
      y = world.axis.bot.y - playerMargin.y
    },
    right = {
      x = display.contentCenterX - ball.diameter / 2 + playerMargin.x,
      y = world.axis.bot.y - playerMargin.y
    },
    ball = {
      x = display.contentCenterX,
      y = 75
    }
  }
  local f = {left = -1, right = 1}

  if matchIsOver == true then
    ball:notifyOnCollide()
    return
  end

  scene:setPosAndClear(pos.ball, pos[player1.oriOrigin], pos[player2.oriOrigin])
  ball:applyForce({x = 15 * f[playerHasBall.oriOrigin], y = 0})

  -- playerHasBall:take(ball, true)
  state = "finished"
end

function clearShootClock()
  ball.lastCollidePlayer = nil
  rules:clearShootClock()
end

function scene:onShootSuccess(owner, origin, points)
  clearShootClock()
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

  Render:basicScale(group, onEnd)

  if owner == player1 then
    sm:play("cheer")
    p = player2
  elseif owner == player2 then
    sm:play("boo")
    p = player1
  end

  if rules.isSuddentDeath == true then
    scene:matchEnd()
  else
    timer.performWithDelay(300, function()
      self:setShootPositions(p)
    end)
  end
end

function scene:onReplay()
  local pparams = MatchUtils.createPlayers({player = player1, from = player1.oriOrigin}, {player = player2, from = player2.oriOrigin})

  isOver = true
  composer.removeScene(composer.getSceneName("current"))
  composer.gotoScene("srcs.views.match", {
    params = pparams
  })
  return true
end

function scene:setPosAndClear(ballPos, p1pos, p2pos)
  if player1.ball ~= nil then
    player1:resetBall()
  end
  if player2.ball ~= nil then
    player2:resetBall()
  end
  ball:clearForces()
  ball:setPos(ballPos)
  player1:clearForces(true)
  player1:resetRotation()
  player1:setOrientation(player1.oriOrigin, "disable")
  player1:setPos(p1pos)
  player2:clearForces(true)
  player2:resetRotation()
  player2:setOrientation(player2.oriOrigin, "disable")
  player2:setPos(p2pos)
  rules.isOver = false
  leftBasket:resetShoot()
  rightBasket:resetShoot()
end

function scene:setStartPositions()
  state = "starting"

  local coords = {
    left = {x = display.contentCenterX - ball.diameter / 2 - 80, y = world.axis.bot.y - 100},
    right = {x = display.contentCenterX + ball.diameter / 2 + 80, y = world.axis.bot.y - 100},
  }

  local startPos = {
    ball = {
      x = display.contentCenterX,
      y = 0,
    },
    player1 = {
      x = coords[player1.oriOrigin].x,
      y = coords[player1.oriOrigin].y
    },
    player2 = {
      x = coords[player2.oriOrigin].x,
      y = coords[player2.oriOrigin].y
    }
  }

  scene:setPosAndClear(startPos.ball, startPos.player1, startPos.player2)
  state = "finished"
end

function scene:initPlayers(p1, p2)
  player1 = Player:new(p1.from, 1)
  player1:setLvl(p1.lvl)
  player1:setHands(p1.hands, "disable")
  player1:setHead(p1.head, "disable")
  player1:setShoes(p1.shoes, "disable")
  player1:setName(p1.name)
  player1.stats = p1.stats
  player1.control = p1.control or "human"
  -- set to true when load is ended
  player1:setVisibility(false)
  if p2 ~= nil then
    player2 = Player:new(p2.from, 2)
    player2:setLvl(p2.lvl)
    player2:setHands(p2.hands, "disable")
    player2:setHead(p2.head, "disable")
    player2:setShoes(p2.shoes, "disable")
    player2:setName(p2.name, p2.shortName)
    player2.stats = p2.stats
    player2.control = p2.control or "ai"
    -- set to true when load is ended
    player2:setVisibility(false)
  end
  if player1.control == "ai" then
    ai = AI:new(player1, player2, p1.lvl)
    -- ai2 = AI:new(player2, player1, p2.lvl)
  elseif player2 ~= nil and player2.control == "ai" then
    ai = AI:new(player2, player1, p2.lvl)
    -- ai2 = AI:new(player1, player2, p1.lvl)
  end

  if player1.control == "human" then
    humanPlayer = player1
  elseif player2 ~= nil and player2.control == "human" then
    humanPlayer = player2
  end
  if humanPlayer ~= nil then
    humanPlayerAside = AsideText:new(Translator:translate("you"), humanPlayer, 2500)
  end
end

local function onDunk()
  if humanPlayer ~= nil and humanPlayer.baskets[1]:playerCanDunk(humanPlayer) == true then
    humanPlayer:dunk()
  end
end

local function onTake()
  if humanPlayer ~= nil and humanPlayer.ball == nil then
    humanPlayer:stealBall(ai.player)
  end
end

local function onJump()
  if humanPlayer ~= nil then
    humanPlayer:jump()
  end
end

function setButtonsOnMobile()
  local alphaValue = 0.9

  shootButton = PressButton:new{
    defaultFile="img/uis/shoot-button-marged.png",
    overFile="img/uis/shoot-button-marged-pressed.png",
    width=264 / 3.5,
    height=282 / 3.5,
    player = humanPlayer,
    toAdd = humanPlayer ~= nil and humanPlayer.strengthCeil + (humanPlayer.stats[3] - STATS_MID) / 8 or 0
  }
  shootButton.button.alpha = alphaValue

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

  takeButton = widget.newButton{
    defaultFile="img/uis/take-button-marged.png",
    overFile="img/uis/take-button-marged-pressed.png",
    width=264 / 3.5,
    height=282 / 3.5,
    onPress = onTake
  }
  takeButton.alpha = alphaValue

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

  shootButton = Keyboard:create("s", {player = humanPlayer, toAdd = (humanPlayer ~= nil and (humanPlayer.strengthCeil + (humanPlayer.stats[3] - STATS_MID) / 8) or 0) })
  dunkButton = Keyboard:create("d", {onPress = onDunk})
  leftButton = Keyboard:create("left")
  rightButton = Keyboard:create("right")
  jumpButton = Keyboard:create("up", {onPress = onJump})
  takeButton = Keyboard:create("f", {onPress = onTake})
end

function setButtonsPosOnMobile()
  leftButton.button.x = leftButton.button.width / 2
  rightButton.button.x = leftButton.button.x + leftButton.button.width
  rightButton.button.y  = rightButton.button.height / 2
  buttonsContainer:insert(rightButton.button)
  buttonsContainer:insert(leftButton.button)

  jumpButton.x = display.actualContentWidth - jumpButton.width / 2

  takeButton.x = jumpButton.x - takeButton.width

  shootButton.button.x = takeButton.x

  dunkButton.x = shootButton.button.x
  dunkButton.isVisible = false
  buttonsContainer:insert(shootButton.button)
  buttonsContainer:insert(dunkButton)
  buttonsContainer:insert(jumpButton)
  buttonsContainer:insert(takeButton)
end


function scene:create(event)
  -- composer.removeHidden(true)
  local sceneGroup = self.view
  buttonsContainer = Render.createGroup(display.actualContentWidth, 282 / 3.5, 0, display.actualContentHeight - (282 / 3.5))

  params = event.params
  params.continuePath = params.continuePath or "srcs.views.select-menu"
  self:initPlayers(params.player1, params.player2)

  isOver = false
  world = World:new()
  world.scene = sceneGroup

  if System.isMobile() then setButtonsOnMobile()
  else setButtonsOnDesktop() end

  local function onPause()

    scene:pause()
    composer.showOverlay("srcs.views.match-pause", {
      params = {
        needReplay = params.needReplay == nil and  true or params.needReplay
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
  world:setBackground("assets/courts/tribune.png", sceneGroup)
  leftBasket = Basket:new("assets/baskets/basic.png", "left")
  rightBasket = Basket:new("assets/baskets/basic.png", "right")

  leftBasket:insertTopNetToContainer(sceneGroup)
  rightBasket:insertTopNetToContainer(sceneGroup)
  sceneGroup:insert(leftBasket:getInnerContainer())
  sceneGroup:insert(rightBasket:getInnerContainer())

  matchHUD = MatchHUD:new(270, 38, display.contentCenterX, 4, player1, player2)
  matchHUD:insertToContainer(sceneGroup)
  player1:insertToContainer(sceneGroup)
  player2:insertToContainer(sceneGroup)
  sceneGroup:insert(ball:getContainer())

  leftBasket:insertBotNetToContainer(sceneGroup)
  rightBasket:insertBotNetToContainer(sceneGroup)

  sceneGroup:insert(leftBasket:getOuterContainer())
  sceneGroup:insert(rightBasket:getOuterContainer())


  if System.isMobile() then setButtonsPosOnMobile() end
  sceneGroup:insert(buttonsContainer)
  sceneGroup:insert(pauseButton)

  locas.p1 = Render:localization("assets/heads/" .. params.player1.head.name .. ".png")
  locas.p2 = Render:localization("assets/heads/" .. params.player2.head.name .. ".png")
  locas.ball = Render:localization("assets/balls/basic.png")

  locas.p1.y = locas.p1.height / 2
  locas.p2.y = locas.p2.height / 2
  locas.ball.y = locas.ball.height / 2
  locas.p1.isVisible = false
  locas.p2.isVisible = false
  locas.ball.isVisible = false
  sceneGroup:insert(locas.p1)
  sceneGroup:insert(locas.p2)
  sceneGroup:insert(locas.ball)

end

function scene:onEndShootClock(playerContainer)
  if playerContainer == nil then return end
  local other
  local txt = Render:txtShadow("font/GROBOLD", 50, string.upper(Translator:translate("endShootClockFirst")), 5, 0, 0, Colors:getColor("white"))
  local points = Render:txtShadow("font/GROBOLD", 50, string.upper(Translator:translate("endShootClockSecond")), 5, 0, 0, Colors:getColor("red"))
  local group = display.newContainer(450, 300)
  local player = playerContainer.wrapper
  state = "shoot-screen"

  group:insert(txt)
  group:insert(points)

  local function onEnd()
    self:setShootPositions(other)
    state = "finished"
    group:removeSelf()
    txt:removeSelf()
    points:removeSelf()

    group = nil
    txt = nil
    points = nil
  end

  points.y = txt.height / 2 + 5
  Render:basicScale(group, onEnd)
  sm:play("buzzer")
  if player.ball ~= nil then
    player:untake()
  end
  if player == player1 then
    other = player2
  else
    other = player1
  end
end

function setButtonsVisibility(p)
  local ret = p.baskets[1]:playerCanDunk(p)

  if  ret == true then
    dunkButton.isVisible = true
    matchHUD.p1Container.dunkImg.isVisible = true
    shootButton.button.isVisible = false
  else
    dunkButton.isVisible = false
    matchHUD.p1Container.dunkImg.isVisible = false
    if p.ball ~= nil then
      shootButton.button.isVisible = true
    else
      shootButton.button.isVisible = false
    end
  end
  if p.ball == nil then
    takeButton.isVisible = true
  else
    takeButton.isVisible = false
  end
  return ret
end

local str = nil

function scene:loop()
  local delta = getDeltaTime()
  local canDunk = nil

  if System.isMobile() == true and humanPlayer ~= nil then
    canDunk = setButtonsVisibility(humanPlayer)
  end
  MatchUtils.setDunkIconVisibility(player1, matchHUD.p1Container)
  MatchUtils.setDunkIconVisibility(player2, matchHUD.p2Container)
  if isLoadingEnd == false then pauseButton.isVisible = false else pauseButton.isVisible = true end

  if state == "finished" then
    Render:setLocaPos(player1:getPos(), player2:getPos(), ball:getPos(), locas)
    shootButton:update()
    if leftButton.isPressed == true and humanPlayer ~= nil then
      humanPlayer:move(-1)
    elseif rightButton.isPressed == true and humanPlayer ~= nil then
      humanPlayer:move(1)
    elseif humanPlayer ~= nil then
      humanPlayer:setDefaultAnimation()
    end

    ai:takeDecision(ball, math.min(rules:getShootClockRemainTime(), rules:getMatchClockRemainTime()), leftBasket, rightBasket)
    -- if ai2 ~= nil then
    --   ai2:takeDecision(ball, math.min(rules:getShootClockRemainTime(), rules:getMatchClockRemainTime()), leftBasket, rightBasket)
    -- end
  end

  player1:take(ball)
  player2:take(ball)
  if humanPlayer ~= nil then
    humanPlayerAside:update()
  end
end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase

  local baskets = {
    left = rightBasket,
    right = leftBasket
  };

  local function onEnterFrame()
    if isOver == false and state == "finished" and rules.matchOver ~= true then
      self:loop()
    end
  end

  if phase == "will" then

    physics.start()
    physics.setTimeStep(1 / 35)
    world:addAxisToPhysics()
    leftBasket:addToPhysics()
    rightBasket:addToPhysics()
    baskets[player1.oriOrigin]:setOwner(player1)
    baskets[player2.oriOrigin]:setOwner(player2)
    player1:setPos({x = 0, y = 0})
    player1:addToPhysics()
    player2:setPos({x = 0, y = 0})
    player2:addToPhysics()
    ball:addToPhysics()
    rules:initMatchTimer(matchHUD.timeContainer)

    player1:subscribeScoreChange(matchHUD.p1Container)
    player1:subscribeCurrStrengthChange(matchHUD.p1Container)
    player2:subscribeScoreChange(matchHUD.p2Container)
    player2:subscribeCurrStrengthChange(matchHUD.p2Container)
    leftBasket:subscribeShootSuccess(self)
    rightBasket:subscribeShootSuccess(self)
    ball:subscribeOnCollide(rules)
    rules:subscribeShootClockEnd(self)
    rules:subscribeShootClockChange(matchHUD.timeContainer)
    rules:subscribeEndMatch(self)
    self:setStartPositions()
    leftBasket:setVisibility(true)
    rightBasket:setVisibility(true)
    player1:setVisibility(true)
    player2:setVisibility(true)
		ball:setVisibility(true)
    if humanPlayer ~= nil then
      humanPlayerAside:insertToContainer(sceneGroup)
    end
  elseif phase == "did" then
    world:moveSomeCharsWhile(400, 20, 2)
    sm:play("buzzer")
    rules:startMatchTimer()
    Runtime:addEventListener("enterFrame", onEnterFrame)
    Runtime:addEventListener("enterFrame", function()
      if state == "finished" then
        rightBasket:checkBasket(ball)
        leftBasket:checkBasket(ball)
      end
    end)
    isLoadingEnd = true
  end
end

function scene:preMatchEnd()
  local txtFirst
  local txtSecond
  local group

  local function onEnd()
    matchIsOver = false
    rules.isSuddentDeath = true
    scene:setStartPositions()
    state = "finished"
    txtFirst:removeSelf()
    txtSecond:removeSelf()
    group:removeSelf()

    group = nil
    txtFirst = nil
    txtSecond = nil
  end

  if player1.score == player2.score then

    sm:play("buzzer")
    txtFirst = Render:txtShadow("font/GROBOLD", 50, string.upper(Translator:translate("suddentDeathFirst")), 5, 0, 0, Colors:getColor("white"))
    txtSecond = Render:txtShadow("font/GROBOLD", 50, string.upper(Translator:translate("suddentDeathSecond")), 5, 0, 0, Colors:getColor("red"))
    group = display.newContainer(450, 300)
    group:insert(txtFirst)
    group:insert(txtSecond)
    txtSecond.y = txtFirst.height / 2 + 5
    Render:basicScale(group, onEnd)
    clearShootClock()
  else
    scene:matchEnd()
  end
end

function scene:onEndTime()
  local endMatchListener = {}

  matchIsOver = true
  function endMatchListener:onBallCollide(event)
    if (event == nil or event.other.type == "Player" or event.other.type == "World") and ball ~= nil then
      ball:unsubscribeOnCollide(endMatchListener)
      timer.performWithDelay(1, function()scene:preMatchEnd()end)
    end
  end

  if ball.owner ~= nil or ball.unresolvedCollideCount ~= 0 then
    self:preMatchEnd()
  else
    ball:subscribeOnCollide(endMatchListener)
  end
end

function scene:matchEnd()
  local points = 100

  -- world:moveSomeChars(100, 40)
  sm:play("buzzer")
  if params.onEnd then params.onEnd(player1, player2) end
  clearShootClock()
  player1:setDefaultAnimation()
  if player2 ~= nil then player2:setDefaultAnimation() end
  rules:overMatch()
  matchHUD:hideSubGUIs()
  if player1.score <= player2.score then
    points = points / 2
  end
  points = points + (player1.score * 3)
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
        player2 = player2,
        needQuit = params.needQuit == nil and  true or params.needQuit,
        needReplay = params.needReplay == nil and  true or params.needReplay,
        needContinue = params.needContinue == nil and  true or params.needContinue,
        container = matchHUD
      },
      isModal = true
  })
end

function scene:pause()
  state = "paused"
  if afterShootTimer ~= nil then timer.pause(afterShootTimer) end
  player1:onPause()
  ai:onPause()
  if player2 ~= nil then player2:onPause() end
  if ai2 ~= nil then ai2:onPause() end
  physics.pause()
  rules:pauseMatchTimer()
  rules:pauseShootClock()
end

function scene:resume()
  state = "finished"
  if afterShootTimer ~= nil then timer.resume(afterShootTimer) end
  player1:onResume()
  ai:onResume()
  if player2 ~= nil then player2:onResume() end
  if ai2 ~= nil then ai2:onResume() end
  isOver = false
  physics.start()
  rules:resumeMatchTimer()
  rules:resumeShootClock()
end

function scene:quit(newPath)
  local path = "srcs.views.menu"
  -- local path = "srcs.views.menu"
  local to = composer.getSceneName("current")

  if newPath ~= nil then path = newPath end
  if params.onQuit ~= nil then
    params.onQuit(player1, player2)
  end
  composer.removeScene(composer.getSceneName("current"))
  composer.gotoScene(path, {
    params = {
      to = to,
      nbChars = 2
    }
  })
end

function scene:continue()
  local to = composer.getSceneName("current")

  composer.removeScene(composer.getSceneName("current"))
  composer.gotoScene(params.continuePath, {
    params = {
      to = to,
      nbChars = 2
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
  -- Render:unbouncePlayer(player1)
  -- Render:unbouncePlayer(player2)
  ai:destroy()
  if ai2 ~= nil then ai2:destroy() end
  ball:destroy()
  leftBasket:destroy()
  rightBasket:destroy()
  player1:destroy()
  if humanPlayerAside ~= nil then
    humanPlayerAside:destroy()
  end
  player2:destroy()
  world:destroy()
  matchHUD:destroy()
  rules:destroy()
  pauseButton:removeSelf()
  locas.p1:removeSelf()
  locas.p2:removeSelf()
  locas.ball:removeSelf()
  if System.isMobile() == true then
    takeButton:removeSelf()
    jumpButton:removeSelf()
    leftButton:destroy()
    rightButton:destroy()
    shootButton:destroy()
    leftButton = nil
    rightButton = nil
    takeButton = nil
    jumpButton = nil
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
  humanPlayerAside = nil
  player2 = nil
  world = nil
  matchHUD = nil
  afterShootTimer = nil
  basketTimer = nil
  ai = nil
  ai2 = nil
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
