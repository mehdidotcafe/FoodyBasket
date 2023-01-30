require "srcs.rendering.Render"

Dropdown = {
  button = nil,
  dropdown = nil,
  dropdownGroup = nil,
  container = nil,
  overflowGroup = nil,
  overflowButtons = nil
}

function Dropdown:new(buttonsOpts, dropdownOpts, pos)
  local _self = {}

  local trans
  local isVisible = 2

  local function onClick()
    isVisible = (isVisible == 1 and 2 or 1)
    transition.to(_self.dropdownGroup, {
      y = trans[isVisible],
      time = 100
    })
  end

  setmetatable(_self, self)
  self.__index = self


  _self.container = display.newContainer(math.max(buttonsOpts.width, dropdownOpts.width), buttonsOpts.height / 2 + dropdownOpts.height)

  _self.overflowGroup = display.newContainer(dropdownOpts.width, dropdownOpts.height - 10)
  _self.overflowGroup.y = -5
  _self.overflowButtons = {}

  _self.button = Render:basicButton(buttonsOpts.path, onClick, buttonsOpts.width, buttonsOpts.height)
  _self.button.y = _self.container.height / 2 - _self.button.height / 2
  _self.button.x = 0
  _self.dropdownGroup = display.newGroup()
  _self.dropdown = display.newImageRect(dropdownOpts.path .. ".png", dropdownOpts.width, dropdownOpts.height)
  trans = {_self.dropdown.height / 2 - _self.dropdown.height / 3, _self.dropdown.height / 2 + _self.dropdown.height}
  _self.dropdownGroup.y = trans[isVisible]
  _self.dropdownGroup:insert(_self.dropdown)
  _self.overflowGroup:insert(_self.dropdownGroup)
  _self.container:insert(_self.overflowGroup)
  _self.container:insert(_self.button)

  _self.container.x = pos.x
  _self.container.y = pos.y
  return _self
end

function Dropdown:addButton(btn, decY)
  if decY == nil then decY = 0 end
  self.overflowButtons[#self.overflowButtons + 1] = btn
  btn.y = 8 - decY * (25 + 4)
  btn.x = 0
  self.dropdownGroup:insert(btn)
end

function Dropdown:insertToContainer(c)
  c:insert(self.container)
end

function Dropdown:destroy()
  self.button:removeSelf()
  self.button = nil

  self.dropdown:removeSelf()
  self.dropdown = nil

  self.container:removeSelf()
  self.container = nil

  self.dropdownGroup:removeSelf()
  self.dropdownGroup = nil

  self.overflowGroup:removeSelf()
  self.overflowGroup = nil

  self.overflowButtons = nil
end
