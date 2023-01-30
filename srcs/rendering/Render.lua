require "srcs.rendering.graphics.TextParticles"

Render = {}

local widget = require "widget"
local assets = require "srcs.Assets"
local sm = require "srcs.sound.SoundManager"
local PICTURE_SIZE = {
  width = 45,
  height = 45
}

function Render.createBasicUI(table)
  local basicButton

  local function onEnd()
    basicButton.currTransition = nil
  end

  if table.sound == nil then table.sound = "click" end
  basicButton = widget.newButton{
    label = table.label,
    fontSize = table.height / 2,
    font = native.newFont("font/Kroftsmann"),
    labelColor = { default={255}, over={128} },
		defaultFile="img/uis/basicui.png",
		overFile="img/uis/basicui-pressed.png",
		width=table.width, height=table.height,
    onPress = function(event)
      if basicButton.currTransition ~= nil then return end
      sm:play(table.sound)
			basicButton.currTransition = transition.to(basicButton, {
				transition = easing.continuousLoop,
				xScale = 0.8,
				yScale = 0.8,
        onComplete = onEnd,
				time = 300
			})
		end,
		onRelease = table.onRelease
  }

  if table.x ~= nil then
    basicButton.x = table.x
  end
  if table.y ~= nil then
    basicButton.y = table.y
  end
  return basicButton
end

function Render:basicButton(path, onRelease, width, height, sound)
  local btn

  local function onEnd()
    btn.currTransition = nil
  end
  if width == nil then width = 50 end
  if height == nil then height = 53 end
  if sound == nil then sound = "click" end
  btn = widget.newButton{
    defaultFile=path .. ".png",
    overFile=path .. "-pressed.png",
    width=width,
    height=height,
    onPress = function(event)
      if btn.currTransition ~= nil then return end

      sm:play(sound)
      btn.currTransition = transition.to(btn, {
        transition = easing.continuousLoop,
        xScale = 0.8,
        yScale = 0.8,
        onComplete = onEnd,
        time = 300
      })
    end,
    onRelease = onRelease
  }
  return btn
end

function Render.createContainer(width, height, x, y)
  local container = display.newContainer(width, height)

  container.anchorX = 0
  container.anchorY = 0
  container.x = x
  container.y = y
  container.x = x + display.screenOriginX
  container.y = y + display.screenOriginY
  return container
end

function Render.createGroup(width, height, x, y)
  local container = display.newGroup(width, height)

  container.x = x + display.screenOriginX
  container.y = y + display.screenOriginY
  return container
end

function Render.createArrowSelector(container, selector, group)
  local arrowWidth = 30
  local arrowHeight = 30

  local function onLeft()
    selector:onArrowLeft(group)
    return true
  end

  local function onRight()
    selector:onArrowRight(group)
    return true
  end

  local leftArrow = widget.newButton{
    defaultFile="img/uis/arrow-left.png",
    overFile="img/uis/arrow-left-pressed.png",
    width= arrowWidth,
    height= arrowHeight,
    type= "left",
    onRelease = onLeft
  }
  leftArrow.x = -arrowWidth / 2
  -- leftArrow.y = container.height / 2 - arrowHeight

  local rightArrow = widget.newButton{
    defaultFile="img/uis/arrow-right.png",
    overFile="img/uis/arrow-right-pressed.png",
    width= arrowWidth,
    height= arrowHeight,
    type= "right",
    onRelease = onRight
  }
  rightArrow.x = arrowWidth / 2
  -- rightArrow.y = arrowHeight

  -- container:insert(leftArrow)
  -- container:insert(rightArrow)
  -- return container
end

function Render:appendCharToGrid(grid, char, x, y, onCharClick)
  local function onRelease(event)
    onCharClick(event, char)
  end

  local picture = widget.newButton{
    defaultFile = char.head,
    width = PICTURE_SIZE.width,
    height = PICTURE_SIZE.height,
    onRelease = onRelease
  }

  picture.anchorX = 0
  picture.anchorY = 0
  picture.x = x
  picture.y = y
  grid:insert(picture)
end

