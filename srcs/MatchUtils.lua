MatchUtils = {}

function MatchUtils.setDunkIconVisibility(player, container, canDunk)
  if canDunk == nil then canDunk = player:canDunk() end

  container.dunkImg.isVisible = canDunk
end

function MatchUtils.createPlayers(opts1, opts2)
  local params = {
    player1 = nil,
    player2 = nil
  }

  if opts1 ~= nil then
    params.player1 = {
      head = opts1.player:getHeadPath(),
      hands = opts1.player:getHandsPath(),
      shoes = opts1.player:getShoesPath(),
      stats = opts1.player:getStats(),
      name = opts1.player.name,
      lvl = opts1.player.lvl,
      from =  opts1.from,
      control = opts1.control
    }
  end
  if opts2 ~= nil then
    params.player2 = {
      head = opts2.player:getHeadPath(),
      hands = opts2.player:getHandsPath(),
      shoes = opts2.player:getShoesPath(),
      stats = opts2.player:getStats(),
      name = opts2.player.name,
      lvl = opts2.player.lvl,
      from =  opts2.from,
      control = opts2.control
    }
  end
  return params
end

return MatchUtils
