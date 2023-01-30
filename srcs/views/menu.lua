-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

require "srcs.rendering.Render"
require "srcs.rendering.buttons.Dropdown"
require "srcs.rendering.buttons.FoodzContainer"
require "srcs.System"
require "srcs.Translator"
local composer = require( "composer" )
local pm = require("srcs.PurchaseManager")
local sm = require "srcs.sound.SoundManager"
local scene = composer.newScene()
scene.buttonEnabled = false

-- include Corona's "widget" library
local widget = require "widget"

system.activate( "multitouch" )

--------------------------------------------

-- forward declarations and other locals
local playBtn
local arenaBtn
local leagueBtn
local quitBtn = nil
local infoBtn
local keyBtn
local soundBtn
local unsoundBtn
local foodzContainer
local char
local char2
local titleLogo
local dd

local function onMatchBtnRelease()
	if scene.buttonEnabled ~= true then return end

	composer.gotoScene( "srcs.views.select-menu", {
		effect = "fade",
		time = 200,
		params = {
			to = "srcs.views.match",
			nbChars = 2
		}
	})

	return true
end

local function onArenaBtnRelease()
	if scene.buttonEnabled ~= true then return end

	composer.gotoScene( "srcs.views.select-menu", {
		effect = "fade",
		time = 200,
		params = {
			to = "srcs.views.arena",
			nbChars = 1
		}
	})

	return true
end

local function onLeagueBtnRelease()
	if scene.buttonEnabled ~= true then return end
	local currLeague = pm.db:getLeague()

	if currLeague == nil or currLeague.player1 == nil then
		composer.gotoScene( "srcs.views.select-menu", {
			effect = "fade",
			time = 200,
			params = {
				to = "srcs.views.league",
				nbChars = 1
			}
		})
	else
		composer.gotoScene( "srcs.views.league", {
			effect = "fade",
			time = 200,
			params = {
				league = currLeague
			}
		})
	end

	return true
end