function Render:createCharsGrid(width, height, x, y, chars, onCharClick)
  local grid = display.newContainer(width, height)
  grid.anchorY = 0
  grid.anchorX = 0
  grid.x = x
  grid.y = y

  local size = 0
  local dims = {
    x = -grid.width / 2,
    maxX = grid.width / 2,
    y = -grid.height / 2
  }
  local x = dims.x
  local y = dims.y

  for key, value in pairs(chars)
  do
    self:appendCharToGrid(grid, value, x, y, onCharClick)
    x = x + PICTURE_SIZE.width
    if x >= dims.maxX - 20
    then
      x = dims.x
      y = y + PICTURE_SIZE.height
    end
  end

  return grid
end

function Render.setTopLeft(e)
  e.anchorX = 0
  e.anchorY = 0
  return e
end

function Render:infiniteBounce(container, y, time, delay)
  local function callback()
    if container.isBouncing == true then
      self:infiniteBounce(container, y, time)
    end
  end

  local function startTransition()
    transition.to(container, {
      transition = easing.continuousLoop,
      y = container.y + y,
      time = time,
      onComplete = callback
    })
  end

  container.isBouncing = true
  if delay ~= nil then
    timer.performWithDelay(delay, startTransition)
  else
    startTransition()
  end
end

function Render:unbounce(container)
  container.isBouncing = false
end

function Render:infiniteBouncePlayer(player, y, time)
  local c = player.container.head:getSprite()
  local function callback()
    if c.isBouncing == true then
      self:infiniteBouncePlayer(player, y, time)
    end
  end

  if c.isBouncing == nil then
    c.isBouncing = true
  end

  c:applyLinearImpulse(0.5, 0, c.x, c.y)
  timer.performWithDelay(1000, callback)
  -- transition.to(c, {
  --   transition = easing.continuousLoop,
  --   y = c.y + y,
  --   time = time,
  --   onComplete = callback
  -- })
end

function Render:unbouncePlayer(player)
  player.container.head:getSprite().isBouncing = false
end

function Render:basicScale(group, onEnd)
  group.xScale = 2.5
  group.yScale = 2.5
  group.y = display.contentCenterY - 25
  group.x = display.contentCenterX
  transition.scaleTo(group, {
    xScale = 0.2,
    yScale = 0.2,
    transition = easing.outInExpo,
    time = 800,
    onComplete = onEnd,
    onCancel = onEnd,
    onPause = onEnd
  })
end

function Render:charUi(char, width, height, offX, offY)
  local c = display.newContainer(width, height + 5)
  local top = display.newImageRect("img/uis/char-ui-top.png", width, height)
  local bot = display.newImageRect("img/uis/char-ui-bot.png", width, height)

  if offX == nil then offX = 10 end
  if offY == nil then offY = -5 end
  char.x = offX
  char.y = offY
  c:insert(top)
  c:insert(char)
  c:insert(bot)
  return c
end

function Render:unlockEffect(obj)
  obj.fill.effect = "filter.desaturate"
  obj.fill.effect.intensity = 1
end

function Render:txtShadow(font, fontSize, text, offset, x, y, r, g, b)
  local txt = display.newText{
    font = native.newFont(font, fontSize),
    text = text
  }
  txt:setFillColor(r, g, b)
  local shadow = display.newText{
    font = native.newFont(font, fontSize),
    text = text,
    x = offset,
    y = offset
  }

  local group = display.newGroup()

  group.x = x
  group.y = y

  shadow:setFillColor(0, 0, 0, 0.4)
  group:insert(shadow)
  group:insert(txt)
  return group, txt, shadow
end

function Render:txtStroke(font, fontSize, text, offset, x, y, r, g, b)
  local txt = display.newText{
    font = native.newFont(font, fontSize),
    text = text
  }
  txt:setFillColor(r, g, b)
  local shadow = display.newText{
    font = native.newFont(font, fontSize + offset),
    text = text
  }

  local group = display.newGroup()

  group.x = x
  group.y = y

  shadow:setFillColor(0, 0, 0, 1)
  group:insert(shadow)
  group:insert(txt)
  return group, txt, shadow
end

function Render:popFromBackground(btn, cb)
  transition.from(btn, {
    xScale = 0.1,
    yScale = 0.1,
    transition = easing.outBack,
    time = 200,
    onCancel = cb,
    onComplete = cb
  })
end

