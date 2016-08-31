local anim8 = require 'anim8'
local HC = require 'HC'
newFont = nil
luigiScore = nil
player = {}
pissStream = {}
nearestPiss = {}
pissTankMax = nil
pissTank = nil
collisionTiles = {}
luigi = {}
map = {}
screen = {}
state = 0
-- STATES:
-- 0 - Init
-- 1 - Intro
-- 2 - Gameplay
-- 3 - End game

-- troubleshooting text
text = ''

-- Return the quad for a tileid
-- TODO: accept a tileset as a parm
function getQuad(map, tileId)
  -- Get the x index of the tile
  tileX = (((tileId -1) % (map.tilesets[1].imagewidth/map.tilesets[1].tilewidth)) * map.tilesets[1].tilewidth)
  -- get the y index of the tile
  tileY = ((math.floor((tileId - 1) / (map.tilesets[1].imagewidth/map.tilesets[1].tilewidth))) * map.tilesets[1].tilewidth)
  return love.graphics.newQuad(tileX, tileY, map.tilesets[1].tilewidth, map.tilesets[1].tileheight, map.tilesets[1].imagewidth, map.tilesets[1].imageheight)
end -- getQuad()

-- fill a table with the tile quads in use
function getTiles(map)
  local ids = {} -- list of all tileIds
  local tileids = {} -- list of non-duplicate tileIds
  local tiles = {} -- table of quads for each tileId
  local hash = {} -- used for de-dup
  -- union all map data across layers
  local n = 1
  for i=1, table.getn(map.layers) do
    for v in pairs(map.layers[i].data) do
      --print(map.layers[i].data[v])
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

function createBlockingTiles(map, collider)
  local collisionTileTable = {}
  local blockinglayer = nil
  local row = 1
  local column = 1

  for i=1, table.getn(map.file.layers) do
    if map.file.layers[i].name == 'blocking' then
      -- find the blocking layer
      blockinglayer = i
    end
  end

  for i=1, table.getn(map.file.layers[blockinglayer].data) do
    --text = text..' Blocking tile value is '..map.file.layers[blockinglayer].data[i]
    if column > map.file.layers[blockinglayer].width then
      column = 1
      row = row + 1
    end
    if map.file.layers[blockinglayer].data[i] ~= 0 then
      table.insert(collisionTileTable, collider:rectangle((column * map.file.tilewidth) - map.file.tilewidth,
        (row * map.file.tileheight) - map.file.tileheight, map.file.tilewidth, map.file.tileheight))
    end
    column = column + 1
  end
  --collider:rectangle(0, 0, 32, 32)
  return collisionTileTable
end -- createBlockingTiles()

function drawMap(map)
  -- iterate layers
  for n = 1, table.getn(map.file.layers) do
        local row = 1
        local column = 1
        -- for each data elemnt in the layer's table
        for l = 1, table.getn(map.file.layers[n].data) do
          -- goto the next row if we've passed the screen width and reset columns
          if column > map.file.layers[n].width then
            column = 1
            row = row + 1
          end
          -- draw the tile as long as it's not 0 (empty)
          if map.file.layers[n].data[l] ~= 0 then
            love.graphics.draw(map.atlas, map.tiles[map.file.layers[n].data[l]],
              (column * map.file.tileheight) - map.file.tileheight, (row * map.file.tilewidth) - map.file.tilewidth)
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
  and object.x <= (map.file.width * map.file.tilewidth) - (object.sprite:getWidth()/2)
  and checkCircularCollision(object.x, object.y, toObject.x, toObject.y, object.radius, toObject.radius) ~= true then
    object.x = object.x + dx
  elseif object.x < (object.sprite:getWidth()/2) then
      object.x = (object.sprite:getWidth()/2)
  elseif object.x > (map.file.width * map.file.tilewidth) - (object.sprite:getWidth()/2) then
      object.x = object.x - 1
  end

  -- update y coord
  if object.y >= (object.sprite:getHeight()/2)
  and object.y <= (map.file.height * map.file.tileheight) - (object.sprite:getHeight()/2)
  and checkCircularCollision(object.x, object.y, toObject.x, toObject.y, object.radius, toObject.radius) ~= true then
    object.y = object.y + dy
  elseif object.y < (object.sprite:getHeight()/2) then
      object.y = (object.sprite:getHeight()/2)
  elseif object.y > (map.file.height * map.file.tileheight) - (object.sprite:getHeight()/2) then
      object.y = object.y - 1
  end
