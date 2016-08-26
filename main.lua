
newFont = nil
luigiScore = nil
player = {}
pissStream = {}
nearestPiss = {}
pissTank = nil
luigi = {}
map = {}
mouse = {}
state = 0
-- STATES:
-- 0 - Init
-- 1 - Intro
-- 2 - Gameplay
-- 3 - End game

-- Return the quad for a tileid
-- TODO: accept a tileset as a parm
function getQuad(map, tileId)
  -- Get the x index of the tile
  tileX = ((tileId % (map.tilesets[1].imagewidth/map.tilesets[1].tilewidth)) * map.tilesets[1].tilewidth) - map.tilesets[1].tilewidth
  -- get the y index of the tile
  tileY = ((math.floor(tileId / (map.tilesets[1].imagewidth/map.tilesets[1].tilewidth)) + 1) * map.tilesets[1].tilewidth) - map.tilesets[1].tilewidth
  return love.graphics.newQuad(tileX, tileY, map.tilesets[1].tilewidth, map.tilesets[1].tileheight, map.tilesets[1].imagewidth, map.tilesets[1].imageheight)
end -- getQuad()

-- fill a table with the tile quads in use
function getTiles(map)
  ids = {} -- list of all tileIds
  tileids = {} -- list of non-duplicate tileIds
  tiles = {} -- table of quads for each tileId
  hash = {} -- used for de-dup
  -- union all map data across layers
  n = 1
  for i=1, table.getn(map.layers) do
    for v in pairs(map.layers[i].data) do
      print(map.layers[i].data[v])
      ids[n] = map.layers[i].data[v]
      n = n+1
    end
  end
  -- get unique tileIDs
  for _,v in ipairs(ids) do
    if (not hash[v]) then
      tileids[#tileids+1] = v
      hash[v] = true
    end
  end
  -- create the table containing the quads
  for i=1, table.getn(tileids) do
    r = tileids[i]
    tiles[r] = getQuad(map, r)
  end
  -- return the table of quads
  return tiles
end -- getTiles()

function drawMap(map)
  -- iterate layers
  for n = 1, table.getn(map.file.layers) do
        row = 1
        column = 1
        -- for each data elemnt in the layer's table
        for l = 1, table.getn(map.file.layers[n].data) do
          -- goto the next row if we've passed the screen width and reset columns
          if column > map.file.layers[n].width then
            column = 1
            row = row + 1
          end
          -- draw the tile as long as it's not 0 (empty)
          if map.file.layers[n].data[l] ~= 0 then
            love.graphics.draw(map.atlas, map.tiles[map.file.layers[n].data[l]], (column * 32) - 32, (row * 32) - 32)
          end
          -- move to the next column
          column = column + 1
        end
    end
end -- drawMap()

function loadMap(path)
  -- Creates a map table with the following values:
  --  .file - a handle to the lua map file
  --  .atlas - the image to use asthe tilemap
  --  .tiles - a table indexed for each tileid
  -- load the map file
  map.file = love.filesystem.load(path)()
  -- load the atlas
  -- TODO: make this load each atlas per layer
  map.atlas = love.graphics.newImage('assets/atlas.png')
  -- load the tiles for the map
  map.tiles = getTiles(map.file)
  --return the map table
  return map
end --loadMap()

-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2)
  return ((x2-x1)^2+(y2-y1)^2)^0.5
end -- math.dist()

-- angle in degrees
function findRotation(x1,y1,x2,y2)
  local t = -math.deg(math.atan2(x2-x1,y2-y1))
  if t < 0 then t = t + 360 end;
  return t - 180;
end -- findRotation()

-- angle in radians
--function findAngle(x1, y1, x2, y2)
--  local t = -math.atan2(y2-y1, x2-x1)
--  if t < 0 then t = t + 6.28319 end;
--  return -t + 1.5708
--end -- findAngle()

function checkCircularCollision(ax, ay, bx, by, ar, br)
	local dx = bx - ax
	local dy = by - ay
	local dist = math.sqrt(dx * dx + dy * dy)
	return dist < ar + br