function Render:buyUi(points, index, width, height, onBuyClick)
  local group = display.newGroup(width, height)
  local margin = 10
  local line
  local buy = widget.newButton{
    defaultFile="img/uis/name-ui.png",
    label = points.price,
    fontSize = height / 4,
    font = native.newFont("font/Kroftsmann"),
    labelColor = { default={Colors:getColor("red")}, over={128} },
    width=width / 5,
    height=height - height / 1.8,
    onRelease = function(e)
      onBuyClick(points, e)
    end
  }
  local pointsTxt = display.newText{
    font = native.newFont('font/GROBOLD', 20),
    text = points.points .. " Foodz"
  }
  pointsTxt:setFillColor(Colors:getColor("red"))

  buy.y = 0
  pointsTxt.y = 0
  pointsTxt.x = pointsTxt.width / 2 + margin
  buy.x = width - buy.width / 2 - margin
  line = display.newLine(pointsTxt.x - pointsTxt.width / 2, height / 2, pointsTxt.x + pointsTxt.width / 2, height / 2)
  line:setStrokeColor(Colors:getColor("red"))
  group:insert(line)
  group:insert(buy)
  group:insert(pointsTxt)
  return group
end


function Render:selectionGroup(width, height, onHeadClick, onHandsClick, onShoesClick)
  local group = display.newContainer(width * 3, height)
  local headBtn = self:basicButton("img/uis/head-button-marged", onHeadClick, width, height)
  local handsBtn = self:basicButton("img/uis/hands-button-marged", onHandsClick, width, height)
  local shoesBtn = self:basicButton("img/uis/shoes-button-marged", onShoesClick, width, height)

  headBtn.x = -handsBtn.width
  handsBtn.x = 0
  shoesBtn.x = handsBtn.width
  headBtn.y = 0
  handsBtn.y = 0
  shoesBtn.y = 0
  group:insert(headBtn)
  group:insert(handsBtn)
  group:insert(shoesBtn)
  return group
end

function Render:cloneImg(name, img)
  local nimg = display.newImageRect(assets:asBig(name, "head"), img.width, img.height)

  nimg.x = img.x
  nimg.y = img.y
  return nimg
end

local function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function Render:rankLine(sceneGroup, rank, guy, r, index)
  local container = display.newContainer(rank.width, rank.height / 6)
  local img = display.newImageRect(assets:asBig(guy.name, "head"), container.height - 7, container.height - 7)
  local wimg = self:charUi(img,  (container.height - 5) * 1.35, container.height - 5, 5, -2)
  local points = display.newText{text = (r == 0 and 0 or round(guy.points / r * 100, 1)) .. "%", font = native.newFont("font/GROBOLD", 2.5 * container.height / 5)}
  local indexTxt = display.newText{text = index .. ".", font = native.newFont("font/GROBOLD", 2.5 * container.height / 5)}
  local bot = display.newLine(-container.width / 2, container.height / 2, container.width / 2, container.height / 2)

  indexTxt.x = -container.width / 2  + wimg.width / 2 - indexTxt.width / 2
  wimg.x = -container.width / 2  + wimg.width / 2 + indexTxt.width + 10
  points.x = 0 + container.width / 2 - points.width / 2 - 20

  bot.strokeWidth = 2
  bot:setStrokeColor(Colors:getColor("red"))
  if index == 1 then
    indexTxt:setFillColor(Colors:getColor("red"))
  elseif index == 2 or index == 3 then
    indexTxt:setFillColor(Colors:getColor("orange"))
  end
  container:insert(wimg)
  container:insert(points)
  container:insert(indexTxt)
  container:insert(bot)
  return container
end

function Render:basicPopup(sceneGroup, txtStr, width, height, clickListener)
  local group = display.newGroup()
  local bg = display.newImageRect("img/uis/popup.png", width, height)
  local txt = display.newText{
    font = native.newFont("font/Kroftsmann", 18),
    -- font = native.newFont("font/GROBOLD", 18),
    text = txtStr
  }
  txt:setFillColor(Colors:getColor("red"))
  local btn


  function onClick()
    bg:removeSelf()
    bg = nil

    txt:removeSelf()
    txt = nil

    btn:removeSelf()
    btn = nil
    group = nil

    if clickListener ~= nil then
      clickListener()
    end
  end

  btn = Render.createBasicUI{
  		label=Translator:translate("yes"),
      width=300 / 2.5, height=157 / 2.5,
  		onRelease = onClick
  	}

  group:insert(bg)
  txt.y = -txt.height / 2 - 30
  group:insert(txt)
  btn.x = 0
  group:insert(btn)
  group.x = display.contentCenterX
  group.y = display.contentCenterY
  sceneGroup:insert(group)
  self:popFromBackground(group)
  return group
