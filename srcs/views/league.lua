require "srcs.entities.Player"
require "srcs.rendering.Render"
require "srcs.rendering.Colors"
require "srcs.rendering.RadarGrid"
require "srcs.rendering.huds.StarContainer"
require "srcs.Translator"
require "srcs.MatchUtils"
require "srcs.AI.AI"

local pm = require "srcs.PurchaseManager"
local sm = require "srcs.sound.SoundManager"
local composer = require "composer"
local widget = require "widget"
local scene = composer.newScene()
scene.buttonEnabled = false

local calendar = {
  {{1, 10}, {11, 9}, {12, 8}, {2, 7}, {3, 6}, {4, 5}},
  {{1, 12}, {2, 11}, {3, 10}, {4, 9}, {5, 8}, {6, 7}},
  {{1, 6}, {7, 5}, {8, 4}, {9, 3}, {10, 2}, {11, 12}},
  {{1, 2}, {3, 12}, {4, 11}, {5, 10}, {6, 9}, {7, 8}},
  {{1, 4}, {5, 3}, {6, 2}, {7, 12}, {8, 11}, {9, 10}},
  {{1, 3}, {4, 2}, {5, 12}, {6, 11}, {7, 10}, {8, 9}},
  {{1, 7}, {8, 6}, {9, 5}, {10, 4}, {11, 3}, {12, 2}},
  {{1, 8}, {9, 7}, {10, 6}, {11, 5}, {12, 4}, {2, 3}},
  {{1, 5}, {6, 4}, {7, 3}, {8, 2}, {9, 12}, {10, 11}},
  {{1, 9}, {10, 8}, {11, 7}, {12, 6}, {2, 5}, {3, 4}},
  {{1, 11}, {12, 10}, {2, 9}, {3, 8}, {4, 7}, {5, 6}},

  {{10, 1}, {9, 11}, {8, 12}, {7, 2}, {6, 3}, {5, 4}},
  {{12, 1}, {11, 2}, {10, 3}, {9, 4}, {8, 5}, {7, 6}},
  {{6, 1}, {5, 7}, {4, 8}, {3, 9}, {2, 10}, {12, 11}},
  {{2, 1}, {12, 3}, {11, 4}, {10, 5}, {9, 6}, {8, 7}},
  {{4, 1}, {3, 5}, {2, 6}, {12, 7}, {11, 8}, {10, 9}},
  {{3, 1}, {2, 4}, {12, 5}, {11, 6}, {10, 7}, {9, 8}},
  {{7, 1}, {6, 8}, {5, 9}, {4, 10}, {3, 11}, {2, 12}},
  {{8, 1}, {7, 9}, {6, 10}, {5, 11}, {4, 12}, {3, 2}},
  {{5, 1}, {4, 6}, {3, 7}, {2, 8}, {12, 9}, {11, 10}},
  {{9, 1}, {8, 10}, {7, 11}, {6, 12}, {5, 2}, {4, 3}},
  {{11, 1}, {10, 12}, {9, 2}, {8, 3}, {7, 4}, {6, 5}}

}

-- guys model = {
--  name: "kebaby",
--  hands: "basic",
--  shoes: "basic",
--  id: 2,
--  points: 45,
--  lvl: 6 [1 - 10]
--}

local player
local player1 = {
  player = nil,
  radar = nil,
  name = nil,
  starContainer = nil
}
local player2= {
  player = nil,
  radar = nil,
  name = nil,
  starContainer = nil
}
local guys = {}
local guysNb = 12
local round
local bg
local rank
local rankScrollView
local backBtn
local delBtn
local matchBtn
local endBtn
local title
local vsTxt
local rankTxt
local nextMatchBg
local margin = 10
local lines = {}

