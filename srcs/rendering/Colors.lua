Colors = {}

function Colors:getColor(color)
  if color == "red" then return 0.8, 0.2, 0.2 end
  if color == "yellow" then return 1, 200 / 255, 63 / 255 end
  if color == "orange" then return 1, 170 / 255, 23 / 255 end
  if color == "white" then return 255, 255, 255 end
  if color == "green" then return 0.2, 0.8, 0.2 end
end
