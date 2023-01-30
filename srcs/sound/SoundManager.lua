SoundManager = {
  root = "sound/",
  ext = ".wav",
  sounds = {
    click = {
    path = "button/click"
    },
    buy = {
    path = "button/buy"
    },
    music = {
      path = "music",
      channel = nil
    },
    flip = {path="player/flip"},
    swish = {path="basket/swish"},
    board = {path="basket/board"},
    swing = {path="button/swing"},
    buzzer = {path="buzzer"},
    bounce = {path="bounce"},
    cry = {path="player/cry"},
    cheer = {path="crowd/cheer"},
    boo = {path="crowd/boo"},
    foot1 = {path="player/footstep0"},
    foot2 = {path="player/footstep1"},
    foot3 = {path="player/footstep1"}
},
  db = require("srcs.db.DB"),
  isSoundEnabled = true
}

function SoundManager:init()
  for k, v in pairs(self.sounds) do
    v.loaded = audio.loadSound(self.root .. v.path .. self.ext)
  end
  self.isSoundEnabled = self.db:getMusic()
end

function SoundManager:play(sound)
  if self.isSoundEnabled == false then return end
  self.sounds[sound].isPlaying = true
  return audio.play(self.sounds[sound].loaded, {
      onComplete = function()
        self.sounds[sound].isPlaying = false
      end
    })
end

function SoundManager:startBgMusic(forced)
  -- if self.isSoundEnabled == false and forced ~= true then return end
  -- self.sounds.music.channel = audio.play(self.sounds["music"].loaded, {
  --   loops = -1
  -- })
end

function SoundManager:hasBgMusic()
  return self.sounds.music.channel ~= nil
end

function SoundManager:stopBgMusic()
  -- if self.isSoundEnabled == false then return end
  -- self.sounds.music.channel = audio.pause(self.channel)
end

function SoundManager:resumeBgMusic(forced)
  -- if self.isSoundEnabled == false and forced ~= true then return end
  -- self.sounds.music.channel = audio.resume(self.channel)
end

function SoundManager:isPlaying(sound)
  return self.sounds[sound].isPlaying
end

function SoundManager:pause(channel)
  return audio.pause(channel)
end

function SoundManager:resume(channel)
  return audio.pause(channel)
end

function SoundManager:toggle()
  if (not self.isSoundEnabled) == false then
    self:stopBgMusic()
  elseif self:hasBgMusic() == true then
    self:resumeBgMusic(true)
  else
    self:startBgMusic(true)
  end
  self.isSoundEnabled = not self.isSoundEnabled
  self.db:setMusic(self.isSoundEnabled)
end

return SoundManager