function simulateMatches()
  local max
  local min
  local diff

  for i = 2, guysNb / 2 do
    if guys[calendar[round][i][1]].lvl > guys[calendar[round][i][2]].lvl then
      max = guys[calendar[round][i][1]]
      min = guys[calendar[round][i][2]]
    else
      min = guys[calendar[round][i][1]]
      max = guys[calendar[round][i][2]]
    end
    diff = max.lvl - min.lvl
    if math.random(0, diff + 1) <= diff then
      max.points = max.points + 1
    else
      min.points = min.points + 1
    end
  end
  round = round + 1
  save(guys, round)
end

function sortGuysByPoints()
  local sorted = {}
  local max

  for i = 1, #guys do
    max = nil
    for j = 1, #guys do
      if guys[j].isPicked ~= true and (max == nil or guys[j].points > max.points) then
        max = guys[j]
      end
    end
    max.isPicked = true
    sorted[i] = max
  end

  for i = 1, #guys do
    guys[i].isPicked = nil
  end

  return sorted
end

function generateGuys()
  local chars = pm.assets.chars
  local hands = pm.assets.hands
  local shoes = pm.assets.shoes
  local ok
  local randV

  for i = 2, guysNb do
    guys[i] = {}
    ok = false
    while ok == false do
      randV = math.random(#chars)
      if chars[randV].isPicked ~= true and chars[randV].name ~= guys[1].name then
        ok = true
        chars[randV].isPicked = true
        guys[i].name = chars[randV].name
      end
    end
    guys[i].shoes = shoes[math.random(#shoes)].name
    guys[i].hands = hands[math.random(#hands)].name
    guys[i].id = i
    guys[i].points = 0
    guys[i].lvl = math.random(1, 10)
  end

  for i = 1, #chars do
    chars[i].isPicked = nil
  end
  return guys
end

function unserialize(toExtract)
  local guy = {}
  local idx = 1
  local fields = {"name", "hands", "shoes", "points", "id", "lvl"}

  for word in string.gmatch(toExtract, '([^,]+)') do
    guy[fields[idx]] = word
    idx = idx + 1
  end
  guy.points = tonumber(guy.points)
  guy.id = tonumber(guy.id)
  guy.lvl = tonumber(guy.lvl)
  return guy
end

function serialize(guy)
  return guy.name .. "," .. guy.hands .. "," .. guy.shoes .. "," .. guy.points .. "," .. guy.id .. "," .. (guy.lvl ~= nil and guy.lvl or "")
end

function save(guys, round)
  local serialized = {}

  for i = 1, guysNb do
    serialized[#serialized + 1] = serialize(guys[i])
  end
  pm.db:setLeague(serialized, round)
end

function initPlayer(p)
  player = Player:new("left", 1)
  player:setHands(p.hands, "disable")
  player:setHead(p.head, "disable")
  player:setShoes(p.shoes, "disable")
  player:setName(p.name)
  -- set to true when load is ended
  player:setVisibility(false)
end

function scene:create(event)
  local sceneGroup = self.view
  local currLeague = event.params.league
  local toExtract

  function deleteLeague(force)
    if scene.buttonEnabled ~= true and force ~= true then return end

    Render:confirmPopup(sceneGroup, Translator:translate("removeLeagueConfirm"), 2 * display.actualContentWidth / 3, 2 * display.actualContentHeight / 3, function()
      pm.db:resetLeague()
      composer.removeScene(composer.getSceneName("current"))
      composer.gotoScene("srcs.views.menu", {
        effect="fade",
        time = 200
      })
    end)
  end

if currLeague == nil then
    guys[1] = {
      name = event.params.player1.name,
      hands = event.params.player1.hands.name,
      shoes = event.params.player1.shoes.name,
      points = 0,
      id = 1,
      lvl = 0
    }
    generateGuys()
    round = 1
    save(guys, round)
  else
    for i = 1, guysNb do
      guys[i] = {}
      guys[i] = unserialize(currLeague["player" .. i])
    end
    round = currLeague.round
  end

  rank = display.newImageRect("img/uis/foodz-buy-container.png", display.actualContentWidth / 2, 4 * display.actualContentHeight / 5 - margin)
  rank.y = display.contentCenterY - display.actualContentHeight / 2 + rank.height / 2 + margin
  rank.x = display.contentCenterX + display.actualContentWidth / 2 - rank.width / 2 - margin
  rankScrollView = widget.newScrollView({
    y = rank.y + rank.height / 15,
    x = rank.x,
    width = rank.width - rank.width / 20,
    height = rank.height - rank.height / 5 - rank.height / 8,
    horizontalScrollDisabled = true,
    hideBackground = true
  })

  nextMatchBg = display.newImageRect("img/uis/char-selector.png", display.actualContentWidth / 2 - margin * 3, 3 * display.actualContentHeight / 5 - margin)
  nextMatchBg.x = display.contentCenterX - display.actualContentWidth / 2 + margin + nextMatchBg.width / 2
  nextMatchBg.y = rank.y


  bg = display.newImageRect("img/uis/background-select.png", display.actualContentWidth, display.actualContentHeight )
  bg.y =  display.contentCenterY
  bg.x = display.contentCenterX

  local function endLeague()
    local rankedGuys = sortGuysByPoints()
    pm.db:resetLeague()
    composer.removeScene(composer.getSceneName("current"))
    composer.gotoScene("srcs.views.league-end", {
      params = {
        rank = rankedGuys,
        player = guys[1]
      }
    })
  end

  local function nextMatch()
    if scene.buttonEnabled ~= true then return end
    local tmpParams
    local controls = {"human", "ai"}

    tmpParams = MatchUtils.createPlayers({player = player1.player, from="left", control = controls[round < guysNb and 1 or 2]}, {player = player2.player, from="right", control = controls[round < guysNb and 2 or 1]})
    tmpParams.onEnd = function(p1, p2)
      local idxs = {left = 1, right = 2}
      local playersArr = {p1.controls == "human" and p1 or p2, p1.controls == "human" and p2 or p1}

      if playersArr[1].score > playersArr[2].score then
        guys[calendar[round - 1][1][idxs[playersArr[1].oriOrigin]]].points = guys[calendar[round - 1][1][idxs[playersArr[1].oriOrigin]]].points + 1
      else
        guys[calendar[round - 1][1][idxs[playersArr[2].oriOrigin]]].points = guys[calendar[round - 1][1][idxs[playersArr[2].oriOrigin]]].points + 1
      end
      save(guys, round)
    end

    tmpParams.onQuit = function(p1, p2)
      local idxs = {left = 1, right = 2}
      local opp = p1.control == "human" and p2 or p1

      guys[calendar[round - 1][1][idxs[opp.oriOrigin]]].points = guys[calendar[round - 1][1][idxs[opp.oriOrigin]]].points + 1
    end

    tmpParams.continuePath = "srcs.views.league"
    tmpParams.needQuit = false
    tmpParams.needReplay = false
    simulateMatches()
    composer.gotoScene("srcs.views.match", {
      params = tmpParams
    })
  end

  matchBtn = Render.createBasicUI{
  		label="Go !",
      width=300 / 2.5, height=157 / 2.5,
  		onRelease = nextMatch,
  		x = display.contentCenterX,
  		y = display.screenOriginY + display.actualContentHeight - 35
  	}
    endBtn = Render.createBasicUI{
    		label=Translator:translate("end"),
        width=300 / 2.5, height=157 / 2.5,
    		onRelease = endLeague,
    		x = display.contentCenterX,
    		y = display.actualContentHeight - 35
    	}

  backBtn = Render:basicButton("img/uis/back-button", function()
    if scene.buttonEnabled ~= true then return end
      composer.gotoScene("srcs.views.menu", {
        effect="fade",
        time = 200
      })
    end, 35, 37)
  backBtn.y = matchBtn.y
  backBtn.x = display.contentCenterX - display.actualContentWidth / 2 + backBtn.width / 2 + 10

  delBtn = Render:basicButton("img/uis/delete-button", deleteLeague, 35, 37)
  delBtn.y = matchBtn.y
  delBtn.x = display.contentCenterX + display.actualContentWidth / 2 - delBtn.width / 2 - 10

  player1.name = widget.newButton{
    defaultFile="img/uis/name-ui.png",
    width = display.actualContentWidth / 8,
    height = display.actualContentHeight / 11,
    labelColor = { default={Colors:getColor("red")}},
    label = "",
    fontSize = 14,
    font = native.newFont("font/GROBOLD")
  }
  player1.name.isVisible = false

  player2.name = widget.newButton{
    defaultFile="img/uis/name-ui.png",
    width = display.actualContentWidth / 8,
    height = display.actualContentHeight / 11,
    labelColor = { default={Colors:getColor("red")}},
    label = "",
    fontSize = 14,
    font = native.newFont("font/GROBOLD")
  }
  player2.name.isVisible = false

  title = widget.newButton{
    defaultFile="img/uis/name-ui.png",
    width = display.actualContentWidth / 6,
    height = display.actualContentHeight /  8.2,
    labelColor = { default={Colors:getColor("red")}},
    label = "",
    font = native.newFont("font/GROBOLD")
  }
  title.x = nextMatchBg.x
  title.y = nextMatchBg.y - nextMatchBg.height / 2

  vsTxt = Render:txtShadow("font/GROBOLD", 75, "VS", 3, nextMatchBg.x, nextMatchBg.y - margin, Colors:getColor("red"))
  rankTxt = display.newText{
    font = native.newFont("font/GROBOLD", 20),
    text = string.upper(Translator:translate("ranking")),
    y = rank.y - rank.height / 3
  }
  rankTxt.x = rank.x

  player1.radar = RadarGrid:new("img/uis/radar.png", 5, 50, 50, 5, {Translator:translate("strength"):upper(), Translator:translate("speed"):upper(), Translator:translate("shoot"):upper(), Translator:translate("jump"):upper(), Translator:translate("dunk"):upper()})
  player2.radar = RadarGrid:new("img/uis/radar.png", 5, 50, 50, 5, {Translator:translate("strength"):upper(), Translator:translate("speed"):upper(), Translator:translate("shoot"):upper(), Translator:translate("jump"):upper(), Translator:translate("dunk"):upper()})

  player1.starContainer = StarContainer:new(120, AI.MAX_LVL)
  player2.starContainer = StarContainer:new(120, AI.MAX_LVL)

  sceneGroup:insert(bg)
  sceneGroup:insert(nextMatchBg)
  sceneGroup:insert(vsTxt)
  sceneGroup:insert(matchBtn)
  sceneGroup:insert(endBtn)
  sceneGroup:insert(backBtn)
  sceneGroup:insert(delBtn)
  sceneGroup:insert(rank)
  sceneGroup:insert(rankTxt)
  sceneGroup:insert(rankScrollView)
  sceneGroup:insert(player1.name)
  sceneGroup:insert(title)

  sceneGroup:insert(player1.radar.container)
  sceneGroup:insert(player2.radar.container)

end

function createNewPlayer(p, ori, id, pos)
  p.player = Player:new(ori, id)
  p.player:setLvl(guys[calendar[round][1][id]].lvl)
  p.player:setHands(pm.assets:getHands(guys[calendar[round][1][id]].hands), "disable")
  p.player:setHead(pm.assets:getHead(guys[calendar[round][1][id]].name), "disable")
  p.player:setShoes(pm.assets:getShoes(guys[calendar[round][1][id]].shoes), "disable")
  p.player:setName(guys[calendar[round][1][id]].name)
  p.radar:draw(p.player:getStats())
  p.player:setPos(pos)
  p.name:setLabel(guys[calendar[round][1][id]].name:gsub("^%l", string.upper))
  p.name.x = p.player:getPos().x
  p.name.y = p.player:getPos().y - p.player:getHeight() / 2 - p.name.height / 2
  p.starContainer:setPos({y = p.player:getPos().y + p.player:getHeight() / 2 + p.starContainer.container.height / 2 + margin, x = p.player:getPos().x})
  p.starContainer:setIndex(p.player.lvl)
  p.radar.container.y = p.starContainer.container.y + p.starContainer.container.height / 2 + p.radar.container.height / 2
  p.radar.container.x = p.name.x
  p.name.isVisible = true
end

function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase
  local opponent
  local sortedGuys

  if phase == "will" then
    title:setLabel(Translator:translate("round") .. " " .. round)

    if calendar[round] ~= nil then
      createNewPlayer(player1, "left", 1, {y = nextMatchBg.y - ( margin * 3), x = nextMatchBg.x - nextMatchBg.width / 2 + margin * 5})
      player1.starContainer:insertTo(sceneGroup)
      player1.player:insertToContainer(sceneGroup)
      sceneGroup:insert(player1.name)
      createNewPlayer(player2, "right", 2, {y = nextMatchBg.y - ( margin * 3), x = nextMatchBg.x + nextMatchBg.width / 2 - margin * 5})
      player2.starContainer:insertTo(sceneGroup)
      player2.player:insertToContainer(sceneGroup)
      sceneGroup:insert(player2.name)
      matchBtn.isVisible = true
      endBtn.isVisible = false
    else
      player1.name.isVisible = false
      player2.name.isVisible = false
      player1.starContainer.container.isVisible = false
      player2.starContainer.container.isVisible = false
      matchBtn.isVisible = false
      vsTxt.isVisible = false
      player1.radar.container.isVisible = false
      player2.radar.container.isVisible = false
      vsTxt.isVisible = false
      endBtn.isVisible = true
      nextMatchBg.isVisible = false
      title.isVisible = false
      rankTxt.x = display.contentCenterX
      rankScrollView.x = display.contentCenterX
      rank.x = display.contentCenterX
    end

    if round >= guysNb then player = player2 else player = player1 end

    sortedGuys = sortGuysByPoints()
    local startY = 0
    local rankMargin = 5
    for i = 1, #sortedGuys do
      lines[i] = Render:rankLine(sceneGroup, rank, sortedGuys[i], round - 1, i)
      lines[i].x = lines[i].width / 2
      lines[i].y = startY + (lines[i].height + rankMargin) * (i - 1) + lines[i].height / 2
      rankScrollView:insert(lines[i])
    end
    Render:infiniteBounce(endBtn, 3, 1000)
    Render:infiniteBounce(matchBtn, 3, 1000)
  else
    scene.buttonEnabled = true
  end

end

function scene:hide(event)
  local phase = event.phase

  if phase == "did" then
    if player1.player ~= nil then player1.player:destroy() end
    if player2.player ~= nil then player2.player:destroy() end
    for i = 1, #lines do
      lines[i]:removeSelf()
      lines[i] = nil
    end
    player1.player = nil
    player2.player = nil
    player = nil
    lines = {}
  else
    Render:unbounce(matchBtn)
    Render:unbounce(endBtn)
    scene.buttonEnabled = false
  end

end

function scene:destroy()
  if rank ~= nil then
    rank:removeSelf()
    rank = nil

    rankScrollView:removeSelf()
    rankScrollView = nil

    backBtn:removeSelf()
    backBtn = nil

    delBtn:removeSelf()
    delBtn = nil

    matchBtn:removeSelf()
    matchBtn = nil

    endBtn:removeSelf()
    endBtn = nil

    title:removeSelf()
    title = nil

    player1.name:removeSelf()
    player1.name = nil

    player2.name:removeSelf()
    player2.name = nil

    vsTxt:removeSelf()
    vsTxt = nil

    rankTxt:removeSelf()
    rankTxt = nil

    nextMatchBg:removeSelf()
    nextMatchBg = nil

    player1.radar:destroy()
    player1.radar = nil

    player2.radar:destroy()
    player2.radar = nil

    player1.starContainer:destroy()
    player1.starContainer = nil

    player2.starContainer:destroy()
    player2.starContainer = nil

    round = 0
    player1.player = nil
    player2.player = nil
    player = nil
    lines = {}
  end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene
