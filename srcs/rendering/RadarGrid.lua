require "srcs.rendering.Colors"

RadarGrid = {
  nb = 0,
  width = 0,
  height = 0,
  width = 0,
  _height = 0,
  _container = nil,
  lines = nil,
  bg = nil,
  txt = nil
}

function RadarGrid:new(background, nb, width, height, innerOff, textStr)
  local _self = {}

  setmetatable(_self, self)
  self.__index = self
  _self.lines = {}
  _self.nb = nb
  _self.width = width
  _self.height = height
  _self._width = (width - (innerOff * width / 100)) / 2
  _self._height = (height - (innerOff * height / 100)) / 2
  _self.txt = {}

  _self.container = display.newGroup()
  if background ~= nil then
    _self.background = display.newImageRect(background, width, height)
    _self.container:insert(_self.background)
  end

  for i = 1, #textStr do
    _self.txt[i] = display.newText{
      text = textStr[i],
      font = native.newFont("font/GROBOLD", height / 9),
    }
    _self.container:insert(_self.txt[i])
  end
  return _self
end

function RadarGrid:drawTxt()
  local pos = {
    {x = self.width / 2 + 5, y = self.height / 15},
    {x = self.width / 5 + 5, y = -self.height / 2},
    {x = -self.width / 5 - 5, y = -self.height / 2 + 10},
    {x = -self.width / 5 - 5, y = self.height / 2 - 10},
    {x = self.width / 5 + 5, y = self.height / 2},
  }

  for i = 1, #self.txt do
    self.txt[i].x = pos[i].x - self.txt[i].width / 2
    self.txt[i].y = pos[i].y
    self.container:insert(self.txt[i])
  end
end

function RadarGrid:draw(values)
  local dist = 360 / self.nb
  local currOff = 0
  local linePos = {
    x = 0,
    y = 0
  }
  local x
  local y
  local line

  local function drawLine(idx)
    if idx > #values then
      idx = 1
    end
    x = (math.cos(math.rad(currOff)) * self._width * values[idx] * 10) / 100
    y = -(math.sin(math.rad(currOff)) * self._height  * values[idx] * 10) / 100
    self.lines[#self.lines + 1] = display.newLine(self.container, linePos.x, linePos.y, x, y)
    self.lines[#self.lines].strokeWidth = 1
    self.lines[#self.lines]:setStrokeColor(Colors:getColor("red"))
    linePos.x = x
    linePos.y = y
  end

  self:destroyLines()
  linePos.x = (math.cos(math.rad(0)) * self._width * values[1] * 10) / 100
  linePos.y = -(math.sin(math.rad(0)) * self._height  * values[1] * 10) / 100
  for i = 1, self.nb do
    drawLine(i)
    currOff = currOff + dist
  end
  drawLine(self.nb + 1)
  self:drawTxt()
  return self.container
end

function RadarGrid:destroyLines()
  for k, v in ipairs(self.lines) do
    v:removeSelf()
    v = nil
  end
  self.lines = {}
end

function RadarGrid:destroy()
  self:destroyLines()
  self.background:removeSelf()
  self.background = nil
  self.container:removeSelf()
  self.container = nil
end