end -- checkCircularCollision()

function moveTowards(object, dt, toObject)
  --local angle = findRotation(object.x, object.y, toObject.x, toObject.y)
  local angle = math.atan2((toObject.y - object.y), (toObject.x - object.x))
  local dx = (math.cos(angle) * object.speed) * dt
  local dy = (math.sin(angle) * object.speed) * dt
  --print(angle..","..targetx..","..targety)

  -- update X coord
  if object.x >= (object.sprite:getWidth()/2)
  and object.x <= love.graphics.getWidth() - (object.sprite:getWidth()/2)
  and checkCircularCollision(object.x, object.y, toObject.x, toObject.y, object.radius, toObject.radius) ~= true then
    object.x = object.x + dx
  elseif object.x < (object.sprite:getWidth()/2) then
      object.x = (object.sprite:getWidth()/2)
  elseif object.x > love.graphics.getWidth() - (object.sprite:getWidth()/2) then
      object.x = object.x - 1
  end

  -- update y coord
  if object.y >= (object.sprite:getHeight()/2)
  and object.y <= love.graphics.getHeight() - (object.sprite:getHeight()/2)
  and checkCircularCollision(object.x, object.y, toObject.x, toObject.y, object.radius, toObject.radius) ~= true then
    object.y = object.y + dy
  elseif object.y < (object.sprite:getHeight()/2) then
      object.y = (object.sprite:getHeight()/2)
  elseif object.y > love.graphics.getHeight() - (object.sprite:getHeight()/2) then
      object.y = object.y - 1
  end
end -- moveTowards()

function love.load()
  newFont = love.graphics.newFont('assets/orange juice 2.0.ttf', 35)
  -- do my awesome map loading!
  map = loadMap("maps/map.lua")
  -- set up the player
  player.x, player.y, player.speed, player.radius = 100, 100, 150, 80
  player.peespeed, player.deceleration = 200, 25
  player.sprite = love.graphics.newImage('assets/doggo.png')
  player.arrow = love.graphics.newImage('assets/arrow.png')
  -- set up our boy
  luigi.x, luigi.y, luigi.speed, luigi.radius = 300, 300, 250, 10
  luigi.sprite = love.graphics.newImage('assets/luigi.png')
  -- set up piss
  nearestPiss.dist = 10000000
  nearestPiss.x = player.x
  nearestPiss.y = player.y
  nearestPiss.radius = 10

  -- set initial init parms
  pissTank = 1000
  luigiScore = 0

  love.mouse.setGrabbed(true)
end --love.load()

