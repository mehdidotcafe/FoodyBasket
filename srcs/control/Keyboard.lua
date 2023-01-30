require "srcs.control.PressKey"
require "srcs.db.DB"

Keyboard = {
  addedListener = false,
  touches = {},
  db = DB:new(),
  globalListener = {},
  listener = nil
}

function Keyboard:init()
  local function onKeyEvent(event)

    if self.touches[event.keyName] ~= nil then
      self.touches[event.keyName]:onEvent(event)
    end
    for i = 1, #self.globalListener do
      self.globalListener[i].obj[self.globalListener[i].fx](event.keyName)
    end
    return false
  end

  self.listener = onKeyEvent
  if self.addedListener == false then
    Runtime:addEventListener("key", onKeyEvent)
    self.addedListener = true
  end
end

function Keyboard:addSubscriber(s, fx)
  self.globalListener[#self.globalListener + 1] = {}

  self.globalListener[#self.globalListener].obj = s
  self.globalListener[#self.globalListener].fx = fx
end

function Keyboard:create(touch, infos)
  self.touches[touch] = PressKey:new(infos)

  return self.touches[touch]
end

function Keyboard:destroy()
  for k, v in ipairs(self.touches) do
    v:destroy()
  end
  self.touches = {}
  self.globalListener = {}
  self.listener = nil
end
