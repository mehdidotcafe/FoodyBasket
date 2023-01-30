DB = {
  path = "foody-basket-db.db",
  hasSub = false,
  sq = require("sqlite3"),
  db = nil
}

function DB:new()
  local npath
  local function onSystemEvent(event)
    if (event.type == "applicationExit") then
      self.db:close()
    end
  end

  npath = system.pathForFile(self.path, system.DocumentsDirectory)

  self.db = self.sq.open(npath)

  if self.hasSub == false then
    Runtime:addEventListener("system", onSystemEvent)
    self.hasSub = true
  end

  local tablesetup = [[CREATE TABLE IF NOT EXISTS chars (id INTEGER PRIMARY KEY, name);
                       CREATE TABLE IF NOT EXISTS shoes (id INTEGER PRIMARY KEY, name);
                       CREATE TABLE IF NOT EXISTS hands (id INTEGER PRIMARY KEY, name);
                       CREATE TABLE IF NOT EXISTS points (id INTEGER PRIMARY KEY, points);
                       CREATE TABLE IF NOT EXISTS music (id INTEGER PRIMARY KEY, enabled);
                       CREATE TABLE IF NOT EXISTS league (id INTEGER PRIMARY KEY, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11, player12, round);
                       CREATE TABLE IF NOT EXISTS arenaScore (id INTEGER PRIMARY KEY, score, name);
                       CREATE TABLE IF NOT EXISTS buttons (id INTEGER PRIMARY KEY, button, name);]]
  self.db:exec(tablesetup)

  if self:getPoints() == -1 then
    self.db:exec("INSERT INTO points VALUES (NULL, 0);")
  end
  if self:getArenaScore() == -1 then
    self:createArenaScore()
  end
  if self:getMusic() == nil then
    self:createMusic()
  end
  if self:getLeague() == nil then
    self:createLeague()
  end
  return self
end

function DB:exec(query)
  self.db:exec(query)
end

function DB:getLeague()
  for row in self.db:nrows("SELECT * FROM league") do
    return (row)
  end
  return nil
end

function DB:createLeagueSchema()
  return self.db:exec("CREATE TABLE league (id INTEGER PRIMARY KEY, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11, player12, round);")
end

function DB:dropLeague()
  return self.db:exec("DROP TABLE league")
end

function DB:createLeague()
  self.db:exec("INSERT INTO league VALUES (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);")
end

function DB:resetLeague()
  local str = "UPDATE league SET "
  for i = 1, 12 do
    str = str .. " player" .. i .. "=NULL,"
  end
  str = str .. "round = NULL"
  str = str .. " WHERE id=1;"
  self.db:exec(str)
end


function DB:setLeague(guys, round)
  local str = "UPDATE league SET "
  for i = 1, #guys do
    str = str .. " player" .. i .. "='" .. guys[i] .. "',"
  end
  str = str .. "round = " .. round
  str = str .. " WHERE id=1;"
  self.db:exec(str)
end

function DB:getPoints()
  for row in self.db:nrows("SELECT * FROM points") do
    return (row.points)
  end
  return (-1)
end

function DB:setPoints(points)
  self.db:exec("UPDATE points SET points=" .. points .. " WHERE id=1;")
end

function DB:createPoints(points)
  self.db:exec("INSERT INTO points VALUES (NULL, " .. points ..");")
end

function DB:getArenaScore()
  for row in self.db:nrows("SELECT * FROM arenaScore") do
    return ({score = row.score, name = row.name})
  end
  return (-1)
end

function DB:setArenaScore(score, name)
  self.db:exec("UPDATE arenaScore SET score = " .. score .. ", name ='" .. name .. "' WHERE id=1;")
end

function DB:createArenaScore()
  self.db:exec("INSERT INTO arenaScore VALUES (NULL, NULL, NULL);")
end

function DB:getUnlockedCollection(collection, fx)
  local iterations = 0

  for row in self.db:nrows("SELECT * FROM " .. collection) do
    iterations = iterations + 1
    if fx ~= nil then
      fx(row)
    end
  end
  return (iterations)
end

function DB:unlockChar(charName)
  self.db:exec("INSERT INTO chars VALUES (NULL, '" .. charName .."');")
end


function DB:unlockShoes(shoesName)
  self.db:exec("INSERT INTO shoes VALUES (NULL, '" .. shoesName .."');")
end

function DB:unlockHands(handsName)
  self.db:exec("INSERT INTO hands VALUES (NULL, '" .. handsName .."');")
end

function DB:createMusic()
  self.db:exec("INSERT INTO music VALUES (NULL, 1);")
end

function DB:setMusic(enabled)
  self.db:exec("UPDATE music SET enabled=" .. (enabled and 1 or 0) .. " WHERE id=1;")
end

function DB:getMusic()
  for row in self.db:nrows("SELECT * FROM music") do
    return (row.enabled == 1 and true or false)
  end
  return nil
end

return DB