function scene:create( event )
	local sceneGroup = self.view
	local toPrint = {}

	-- Called when the scene's view does not exist.
	--
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	-- display a background image
	local background = display.newImageRect("assets/courts/tribune-first.png", display.actualContentWidth, display.actualContentHeight )
	background.y =  display.contentCenterY
	background.x = display.contentCenterX

	local size = 175
	char = display.newImageRect("img/uis/full-kebaby.png", size, size)
	char.y =  display.contentCenterY + 10
	char.x = display.actualContentWidth * 3.5 / 6
	char2 = display.newImageRect("img/uis/full-tacosy.png", size, size)
	char2.y =  char.y
	char2.x = char.x + 125

	titleLogo = display.newImageRect("img/foody-logo.png", 100, 100)
	titleLogo.x = display.contentCenterX
	titleLogo.y = titleLogo.height / 2 + 10

	-- create a widget button (which will loads level1.lua on release)
	playBtn = Render.createBasicUI{
		label= Translator:translate("match"),
		width=300 / 2.3, height=157 / 2.3,
		onRelease = onMatchBtnRelease
	}
	toPrint[#toPrint + 1] = playBtn


	arenaBtn = Render.createBasicUI{
		label=Translator:translate("arena"),
		width=300 / 2.3, height=157 / 2.3,
		onRelease = onArenaBtnRelease
	}
	toPrint[#toPrint + 1] = arenaBtn

	leagueBtn = Render.createBasicUI{
		label=Translator:translate("league"),
		width=300 / 2.3, height=157 / 2.3,
		onRelease = onLeagueBtnRelease
	}
	toPrint[#toPrint + 1] = leagueBtn

	if System.isMobile() == false then
		quitBtn = Render.createBasicUI{
			label=Translator:translate("quit"),
			width=300 / 2.3, height=157 / 2.3,
			onRelease = function()
				if scene.buttonEnabled ~= true then return end
				native.requestExit()
			end
		}
		toPrint[#toPrint + 1] = quitBtn
	end


	soundBtn = Render:basicButton("img/uis/sound-button", function(e)
		soundBtn.isVisible = false
		unsoundBtn.isVisible = true

		sm:toggle()
		return true
	end, 25, 27)

	unsoundBtn = Render:basicButton("img/uis/unsound-button", function(e)
		soundBtn.isVisible = true
		unsoundBtn.isVisible = false

		sm:toggle()
		return true
	end, 25, 27)

	if sm.isSoundEnabled == true then unsoundBtn.isVisible = false
	else soundBtn.isVisible = true end

	infoBtn = Render:basicButton("img/uis/info-button", function(e)
		return true
	end, 25, 27)
	infoBtn.isVisible = false

	if System.isMobile() == false then
		keyBtn = Render:basicButton("img/uis/keyboard-button", function(e)
			composer.gotoScene( "srcs.views.keyboard-config", {
				effect = "fade",
				time = 200
			})
			return true
		end, 25, 27)
	end


	dd = Dropdown:new({path = "img/uis/settings-button", width = 40, height = 43}, {path = "img/uis/dropdown", width = 45, height = 150}, {y = display.screenOriginY + display.actualContentHeight - 90, x = display.screenOriginX + display.actualContentWidth - 40})

	foodzContainer = FoodzContainer:new(550 / 4.5, 185 / 4.5, true)
	foodzContainer.group.x = dd.container.x - dd.button.width - foodzContainer.group.width / 2
	foodzContainer.group.y = dd.container.y + dd.container.height / 2 - foodzContainer.group.height / 2

	local marginX = 40
	local marginY = 75

	for i = 1, #toPrint do
		toPrint[i].x = display.screenOriginX + display.contentCenterX / 4 + (i - #toPrint / 2 ) * marginX + toPrint[i].width / 2
		toPrint[i].y = display.contentCenterY + (i - #toPrint / 2 ) * marginY - toPrint[i].height / 2
		sceneGroup:insert(toPrint[i])
	end


	-- all display objects must be inserted into group
	sceneGroup:insert( background )
	sceneGroup:insert(char2)
	sceneGroup:insert(char)
	sceneGroup:insert( titleLogo )
	sceneGroup:insert( playBtn )
	sceneGroup:insert( arenaBtn )
	sceneGroup:insert( leagueBtn )
	if quitBtn ~= nil then
		sceneGroup:insert( quitBtn )
	end
	foodzContainer:insertToContainer(sceneGroup)
	dd:insertToContainer(sceneGroup)
	dd:addButton(soundBtn)
	dd:addButton(unsoundBtn)
	if System.isMobile() == false then
		dd:addButton(infoBtn, 1)
		dd:addButton(keyBtn, 2)
	else
		dd:addButton(infoBtn, 1.5)
	end
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		foodzContainer:setPoints(pm.points)
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		Render:infiniteBounce(playBtn, 3, 1000)
		Render:infiniteBounce(arenaBtn, 3, 1000, 50)
		Render:infiniteBounce(leagueBtn, 3, 1000, 130)
		if quitBtn ~= nil then
			Render:infiniteBounce(quitBtn, 3, 1000, 152)
		end
		if sm:hasBgMusic() == true then
			sm:resumeBgMusic()
		else
			sm:startBgMusic()
		end
		-- Called when the scene is now on screen
		--
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		scene.buttonEnabled = true
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if event.phase == "will" then
		scene.buttonEnabled = false
		Render:unbounce(playBtn)
		Render:unbounce(arenaBtn)
		Render:unbounce(leagueBtn)
		if quitBtn ~= nil then
			Render:unbounce(quitBtn)
		end
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end
end

function scene:destroy( event )
	local sceneGroup = self.view

	-- Called prior to the removal of scene's "view" (sceneGroup)
	--
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.

		playBtn:removeSelf()	-- widgets must be manually removed
		playBtn = nil

		arenaBtn:removeSelf()	-- widgets must be manually removed
		arenaBtn = nil

		leagueBtn:removeSelf()
		leagueBtn = nil

		if quitBtn ~= nil then
			quitBtn:removeSelf()
			quitBtn = nil
		end

		char:removeSelf()
		char = nil

		char2:removeSelf()
		char2 = nil

		foodzContainer:destroy()
		foodzContainer = nil

		soundBtn:removeSelf()
		soundBtn = nil

		unsoundBtn:removeSelf()
		unsoundBtn = nil

		titleLogo:removeSelf()
		titleLogo = nil

		dd:destroy()
		dd = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene
