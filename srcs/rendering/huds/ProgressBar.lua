ProgressBar = {
  container = nil,
  bgRect = nil,
  bgImg = nil,
  filledRect = nil,
  width = 0,
  height = 0
}

function ProgressBar:new(table)
  local _self = {}
  local decX = table.width / 5

  setmetatable(_self, self)
  self.__index = self

  _self.width = table.width - decX - table.width / 60
  _self.height = table.height
  _self.container = display.newGroup(table.width, table.height)
  if table.x ~= nil then
    _self.container.x = table.x
  end
  if table.y ~= nil then
    _self.container.y = table.y
  end
  if table.bgRectColors ~= nil then
    _self.bgRect = display.newRoundedRect(_self.container, -table.width / 2 + decX ,table.height / 25, _self.width, table.height - table.height / 2.2, 5)
    _self.bgRect.anchorX = 0
    -- _self.bgRect.alpha = 0.7
    _self.bgRect:setFillColor(unpack(table.bgRectColors))
  end
  _self.filledRect = display.newRoundedRect(_self.container, -table.width / 2 + decX ,table.height / 25, 0, table.height - table.height / 2.2, 5)
  _self.filledRect.anchorX = 0
  if table.backgroundImg ~= nil then
    _self.bgImg = display.newImageRect(_self.container, "img/uis/shoot-container.png", table.width, table.height)
  end
  if table.filledRectColors ~= nil then
    _self.filledRect:setFillColor(unpack(table.filledRectColors))
  end
  return _self
end

function ProgressBar:setProgress(p)
  self.filledRect.width = p * self.width
end

function ProgressBar:insertToContainer(c)
  c:insert(self.container)
end

function ProgressBar:destroy()
  self.container:removeSelf()
  self.bgRect:removeSelf()
  self.filledRect:removeSelf()

  self.container = nil
  self.bgRect = nil
  self.filledRect = nil
end

function ProgressBar:setFillColor(colors)
  self.filledRect:setFillColor(unpack(colors))
end