end -- moveTowards()

function love.load()
  newFont = love.graphics.newFont('assets/orange juice 2.0.ttf', 35)
  collider = HC.new(150)
  -- do my awesome map loading!
  map = loadMap("maps/map2.lua")
  collisionTiles = createBlockingTiles(map, collider)

  -- set up the player
  player.x, player.y, player.speed, player.radius = 100, 100, 150, 80
  player.peespeed, player.deceleration = 200, 25
  player.sprite = love.graphics.newImage('assets/penny2.png')
  player.arrow = love.graphics.newImage('assets/arrow.png')
  player.grid = anim8.newGrid(64, 64, player.sprite:getWidth(), player.sprite:getHeight())
  player.bbox = collider:rectangle(player.x - (player.grid.frameWidth/2), player.y - (player.grid.frameHeight/2), player.grid.frameWidth, player.grid.frameHeight)
  player.direction = 0
  -- Direction key
  --  3  4  5
  --  2  *  6
  --  1  0  7
  --player animations
  player.anIDown = anim8.newAnimation(player.grid('1-4', 1), 0.2)
  player.anMDown = anim8.newAnimation(player.grid('5-8', 3), 0.2)
  player.anIDownLeft = anim8.newAnimation(player.grid('1-4', 3), 0.2)
  player.anMDownLeft = anim8.newAnimation(player.grid('5-8', 5), 0.2)
  player.anILeft = anim8.newAnimation(player.grid('1-4', 2), 0.2)
  player.anMLeft = anim8.newAnimation(player.grid('5-8', 4), 0.2)
  player.anIUpLeft = anim8.newAnimation(player.grid('5-8', 2), 0.2)
  player.anMUpLeft = anim8.newAnimation(player.grid('1-4', 5), 0.2)
  player.anIUp = anim8.newAnimation(player.grid('5-8', 1), 0.2)
  player.anMUp = anim8.newAnimation(player.grid('1-4', 4), 0.2)
  player.anIUpRight = anim8.newAnimation(player.grid('5-8', 2), 0.2):flipH()
  player.anMUpRight = anim8.newAnimation(player.grid('1-4', 5), 0.2):flipH()
  player.anIRight = anim8.newAnimation(player.grid('1-4', 2), 0.2):flipH()
  player.anMRight = anim8.newAnimation(player.grid('5-8', 4), 0.2):flipH()
  player.anIDownRight = anim8.newAnimation(player.grid('1-4', 3), 0.2):flipH()
  player.anMDownRight = anim8.newAnimation(player.grid('5-8', 5), 0.2):flipH()

  pissBar = love.graphics.newImage('assets/yellowblock.png')
  -- set up our boy
  luigi.x, luigi.y, luigi.speed, luigi.radius = 300, 300, 250, 10
  luigi.sprite = love.graphics.newImage('assets/luigi.png')
  -- set up piss
  nearestPiss.dist = 10000000
  nearestPiss.x = player.x
  nearestPiss.y = player.y
  nearestPiss.radius = 10

  -- set up screen transformation
  screen.transformationX = math.floor(-player.y + (love.graphics.getHeight()/2))

  screen.transformationY = math.floor(-player.y + (love.graphics.getHeight()/2))

  -- set init parms
  pissTankMax = 1000
  pissTank = pissTankMax
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
      pissTank = pissTankMax
      luigiScore = 0
      state = 1
      player.x, player.y, player.speed, player.radius = 100, 100, 150, 80
      player.peespeed, player.deceleration = 200, 25
      luigi.x, luigi.y, luigi.speed, luigi.radius = 300, 300, 250, 10
      pissStream = {}
  -- Intro
  elseif state == 1 then
    -- do the intro stuff
    if love.keyboard.isScancodeDown('space') then
      state = 2
    end
  -- run the game
  elseif state == 2 then
    -- play the game
    player.moving = false

        -- NEW! 8 direction movement
        if love.keyboard.isScancodeDown('left', 'a') then
          if love.keyboard.isScancodeDown('up', 'w') then
            if player.x > (player.grid.frameWidth/2) and player.y > (player.grid.frameHeight/2) then
              player.x = player.x - (player.speed * dt)
              player.y = player.y - (player.speed * dt)
              player.direction = 3
              player.moving = true
            end
          elseif love.keyboard.isScancodeDown('down', 's') then
            if player.y < (map.file.height * map.file.tileheight) - (player.grid.frameHeight/2) and player.x > (player.grid.frameWidth/2) then
              player.x = player.x - (player.speed * dt)
              player.y = player.y + (player.speed * dt)
              player.direction = 1
              player.moving = true
            end
          else
            if player.x > (player.grid.frameWidth/2) then
              player.x = player.x - (player.speed * dt)
              player.direction = 2
              player.moving = true
            end
          end
        elseif love.keyboard.isScancodeDown('right', 'd') then
          if love.keyboard.isScancodeDown('up', 'w') then
            if player.y > (player.grid.frameHeight/2) and player.x < (map.file.width * map.file.tilewidth) - (player.grid.frameWidth/2) then
              player.x = player.x + (player.speed * dt)
              player.y = player.y - (player.speed * dt)
              player.direction = 5
              player.moving = true
            end
          elseif love.keyboard.isScancodeDown('down', 's') then
            if player.y < (map.file.height * map.file.tileheight) - (player.grid.frameHeight/2) and player.x < (map.file.width * map.file.tilewidth) - (player.grid.frameWidth/2) then
              player.x = player.x + (player.speed * dt)
              player.y = player.y + (player.speed * dt)
              player.direction = 7
              player.moving = true
            end
          else
            if player.x < (map.file.width * map.file.tilewidth) - (player.grid.frameWidth/2) then
              player.x = player.x + (player.speed * dt)
              player.direction = 6
              player.moving = true
            end
          end
        elseif love.keyboard.isScancodeDown('up', 'w') then
            if player.y > (player.grid.frameHeight/2) then
              player.y = player.y - (player.speed * dt)
              player.direction = 4
              player.moving = true
            end
        elseif love.keyboard.isScancodeDown('down', 's') then
          if player.y < (map.file.height * map.file.tileheight) - (player.grid.frameHeight/2) then
            player.y = player.y + (player.speed * dt)
            player.direction = 0
            player.moving = true
          end
        end

    --update player bounding bbox
    player.bbox:moveTo(player.x, player.y)

    for shape, delta in pairs(collider:collisions(player.bbox)) do
      player.y = player.y + delta.y
      player.x = player.x + delta.x
    end

    -- update animations
    player.anIDown:update(dt)
    player.anMDown:update(dt)
    player.anIDownLeft:update(dt)
    player.anMDownLeft:update(dt)
    player.anILeft:update(dt)
    player.anMLeft:update(dt)
    player.anIUpLeft:update(dt)
    player.anMUpLeft:update(dt)
    player.anIUp:update(dt)
    player.anMUp:update(dt)
    player.anIUpRight:update(dt)
    player.anMUpRight:update(dt)
    player.anIRight:update(dt)
    player.anMRight:update(dt)
    player.anIDownRight:update(dt)
    player.anMDownRight:update(dt)

    -- update
    screen.transformationX = math.floor(-player.x + (love.graphics.getHeight()/2))
    if screen.transformationX > 0 then
      screen.transformationX = 0
    elseif screen.transformationX < -((map.file.width * map.file.tilewidth) - love.graphics.getWidth()) then
      screen.transformationX = -((map.file.width * map.file.tilewidth) - love.graphics.getWidth())
    end
    screen.transformationY = math.floor(-player.y + (love.graphics.getHeight()/2))
    if screen.transformationY > 0 then
      screen.transformationY = 0
    elseif screen.transformationY < -((map.file.height * map.file.tileheight) - love.graphics.getHeight()) then
      screen.transformationY = -((map.file.height * map.file.tileheight) - love.graphics.getHeight())
    end

    -- is we peeing?
    if love.mouse.isDown(1) then
        local startX = player.x
        local startY = player.y
        local mouseX = love.mouse.getX() - screen.transformationX
        local mouseY = love.mouse.getY() - screen.transformationY
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
      if v.x < -20 or v.x > (map.file.width * map.file.tilewidth) + 20 then
        table.remove(pissStream, i)
      elseif checkCircularCollision(luigi.x, luigi.y, v.x, v.y, luigi.radius, v.radius) then
        table.remove(pissStream, i)
        luigiScore = luigiScore + 1
      end
      v.y = v.y + (v.dy* dt)
      if v.y < -20 or v.y > (map.file.height * map.file.tileheight) + 20 then
        table.remove(pissStream, i)
      end
    end

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
  if state == 2 then
    love.graphics.push()
    -- center the screen on the player
    love.graphics.translate(screen.transformationX, screen.transformationY)

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
    -- walking animations
    if player.moving then
      if player.direction == 0 then
        player.anMDown:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 1 then
        player.anMDownLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 2 then
        player.anMLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 3 then
        player.anMUpLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 4 then
        player.anMUp:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 5 then
        player.anMUpRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 6 then
        player.anMRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 7 then
        player.anMDownRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      else
        player.anMDown:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      end
    else -- idle animations
      if player.direction == 0 then
        player.anIDown:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 1 then
        player.anIDownLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 2 then
        player.anILeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 3 then
        player.anIUpLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 4 then
        player.anIUp:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 5 then
        player.anIUpRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 6 then
        player.anIRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      elseif player.direction == 7 then
        player.anIDownRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      else
        player.anIDown:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2)
      end
    end

    --love.graphics.draw(player.sprite, player.x, player.y, 0, 1, 1, player.sprite:getWidth()/2, player.sprite:getHeight()/2)
    love.graphics.draw(player.arrow, player.x, player.y, math.rad(findRotation(player.x, player.y, luigi.x, luigi.y)), 1, 1, player.arrow:getWidth()/2, player.arrow:getHeight()/2)

    -- draw our boy
    love.graphics.draw(luigi.sprite, luigi.x, luigi.y, 0, 1, 1, luigi.sprite:getWidth()/2, luigi.sprite:getHeight()/2)

    -- shade bounding boxes for testing
    --love.graphics.setColor(10, 10, 10, 150)
    --player.bbox:draw('fill')
    --for i = 1, table.getn(collisionTiles) do
    --  collisionTiles[i]:draw('fill')
    --end

    love.graphics.pop()
    love.graphics.setColor(256, 256, 256)
    love.graphics.draw(pissBar, 10, 10, 0, ((love.graphics.getWidth() - 20) * (pissTank/pissTankMax)), 35)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print('Piss left...', 18, 12)
    love.graphics.setColor(0, 256, 0)
    --love.graphics.print('Mouse at '..mouse.x..', '..mouse.y, 10, love.graphics.getHeight()-40)


  end
  if state == 3 then
    drawMap(map)
    love.graphics.translate(0, 0)
    love.graphics.setColor(10, 10, 10, 150)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(256, 256, 256)
    gameovertext = love.graphics.newText(newFont, 'Game Over!')
    love.graphics.rectangle('fill', 100, 175, love.graphics.getWidth()-200, 1)
    love.graphics.printf('Game over!\r\nLuigi drank '..luigiScore..' litres of peep!', 0, 200, love.graphics.getWidth(), 'center')
    love.graphics.rectangle('fill', 100, 300, love.graphics.getWidth()-200, 1)
    love.graphics.print('Press ESC to Exit.\r\nPress R to restart...', 10, love.graphics.getHeight() - 80)
  end
  if state == 1 then
    drawMap(map)
    love.graphics.translate(0, 0)
    love.graphics.setColor(0, 0, 0, 200)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(256, 256, 256)
    love.graphics.rectangle('fill', 100, 75, love.graphics.getWidth()-200, 1)
    love.graphics.printf('You be an doggo.\r\nYou need peeps.\r\nLuigi bad doggo, want drink yr peeps.\r\nStop luigi drink your peeps.\r\nThey is yors.\r\n\r\nNon for Luigi',
      0, 100, love.graphics.getWidth(), 'center')
    love.graphics.draw(player.sprite, 100, 110, math.rad(330), 1, 1)
    love.graphics.draw(luigi.sprite, 450, 250, math.rad(20), 1, 1)
    love.graphics.rectangle('fill', 100, 375, love.graphics.getWidth()-200, 1)
    love.graphics.printf('WASD move doggo\r\nClick mous to make peep',
      0, 400, love.graphics.getWidth(), 'center')
    love.graphics.print('Press SPACE to start...', 10, love.graphics.getHeight() - 40)
  end
  --love.graphics.setColor(256, 256, 256)
  --text = 'Number of collision tiles is '..table.getn(collisionTiles)
  --love.graphics.print(text,10, 100)


end --love.draw()
