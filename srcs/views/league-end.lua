require "srcs.entities.Player"
require "srcs.rendering.Render"
require "srcs.rendering.Colors"
require "srcs.Translator"

local composer = require "composer"
local pm = require "srcs.PurchaseManager"
local scene = composer.newScene()
local params
local foodzContainer
local podium
local podiumBg
local goBtn
local bg
local txt
local players = {}
local rankPopupVisible = false

function scene:create(event)
  local sceneGroup = self.view
  local posKeys = {"first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth"}
  params = event.params

  local function getPlayerRank()
    for i = 0, #params.rank do
      if params.rank[i] == params.player then
        return i
      end
    end
    return nil
  end

  local function goToMenu()
    local currentScene = composer.getSceneName("current")
    composer.gotoScene("srcs.views.menu")
    composer.removeScene(currentScene)
  end

  local function rankPopup()
    local rank
    if rankPopupVisible == false then
      rank = getPlayerRank()
      rankPopupVisible = true
      sceneGroup:insert(Render:basicPopup(sceneGroup, Translator:parse("youFinished", {Translator:translate(posKeys[rank])}) , 2 * display.actualContentWidth / 4, display.actualContentHeight / 2, goToMenu))
    end
  end

  bg = display.newImageRect("img/uis/background-select.png", display.actualContentWidth, display.actualContentHeight )
  bg.y =  display.contentCenterY
  bg.x = display.contentCenterX


  podium = display.newImageRect("img/podium.png", display.actualContentWidth / 2, display.actualContentHeight / 3)
  podium.x = display.contentCenterX
  podium.y = display.contentCenterY + 25

  podiumBg = display.newImageRect("img/uis/char-selector.png", podium.width + 30, podium.height + 80)
  podiumBg.x = display.contentCenterX
  podiumBg.y = podium.y - 25


  goBtn = Render.createBasicUI{
      label="Go !",
      width=300 / 2.5, height=157 / 2.5,
      onRelease = rankPopup,
      x = display.contentCenterX,
      y = display.actualContentHeight - 35
    }

  foodzContainer = FoodzContainer:new(550 / 5, 185 / 5, false)
  foodzContainer.group.x = display.actualContentWidth - foodzContainer.group.width / 2 - 50
  foodzContainer.group.y = goBtn.y
  foodzContainer:setPoints(pm.points)

  txt = Render:txtShadow("font/GROBOLD", 40, string.upper(Translator:translate("finalRanking")), 3, display.contentCenterX, 0, Colors:getColor("red"))
  txt.y = display.contentCenterY - display.actualContentHeight / 2 + txt.height / 2 + 2


  sceneGroup:insert(bg)
  sceneGroup:insert(podiumBg)
  sceneGroup:insert(podium)
  sceneGroup:insert(goBtn)
  foodzContainer:insertToContainer(sceneGroup)
  sceneGroup:insert(txt)

  local currPlayer
  local ori = {"left", "left", "right"}
  for i = 1, 3 do
    players[#players + 1] = Player:new(ori[i], i)
    currPlayer = players[#players]
    currPlayer:setHands({name = params.rank[i].hands}, "disable")
    currPlayer:setHead({name = params.rank[i].name}, "disable")
    currPlayer:setShoes({name = params.rank[i].shoes}, "disable")
    currPlayer:insertToContainer(sceneGroup)
  end

  players[1]:setPos({y = podium.y - podium.height / 2 - players[1]:getHeight() / 2 + 5, x = podium.x + 7})
  players[2]:setPos({y = players[1]:getPos().y + podium.height / 3, x = players[1]:getPos().x - podium.width / 3})
  players[3]:setPos({y = players[1]:getPos().y + podium.height / 2.5, x = players[1]:getPos().x + podium.width / 3})
  players[1]:win()
  timer.performWithDelay(math.random(50, 150), function()players[2]:win() end)
  timer.performWithDelay(math.random(150, 250), function()players[3]:win() end)

end

function scene:show(event)
  local phase = event.phase

  if phase == "will" then
    Render:infiniteBounce(goBtn, 3, 1000)
  else
    pm:incrScore(500)
    foodzContainer:setPointsEffect()
  end
end

function scene:hide(event)
  local phase = event.phase

  if phase == "did" then
    Render:unbounce(goBtn)
  end
end

function scene:destroy()
  for i = 1, #players do
    players[i]:destroy()
    players[i] = nil
  end
  players = nil
  foodzContainer:destroy()
  foodzContainer = nil
  podium:removeSelf()
  podium = nil
  podiumBg:removeSelf()
  podiumBg = nil
  goBtn:removeSelf()
  goBtn = nil
  bg:removeSelf()
  bg = nil
  txt:removeSelf()
  txt = nil
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)


return scene
