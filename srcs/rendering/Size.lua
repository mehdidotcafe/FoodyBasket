local Size = {
  head = {
    width = 200,
    height = 200
  },
  shoes = {
    width = 170,
    height = 52
  },
  hands = {
    width = 100,
    height = 100
  },
  basket = {
    width = 420,
    height = 296
  },
  ball = {
    width = 539,
    height = 539
  },
  coeff = (200 / 40)
}

function Size:headBox(coeff)
  if coeff == nil then coeff = self.coeff end
  return math.floor(self.head.width / coeff), math.floor(self.head.height / coeff)
end

function Size:shoesBox(coeff)
  if coeff == nil then coeff = self.coeff end
  return math.floor(self.shoes.width / coeff), math.floor(self.shoes.height / coeff)
end

function Size:handsBox(coeff)
  if coeff == nil then coeff = self.coeff end
  return math.floor(self.hands.width / coeff), math.floor(self.hands.height / coeff)
end

return Size