end

function Render:confirmPopup(sceneGroup, txtStr, width, height, onSuccess)
  local group = display.newGroup()
  local bg = display.newImageRect("img/uis/popup.png", width, height)
  local txt = display.newText{
    font = native.newFont("font/Kroftsmann", 18),
    -- font = native.newFont("font/GROBOLD", 18),
    text = txtStr
  }
  txt:setFillColor(Colors:getColor("red"))
  local okBtn
  local koBtn


  function onKo()
    bg:removeSelf()
    bg = nil

    txt:removeSelf()
    txt = nil

    okBtn:removeSelf()
    okBtn = nil

    koBtn:removeSelf()
    koBtn = nil
    group = nil
  end

  function onOk()
    onKo()
    onSuccess()
  end

  okBtn = Render.createBasicUI{
  		label= Translator:translate("yes"),
      width=300 / 2.5, height=157 / 2.5,
  		onRelease = onOk
  	}
  koBtn = Render.createBasicUI{
    label=Translator:translate("no"),
    width=300 / 2.5, height=157 / 2.5,
  	onRelease = onKo
  	}

  group:insert(bg)
  txt.y = -txt.height / 2 - 30
  group:insert(txt)
  okBtn.x = width / 2 - okBtn.width / 2 - 30
  okBtn.y = height / 2 - okBtn.width / 2 - 5
  koBtn.x = -width / 2 + okBtn.width / 2 + 30
  koBtn.y = height / 2 - koBtn.width / 2 - 5
  group:insert(okBtn)
  group:insert(koBtn)
  group.x = display.contentCenterX
  group.y = display.contentCenterY
  sceneGroup:insert(group)
  self:popFromBackground(group)
  return group
end

function Render:addStars(y, x, lvl, sceneGroup, stars)
  local dim = 13
  local marginX = 2
  local star
  local i = 0
  local startX = x - 2.5 * (dim + marginX)

  if lvl == 0 then return stars end
  while i < math.floor(lvl / 2) do
    star = display.newImageRect("img/uis/star.png", dim, dim)
    star.y = y
    star.x = startX + i * (dim + marginX) + dim / 2
    sceneGroup:insert(star)
    stars[#stars + 1] = star
    i = i + 1
  end
  if lvl % 2 == 1 then
    star = display.newImageRect("img/uis/star-half.png", dim / 2, dim)
    star.y = y
    star.x = startX + i * (dim + marginX) + dim / 4
    sceneGroup:insert(star)
    stars[#stars + 1] = star
  end

  return stars
end

function Render:deleteStars(stars)
  for i = 1, #stars do
    stars[i]:removeSelf()
    stars[i] = nil
  end
  stars = {}
  return stars
end

function Render:particles()
  local pex = require( "libs.com.ponywolf.pex" )
  particleData = pex.load( "img/particles/particle.pex", "img/particles/texture.png" )
  emitter = display.newEmitter( particleData )
  emitter.x = display.contentCenterX
  emitter.y = display.contentCenterY

  return emitter
end

function Render:localization(spritePath)
  local group = display.newGroup()
  local loca = display.newImageRect("img/uis/localization-ui.png", 200  / 6, 238 / 6)
  local sprite = display.newImageRect(spritePath, 200 / 8, 200 / 8)

  sprite.y = sprite.height / 6
  group:insert(loca)
  group:insert(sprite)
  return group
end

function Render:setLocaPos(p1Pos, p2Pos, ballPos, locas)
  function checkCoords(pos, l)
    if pos.y < display.screenOriginY then
      l.isVisible = true
      l.x = pos.x
    else
      l.isVisible = false
    end
  end

  checkCoords(p1Pos, locas.p1)
  if p2Pos ~= nil then
    checkCoords(p2Pos, locas.p2)
  end
  checkCoords(ballPos, locas.ball)
end

function Render:textParticles(x, y, side, txt)
  return (TextParticles:new(x, y, side, txt))
end

function Render:fadeAndDestroy(wrapper, element)
  local tran

  tran = transition.to(element, {
    alpha = 0,
    time = 200,
    onComplete = function()
      wrapper:destroy()
    end
  })
  return tran
end