function love.update(dt)
  if love.keyboard.isScancodeDown('escape') then
    love.event.push('quit')
  end

  -- flip on the state machine
  -- initialising
  if state == 0 then
      -- set init parms
      pissTank = 1000
      luigiScore = 0
      state = 1
      player.x, player.y, player.speed, player.radius = 100, 100, 150, 80
      player.peespeed, player.deceleration = 200, 25
      luigi.x, luigi.y, luigi.speed, luigi.radius = 300, 300, 250, 10
      pissStream = {}
  -- Intro
  elseif state == 1 then
    -- do the intro stuff
    state = 2
  -- run the game
  elseif state == 2 then
    -- play the game
    if love.keyboard.isScancodeDown('left', 'a') then
      if player.x > (player.sprite:getWidth()/2) then
        player.x = player.x - (player.speed * dt)
      end
    elseif love.keyboard.isScancodeDown('right', 'd') then
      if player.x < love.graphics.getWidth() - (player.sprite:getWidth()/2) then
        player.x = player.x + (player.speed * dt)
      end
    end
    if love.keyboard.isScancodeDown('up', 'w') then
      if player.y > (player.sprite:getHeight()/2) then
        player.y = player.y - (player.speed * dt)
      end
    elseif love.keyboard.isScancodeDown('down', 's') then
      if player.y < love.graphics.getHeight() - (player.sprite:getHeight()/2) then
        player.y = player.y + (player.speed * dt)
      end

    end

    -- is we peeing?
    if love.mouse.isDown(1) then
        local startX = player.x
        local startY = player.y
        local mouseX = love.mouse.getX()
        local mouseY = love.mouse.getY()
        local angle = math.atan2((mouseY - startY), (mouseX - startX))
        local bulletDx = (player.peespeed - player.deceleration) * math.cos(angle)
        local bulletDy = (player.peespeed - player.deceleration) * math.sin(angle)
        table.insert(pissStream, {x = startX,
                                  y = startY,
                                  dx = bulletDx,
                                  dy = bulletDy,
                                  radius = 0})
        pissTank = pissTank - 1
    end

    -- update positions of piss
    for i,v in ipairs(pissStream) do
      v.x = v.x + (v.dx* dt)
      if v.x < -20 or v.x > love.graphics.getWidth() + 20 then
        table.remove(pissStream, i)
      elseif checkCircularCollision(luigi.x, luigi.y, v.x, v.y, luigi.radius, v.radius) then
        table.remove(pissStream, i)
        luigiScore = luigiScore + 1
      end
      v.y = v.y + (v.dy* dt)
      if v.y < -20 or v.y > love.graphics.getHeight() + 20 then
        table.remove(pissStream, i)
      end
    end



    -- update the mouse position
    mouse.x = love.mouse.getX()
    mouse.y = love.mouse.getY()

    -- find the closest pee
    nearestPiss.dist = 10000000
    if next(pissStream) ~= nil then
      for i, v in ipairs(pissStream) do
        local sd = math.dist(luigi.x, luigi.y, v.x, v.y)
        if sd < nearestPiss.dist then
            nearestPiss.dist = sd
            nearestPiss.x = v.x
            nearestPiss.y = v.y
            nearestPiss.radius = 0
        end
      end
    else
        nearestPiss.dist = sd
        nearestPiss.x = player.x
        nearestPiss.y = player.y
        nearestPiss.radius = player.radius
    end
    -- get our boy movin'
    moveTowards(luigi, dt, nearestPiss, player)

    -- end the game if we're out of piss
    if pissTank <= 0 then
      state = 3
    end
  elseif state == 3 then
    -- end game
    if love.keyboard.isScancodeDown('r') then
      state = 0
    end

  end
end --love.update()

function love.draw()
  --love.graphics.scale(1.5, 1.5)
  love.graphics.setFont(newFont)
  -- draw the map
  love.graphics.setColor(256, 256, 256)
  drawMap(map)
  -- draw piss
  love.graphics.setColor(244, 250, 60)
  for i,v in ipairs(pissStream) do
    love.graphics.circle("fill", v.x, v.y, 3)
  end
  love.graphics.setColor(256, 256, 256)
  -- draw the player
  love.graphics.draw(player.sprite, player.x, player.y, 0, 1, 1, player.sprite:getWidth()/2, player.sprite:getHeight()/2)
  love.graphics.draw(player.arrow, player.x, player.y, math.rad(findRotation(player.x, player.y, luigi.x, luigi.y)), 1, 1, player.arrow:getWidth()/2, player.arrow:getHeight()/2)

  -- draw our boy
  love.graphics.draw(luigi.sprite, luigi.x, luigi.y, 0, 1, 1, luigi.sprite:getWidth()/2, luigi.sprite:getHeight()/2)
  love.graphics.setColor(0, 0, 0)
  love.graphics.print('Units of pee left: '..pissTank, 10, 10)
  love.graphics.print('Luigi drank '..luigiScore..' laps of pee!', 10, 40)
  if state == 3 then
    love.graphics.setColor(10, 10, 10, 150)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(256, 256, 256)
    gameovertext = love.graphics.newText(newFont, 'Game Over!')
    love.graphics.printf('Game Over!\r\nLuigi drank '..luigiScore..' litres of piss!', 0, 200, love.graphics.getWidth(), 'center')
  end
  --love.graphics.print('Luigi is at '..luigi.x..' | '..luigi.y,10, 30)
end --love.draw()
