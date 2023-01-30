local assets = {
  extension = ".png",
  bigSuffix = "-big",
  globalPath = "assets/",
  leftPath = "assets/hands/left/",
  charsPath = "assets/heads/",
  chars = {
    { name = "kebaby", price = 0, stats = {5, 5, 5, 5, 5} },
    { name = "burgy", price = 0, stats = {3, 7, 4, 6, 5} },
    { name = "tacosy", price = 15000, stats = {7, 3, 6, 2, 7} },
    { name = "sushy", price = 15000, stats = {9, 2, 4, 6, 4} },
    { name = "pizzy", price = 15000, stats = {2, 5, 4, 8, 6} },
    { name = "bagely", price = 15000, stats = {5, 5, 5, 8, 2} },
    { name = "frity", price = 15000, stats = {2, 9, 4, 5, 5} },
    { name = "wingy", price = 15000, stats = {5, 2, 5, 4, 9} },
    { name = "hotdogy", price = 15000, stats = {4, 7, 3, 5, 6} },
    { name = "nuggy", price = 15000, stats = {3, 3, 9, 4, 6} },
    { name = "croquy", price = 15000, stats = {8, 5, 6, 2, 4} },
    { name = "fishy", price = 15000, stats = {4, 6, 6, 5, 4} },
    { name = "burshy", price = 15000, stats = {2, 9, 2, 9, 3} },
    { name = "burfly", price = 15000, stats = {7, 4, 5, 3, 6} },
    { name = "onigiry", price = 15000, stats = {4, 3, 6, 5, 7} },
    { name = "falafely", price = 1, stats = {5, 5, 5, 5, 5} }
  },
  hands = {
    { name = "basic", price = 0, stats = {0, 0, 0, 0, 0} },
    { name = "crab", price = 10000, stats = {1, -1, 1, 0, 0} },
    { name = "punch", price = 10000, stats = {3, 0, 0, -1, -1} },
    { name = "mouse", price = 10000, stats = {-1, 1, -2, 0, 3} },
    { name = "like", price = 10000, stats = {-1, 1, -2, 2, 1}}
  },
  shoes = {
    { name = "basic", price = 0, stats = {0, 0, 0, 0, 0} },
    { name = "basic green", price = 0, stats = {0, 0, 0, 0, 0}  },
    { name = "airmax", price = 10000, stats = {0, 0, -1, 2, 0}  },
    { name = "mexicano", price = 10000, stats = {-1, 1, 0, 0, 1}  },
    { name = "heel", price = 10000, stats = {-1, 0, 3, -1, 0}  },
    { name = "sneakers", price = 10000, stats = {1, -1, 1, -1, 1}  },
  }
}

function assets:charAsBig(name)
  return self.charsPath .. string.lower(name) .. self.bigSuffix .. self.extension
end

function assets:asBig(name, type)
  if type ~= "head" and type ~= "ball" then
    return self.globalPath .. type .. 's/'.. string.lower(name) .. self.bigSuffix .. self.extension
  else
    return self.globalPath .. type .. 's/'.. string.lower(name) .. self.extension
  end
end

function assets:fromName(name, type)
  type = type .. "s/"
  return self.globalPath .. type .. string.lower(name) .. self.extension
end

function assets:charFromName(name)
  return self.charsPath .. string.lower(name) .. self.extension
end

function assets:leftFromName(name)
  return self.leftPath .. string.lower(name) .. self.extension
end

function assets:rightFromName(name)
  return self.rightPath .. string.lower(name) .. self.extension
end

function assets:getHead(name)
  for k, v in pairs(self.chars) do
    if v.name == name then
      return v
    end
  end
  return nil
end

function assets:getHands(name)
  for k, v in pairs(self.hands) do
    if v.name == name then
      return v
    end
  end
  return nil
end

function assets:getShoes(name)
  for k, v in pairs(self.shoes) do
    if v.name == name then
      return v
    end
  end
  return nil
end

return assets
