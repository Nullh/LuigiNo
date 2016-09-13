local anim8 = require 'anim8'
local HC = require 'HC'
local shack = require 'shack'
require 'bookEntries'
debug = true
fullscreen = false
newFont = nil
luigiScore = nil
score = nil
player = {}
pissStream = {}
chaseObject = {}
pissTankMax = nil
pissTank = nil
pissStamina = nil
pissStaminaMax = nil
staminaTimer = nil
staminaTimerMax = nil
rotateAngle = nil
collisionTiles = {}
scoreTiles = {}
peeOrb = {}
portal = {}
luigi = {}
map = {}
screen = {}
state = 0
signpost = nil
paused = false
glow = 0
glowUp = true
fadeIn = nil
endImg = nil
startCrawl = nil
textFade = nil
-- STATES:
-- 0 - Init
-- 1 - Intro
-- 2 - Gameplay
-- 3 - End game

-- troubleshooting text
text = ''
rotateTargetX = 0
rotateTargetY = 0

-- Return the quad for a tileid
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
    if map.layers[i].type == "tilelayer" then
      for v in pairs(map.layers[i].data) do
        ids[n] = map.layers[i].data[v]
        n = n+1
      end
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

function getPlayerStart(map)
  local coords = {}
  for i=1, table.getn(map.file.layers) do
    if map.file.layers[i].name == "playerstart" then
      coords.x = map.file.layers[i].objects[1].x
      coords.y = map.file.layers[i].objects[1].y
    end
  end
  return coords
end --getPlayerStart()

function createBlockingTiles(map, collider, blockingLayerString)
  local collisionTileTable = {}
  local blockinglayer = nil
  local row = 1
  local column = 1

  for i=1, table.getn(map.file.layers) do
    if map.file.layers[i].name == blockingLayerString then
      -- find the blocking layer
      blockinglayer = i
    end
  end

  -- draw each blocking object
  for i=1, table.getn(map.file.layers[blockinglayer].objects) do
    if map.file.layers[blockinglayer].objects[i].shape == "rectangle" then
      table.insert(collisionTileTable, collider:rectangle(map.file.layers[blockinglayer].objects[i].x, map.file.layers[blockinglayer].objects[i].y,
          map.file.layers[blockinglayer].objects[i].width, map.file.layers[blockinglayer].objects[i].height))
      collisionTileTable[table.getn(collisionTileTable)].name = 'blocking'
    elseif map.file.layers[blockinglayer].objects[i].shape == "ellipse" then
      table.insert(collisionTileTable, collider:circle(map.file.layers[blockinglayer].objects[i].x + (map.file.layers[blockinglayer].objects[i].width/2),
          map.file.layers[blockinglayer].objects[i].y + (map.file.layers[blockinglayer].objects[i].width/2),
          map.file.layers[blockinglayer].objects[i].width/2))
      collisionTileTable[table.getn(collisionTileTable)].name = 'blocking'
    end
  end
  return collisionTileTable
end -- createBlockingTiles()

function getScoreTiles(map, collider, scoreLayerString, psystem)
  local scoreObjectTable = {}
  local scoreLayer = nil
  for i=1, table.getn(map.file.layers) do
    if map.file.layers[i].name == scoreLayerString then
      -- find the blocking layer
      scoreLayer = i
    end
  end

  -- create each blocking object
  for i=1, table.getn(map.file.layers[scoreLayer].objects) do
    if map.file.layers[scoreLayer].objects[i].shape == "rectangle" then
      table.insert(scoreObjectTable, collider:rectangle(map.file.layers[scoreLayer].objects[i].x, map.file.layers[scoreLayer].objects[i].y,
          map.file.layers[scoreLayer].objects[i].width, map.file.layers[scoreLayer].objects[i].height))
      scoreObjectTable[table.getn(scoreObjectTable)].name = 'score'
      scoreObjectTable[table.getn(scoreObjectTable)].full = false
      scoreObjectTable[table.getn(scoreObjectTable)].fill = 0
      scoreObjectTable[table.getn(scoreObjectTable)].x = map.file.layers[scoreLayer].objects[i].x
      scoreObjectTable[table.getn(scoreObjectTable)].y = map.file.layers[scoreLayer].objects[i].y
      scoreObjectTable[table.getn(scoreObjectTable)].width = map.file.layers[scoreLayer].objects[i].width
      scoreObjectTable[table.getn(scoreObjectTable)].height = map.file.layers[scoreLayer].objects[i].height
      scoreObjectTable[table.getn(scoreObjectTable)].number = map.file.layers[scoreLayer].objects[i].name
      scoreObjectTable[table.getn(scoreObjectTable)].particles = psystem:clone()
    elseif map.file.layers[scoreLayer].objects[i].shape == "ellipse" then
      table.insert(scoreObjectTable, collider:circle(map.file.layers[scoreLayer].objects[i].x + (map.file.layers[scoreLayer].objects[i].width/2),
          map.file.layers[scoreLayer].objects[i].y + (map.file.layers[scoreLayer].objects[i].width/2),
          map.file.layers[scoreLayer].objects[i].width/2))
      scoreObjectTable[table.getn(scoreObjectTable)].name = 'score'
      scoreObjectTable[table.getn(scoreObjectTable)].full = false
      scoreObjectTable[table.getn(scoreObjectTable)].fill = 0
      scoreObjectTable[table.getn(scoreObjectTable)].x = map.file.layers[scoreLayer].objects[i].x
      scoreObjectTable[table.getn(scoreObjectTable)].y = map.file.layers[scoreLayer].objects[i].y
      scoreObjectTable[table.getn(scoreObjectTable)].width = map.file.layers[scoreLayer].objects[i].width
      scoreObjectTable[table.getn(scoreObjectTable)].height = map.file.layers[scoreLayer].objects[i].height
      scoreObjectTable[table.getn(scoreObjectTable)].number = map.file.layers[scoreLayer].objects[i].name
      scoreObjectTable[table.getn(scoreObjectTable)].particles = psystem:clone()
    end
  end
  -- sort the order of the array based on the object name (which is a string!)
  local sortFunc = function(a, b) return a.number < b.number end
  table.sort(scoreObjectTable, sortFunc)
  return scoreObjectTable
end -- getScoreTiles()

function drawMap(map, minLayer, maxLayer)
  -- iterate layers
  if table.getn(map.file.layers) < maxLayer then
    maxLayer = table.getn(map.file.layers)
  end
  if minLayer <= 0 then
    minLayer = 1
  end
  for n = minLayer, maxLayer do
    if map.file.layers[n].type == "tilelayer" then
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
    end
end -- drawMap()

function loadMap(path, atlaspath)
  -- Creates a map table with the following values:
  --  .file - a handle to the lua map file
  --  .atlas - the image to use asthe tilemap
  --  .tiles - a table indexed for each tileid
  -- load the map file
  map.file = love.filesystem.load(path)()
  -- load the atlas
  -- TODO: make this load each atlas per layer
  map.atlas = love.graphics.newImage(atlaspath)
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
  if toObject.name == 'player' then
    -- walk around the player
    --rotateTargetX = toObject.x + (100 * math.cos(math.rad(rotateAngle)))
    --rotateTargetY = toObject.y + (100 * math.sin(math.rad(rotateAngle)))

    --local angle = math.atan2((rotateTargetY - object.y), (rotateTargetX - object.x))
    local angle = math.atan2((toObject.y - object.y), (toObject.x - object.x))
    local dx = (math.cos(angle) * object.speed) * dt
    local dy = (math.sin(angle) * object.speed) * dt
      object.x = object.x + dx
      object.y = object.y + dy
  else
    local angle = math.atan2((toObject.y - object.y), (toObject.x - object.x))
    local dx = (math.cos(angle) * object.speed) * dt
    local dy = (math.sin(angle) * object.speed) * dt
      object.x = object.x + dx
      object.y = object.y + dy
    end
end -- moveTowards()

function love.load()
  newFont = love.graphics.newFont('assets/ComingSoon.ttf', 25)
  --compyFont = love.graphics.newFont('assets/256BYTES.TTF', 15)
  signFont = love.graphics.newFont('assets/Cinzel-Black.ttf', 20)
  signFont = love.graphics.newFont('assets/Cinzel-Black.ttf', 20)
  bigSignFont = love.graphics.newFont('assets/Cinzel-Black.ttf', 40)
  bigDefault = love.graphics.newFont('assets/ComingSoon.ttf', 40)
  endImg = love.graphics.newImage('assets/ending.png')
  textFade = 0
  local particle = love.graphics.newImage('assets/particle.png')
  psystem = love.graphics.newParticleSystem(particle, 32)
  psystem:setParticleLifetime(2, 4)
	psystem:setEmissionRate(5)
	psystem:setSizeVariation(1)
	psystem:setLinearAcceleration(5, -8, -5, -40)
	psystem:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.
  psystem:stop()

  -- set up the big particle system
  finalePS = love.graphics.newParticleSystem(particle, 200)
  finalePS:setParticleLifetime(3, 5) -- Particles live at least 2s and at most 5s.
  finalePS:setEmissionRate(40)
  finalePS:setSizeVariation(1)
  finalePS:setLinearAcceleration(40, -10, -40, -40)
  finalePS:setColors(255, 255, 255, 255, 255, 255, 255, 255,255,255,255,0) -- Fade to transparency.
  finalePS:start()

  shack:setDimensions(love.graphics.getWidth(), love.graphics.getHeight())

  collider = HC.new(150)
  -- do my awesome map loading!
  map = loadMap("maps/map3.lua", "assets/atlas64.png")
  collisionTiles = createBlockingTiles(map, collider, 'blocking')
  scoreTiles = getScoreTiles(map, collider, 'score', psystem)

  signpost = love.graphics.newImage('assets/Signpost.png')
  fadeIn = 0

  peeOrb.x = 100
  peeOrb.y = 100
  peeOrb.sprite = love.graphics.newImage('assets/peeorb.png')
  peeOrb.grid = anim8.newGrid(52, 52, peeOrb.sprite:getWidth(), peeOrb.sprite:getHeight())

  portal.sprite = love.graphics.newImage('assets/Portal.png')
  portal.grid = anim8.newGrid(128, 128, portal.sprite:getWidth(), portal.sprite:getHeight())
  portal.active = false
  portal.entered = false
  portal.x = ((map.file.width * map.file.tilewidth)/2)-44
  portal.y = ((map.file.height * map.file.tileheight)/2)-264
  portal.bbox = {}

  -- set up the player
  player.x = getPlayerStart(map).x
  player.y = getPlayerStart(map).y
  player.name = 'player'
  player.speed, player.radius = 150, 80
  player.peespeed, player.deceleration = 200, 25
  player.sprite = love.graphics.newImage('assets/penny2.png')
  player.arrow = love.graphics.newImage('assets/arrow.png')
  player.grid = anim8.newGrid(64, 64, player.sprite:getWidth(), player.sprite:getHeight())
  player.bbox = collider:circle(player.x - (player.grid.frameWidth/2), player.y - (player.grid.frameHeight/2),
    player.grid.frameWidth * 0.5)
  player.bbox.name = 'player'
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

  -- crate the pee orb animations
  peeOrb.anEmpty = anim8.newAnimation(peeOrb.grid(1, 1), 0.2)
  peeOrb.anFull = anim8.newAnimation(peeOrb.grid(2, 1), 0.2)
  peeOrb.an25 = anim8.newAnimation(peeOrb.grid('2-5', 2, '5-2', 2), 0.2)
  peeOrb.an50 = anim8.newAnimation(peeOrb.grid('2-5', 3, '5-2', 3), 0.2)
  peeOrb.an75 = anim8.newAnimation(peeOrb.grid('2-5', 4, '5-2', 4), 0.2)

  portal.an1 = anim8.newAnimation(portal.grid('1-3', 1, '1-3', 2, '1-3', 3, '1-3', 4), 0.2)

  pissBar = love.graphics.newImage('assets/yellowblock.png')
  -- set up our boy
  luigi.x , luigi.y, luigi.speed, luigi.radius = 0, 0, 300, 10
  luigi.sprite = love.graphics.newImage('assets/luigi.png')
  luigi.bbox = collider:circle(luigi.x - (luigi.sprite:getWidth()/2),
    luigi.y - (luigi.sprite:getHeight()/2), luigi.sprite:getWidth() /3)
  -- set up piss
  luigi.bbox.name = 'luigi'
  chaseObject.dist = 10000000
  chaseObject.x = player.x
  chaseObject.y = player.y
  chaseObject.radius = 10

  -- set init parms
  pissTankMax = 1300
  pissStaminaMax = 100
  staminaTimerMax = 10

  love.mouse.setGrabbed(true)
end --love.load()

function love.update(dt)
  if love.keyboard.isScancodeDown('escape') then
    love.event.push('quit')
  end

  function love.keypressed(key, scancode, isrepeat)
    if key == 'f' and isrepeat == false then
      if fullscreen == false then
        fullscreen = true
        love.window.setFullscreen(fullscreen)
        if portal.entered ~= true then
          startCrawl = love.graphics.getHeight() + 50
        end
      else
        fullscreen = false
        love.window.setFullscreen(fullscreen)
        if portal.entered ~= true then
          startCrawl = love.graphics.getHeight() + 50
        end
      end
    end
  end

  -- flip on the state machine
  -- initialising
  if state == 0 then
      -- set init parms
      pissTank = pissTankMax
      pissStamina = pissStaminaMax
      staminaTimer = staminaTimerMax
      rotateAngle = 0
      luigiScore = 0
      score = 0
      portal.active = false
      portal.entered = false
      startCrawl = love.graphics.getHeight() + 50
      textFade = 0
      fadeIn = 0
      screen.transformationX = math.floor(-player.x + (love.graphics.getWidth()/2))
      screen.transformationY = math.floor(-player.y + (love.graphics.getHeight()/2))
      for i, tile in ipairs(scoreTiles) do
        tile.fill = 0
        tile.full = false
        tile.active = false
      end
      state = 1
      player.x = getPlayerStart(map).x
      player.y = getPlayerStart(map).y
      player.speed, player.radius = 150, 80
      player.peespeed, player.deceleration = 200, 25
      math.randomseed(os.time())
      luigi.x, luigi.y = player.x + math.random(-200, 200), player.y + math.random(-200, 200)
      pissStream = {}
  -- Intro
  elseif state == 1 then
    -- do the intro stuff
    player.anIDownLeft:update(dt)
    if love.keyboard.isScancodeDown('space') then
      state = 2
    end
  -- run the game
  elseif state == 2 then
    if love.keyboard.isScancodeDown('p') then
      paused = true
    end

    if debug == true then
      if love.keyboard.isScancodeDown('o') then
        showSignpost = true
        randEntry = love.math.random(1,table.getn(bookEntries))
      end
      if love.keyboard.isScancodeDown('m') then
        portal.active = true
      end
    end

    shack:update(dt)
    shack:setShake(20)

    -- increment the glow value up and down
    if glowUp == true then
      glow = glow + 2
      if glow >= 200 then
        glowUp = false
      end
    else
      glow = glow - 2
      if glow <= 0 then
        glowUp = true
        glow = 0
      end
    end

    if paused == false then
      -- play the game
      for i, v in ipairs(scoreTiles) do
        if v.active == true then
          v.particles:update(dt)
        end
      end

      finalePS:update(dt)

      player.moving = false
      rotateAngle = rotateAngle + 1
      if rotateAngle > 360 then rotateAngle = 0 end
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

      -- update the pee orbs
      peeOrb.an25:update(dt)
      peeOrb.an50:update(dt)
      peeOrb.an75:update(dt)

      portal.an1:update(dt)

      if scoreTiles[1].active == true
        and scoreTiles[2].active == true
        and scoreTiles[3].active == true
        and scoreTiles[4].active == true
        and scoreTiles[5].active == true then
          portal.active = true
      end

      if portal.active == true then
        portal.bbox =  collider:rectangle(portal.x, portal.y, 128, 128)
        portal.bbox.name = 'portal'
      end

      -- update
      if love.graphics.getWidth() < map.file.width * map.file.tilewidth then
        screen.transformationX = math.floor(-player.x + (love.graphics.getWidth()/2))
        if screen.transformationX > 0 then
          screen.transformationX = 0
        elseif screen.transformationX < -((map.file.width * map.file.tilewidth) - love.graphics.getWidth()) then
          screen.transformationX = -((map.file.width * map.file.tilewidth) - love.graphics.getWidth())
        end
      else
        screen.transformationX = (love.graphics.getWidth() - (map.file.width * map.file.tilewidth))/2
      end

      if love.graphics.getHeight() < map.file.height * map.file.tileheight then
        screen.transformationY = math.floor(-player.y + (love.graphics.getHeight()/2))
        if screen.transformationY > 0 then
          screen.transformationY = 0
        elseif screen.transformationY < -((map.file.height * map.file.tileheight) - love.graphics.getHeight()) then
          screen.transformationY = -((map.file.height * map.file.tileheight) - love.graphics.getHeight())
        end
      else
        screen.transformationY = (love.graphics.getHeight() - (map.file.height * map.file.tileheight))/2
      end

      -- do we want to stop peeing?
      if pissStamina > 0 and love.mouse.isDown(1) and staminaTimer >= staminaTimerMax then
        pissStamina = pissStamina - (20 * dt)
        if pissStamina <= 0 then staminaTimer = 0 end
        -- REMOVE THIS BEFORE RELEASE!
      elseif love.mouse.isDown(2) and debug == true then
      else
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
                                    radius = 0,
                                    bbox = collider:circle(startX, startY, 5)})
          pissStream[table.getn(pissStream)].bbox.name = 'piss'
          pissTank = pissTank - 1
          pissStamina = pissStamina + (20 * dt)
          if pissStamina > pissStaminaMax then pissStamina = pissStaminaMax end
          if staminaTimer < staminaTimerMax then staminaTimer = staminaTimer + (10 * dt) end
      end

      --update player bounding bbox

      for shape, delta in pairs(collider:collisions(luigi.bbox)) do
        if shape.name ~= 'piss' then
          luigi.y = luigi.y + delta.y
          luigi.x = luigi.x + delta.x
        end
      end
      luigi.bbox:moveTo(luigi.x, luigi.y)

      for shape, delta in pairs(collider:collisions(player.bbox)) do
        if shape.name ~= 'piss' and shape.name ~= 'luigi' then
          player.y = player.y + delta.y
          player.x = player.x + delta.x
          if shape.name == 'portal' then
            portal.entered = true
            collider:remove(portal.bbox)
            state = 3
          end
        end
      end
      player.bbox:moveTo(player.x, player.y)

      for i,v in ipairs(pissStream) do
        for shape, delta in pairs(collider:collisions(v.bbox)) do
          if shape.name == 'score' then
            collider:remove(v.bbox)
            table.remove(pissStream, i)
            if shape.fill + 1 < 101 then
              shape.fill = shape.fill + 1
              score = score + 1
            elseif shape.full == false then
              -- pause and show the signpost
              paused = true
              showSignpost = true
              randEntry = love.math.random(1,table.getn(bookEntries))
              shape.full = true
              shape.active = true
              shape.particles:start()
            end
          elseif shape.name == 'blocking' then
            collider:remove(v.bbox)
            table.remove(pissStream, i)
          elseif shape.name == 'luigi' then
            collider:remove(v.bbox)
            table.remove(pissStream, i)
            luigiScore = luigiScore + 1
          end
        end
      end

      for i, v in ipairs(pissStream) do
        v.x = v.x + (v.dx* dt)
        v.y = v.y + (v.dy* dt)
        v.bbox:moveTo(v.x, v.y)
      end

      -- find the closest pee
      chaseObject.dist = 10000000
      if next(pissStream) ~= nil then
        for i, v in ipairs(pissStream) do
          local sd = math.dist(luigi.x, luigi.y, v.x, v.y)
          if sd < chaseObject.dist then
              chaseObject.dist = sd
              chaseObject.x = v.x
              chaseObject.y = v.y
              chaseObject.radius = 0
              chaseObject.name = 'piss'
          end
        end
      else
          chaseObject.dist = sd
          chaseObject.x = player.x
          chaseObject.y = player.y
          chaseObject.radius = player.radius
          chaseObject.name = 'player'
      end
      -- get our boy movin'
      moveTowards(luigi, dt, chaseObject)

      -- end the game if we're out of piss
      if pissTank <= 0 then
        state = 3
      end
    else
      if love.keyboard.isScancodeDown('space') then
        paused = false
        showSignpost = false
      end
    end
  elseif state == 3 then
    -- end game
    if love.keyboard.isScancodeDown('r') then
      state = 0
    end
  end
end --love.update()

function love.draw()
  love.graphics.setFont(newFont)
  if state == 2 then

    love.graphics.push()
    -- center the screen on the player
    love.graphics.translate(screen.transformationX, screen.transformationY)

    if portal.active == true then
      shack:apply()
    end

    -- draw the map
    love.graphics.setColor(256, 256, 256)
    drawMap(map, 1, 3)
    -- draw piss
    love.graphics.setColor(244, 250, 60)
    for i,v in ipairs(pissStream) do
      love.graphics.circle("fill", v.x, v.y, 3)
    end
    love.graphics.setColor(256, 256, 256)

    -- draw the pentagram lines
    if scoreTiles[1].active == true then
      if scoreTiles[4].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(scoreTiles[1].x+(scoreTiles[1].width/2), scoreTiles[1].y+(scoreTiles[1].height/2),
          scoreTiles[4].x+(scoreTiles[4].width/2), scoreTiles[4].y+(scoreTiles[4].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(scoreTiles[1].x+(scoreTiles[1].width/2), scoreTiles[1].y+(scoreTiles[1].height/2),
          scoreTiles[4].x+(scoreTiles[4].width/2), scoreTiles[4].y+(scoreTiles[4].height/2))
      end
      if scoreTiles[3].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(scoreTiles[1].x+(scoreTiles[1].width/2), scoreTiles[1].y+(scoreTiles[1].height/2),
          scoreTiles[3].x+(scoreTiles[3].width/2), scoreTiles[3].y+(scoreTiles[3].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(scoreTiles[1].x+(scoreTiles[1].width/2), scoreTiles[1].y+(scoreTiles[1].height/2),
          scoreTiles[3].x+(scoreTiles[3].width/2), scoreTiles[3].y+(scoreTiles[3].height/2))
      end
    end
    if scoreTiles[2].active == true then
      if scoreTiles[4].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(scoreTiles[2].x+(scoreTiles[2].width/2), scoreTiles[2].y+(scoreTiles[2].height/2),
          scoreTiles[4].x+(scoreTiles[4].width/2), scoreTiles[4].y+(scoreTiles[4].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(scoreTiles[2].x+(scoreTiles[2].width/2), scoreTiles[2].y+(scoreTiles[2].height/2),
          scoreTiles[4].x+(scoreTiles[4].width/2), scoreTiles[4].y+(scoreTiles[4].height/2))
      end
      if scoreTiles[5].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(scoreTiles[2].x+(scoreTiles[2].width/2), scoreTiles[2].y+(scoreTiles[2].height/2),
          scoreTiles[5].x+(scoreTiles[5].width/2), scoreTiles[5].y+(scoreTiles[5].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(scoreTiles[2].x+(scoreTiles[2].width/2), scoreTiles[2].y+(scoreTiles[2].height/2),
          scoreTiles[5].x+(scoreTiles[5].width/2), scoreTiles[5].y+(scoreTiles[5].height/2))
      end
    end
    if scoreTiles[3].active == true then
      if scoreTiles[5].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(scoreTiles[3].x+(scoreTiles[3].width/2), scoreTiles[3].y+(scoreTiles[3].height/2),
          scoreTiles[5].x+(scoreTiles[5].width/2), scoreTiles[5].y+(scoreTiles[5].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(scoreTiles[3].x+(scoreTiles[3].width/2), scoreTiles[3].y+(scoreTiles[3].height/2),
          scoreTiles[5].x+(scoreTiles[5].width/2), scoreTiles[5].y+(scoreTiles[5].height/2))
      end
    end

    for i, v in ipairs(scoreTiles) do
      if v.active == true then
        love.graphics.setColor(200, 0, 0, glow/3.5)
        love.graphics.circle('fill', v.x+(v.width/2),
          v.y+(v.height/2)+5, 25, 20)
      end
    end

    love.graphics.setColor(256, 256, 256)


    for i, v in ipairs(scoreTiles) do
      if v.active == true then
        love.graphics.draw(v.particles, v.x+(v.width/2), v.y+3)
      end
    end
    -- draw the pee orbs
    for i, v in ipairs(scoreTiles) do
      if v.fill == 0 then
        peeOrb.anEmpty:draw(peeOrb.sprite, v.x-8, v.y)
      elseif v.fill > 0 and v.fill < 33 then
        peeOrb.an25:draw(peeOrb.sprite, v.x-8, v.y)
      elseif v.fill >= 33 and v.fill < 66 then
        peeOrb.an50:draw(peeOrb.sprite, v.x-8, v.y)
      elseif v.fill >= 66 and v.fill < 100 then
        peeOrb.an75:draw(peeOrb.sprite, v.x-8, v.y)
      elseif v.fill >= 100 then
        peeOrb.anFull:draw(peeOrb.sprite, v.x-8, v.y)
      end
    end

    if portal.active == true then
      love.graphics.draw(finalePS, portal.x+64, portal.y+30)
      portal.an1:draw(portal.sprite, portal.x, portal.y)
    end

    -- draw our boy
    love.graphics.setColor(256, 256, 256)
    love.graphics.draw(luigi.sprite, luigi.x, luigi.y, 0, 1, 1, luigi.sprite:getWidth()/2, luigi.sprite:getHeight()/2)
    -- draw the player
    -- walking animations
    if player.moving then
      if player.direction == 0 then
        player.anMDown:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 1 then
        player.anMDownLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 2 then
        player.anMLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 3 then
        player.anMUpLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 4 then
        player.anMUp:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 5 then
        player.anMUpRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 6 then
        player.anMRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 7 then
        player.anMDownRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      else
        player.anMDown:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      end
    else -- idle animations
      if player.direction == 0 then
        player.anIDown:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 1 then
        player.anIDownLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 2 then
        player.anILeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 3 then
        player.anIUpLeft:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 4 then
        player.anIUp:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 5 then
        player.anIUpRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 6 then
        player.anIRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      elseif player.direction == 7 then
        player.anIDownRight:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      else
        player.anIDown:draw(player.sprite, player.x, player.y, 0, 1, 1, player.grid.frameWidth/2, player.grid.frameHeight/2 + 8)
      end
    end

    --love.graphics.draw(player.sprite, player.x, player.y, 0, 1, 1, player.sprite:getWidth()/2, player.sprite:getHeight()/2)
    love.graphics.draw(player.arrow, player.x, player.y, math.rad(findRotation(player.x, player.y, luigi.x, luigi.y)), 1, 1, player.arrow:getWidth()/2, player.arrow:getHeight()/2)





    -- draw overlay layer
    drawMap(map, 4, 4)

    -- shade bounding boxes for testing
    if debug == true then
      love.graphics.setColor(10, 10, 10, 150)
      --player.bbox:draw('fill')
      --luigi.bbox:draw('fill')
      --portal.bbox:draw('fill')
      for i = 1, table.getn(collisionTiles) do
        --collisionTiles[i]:draw('fill')
      end
      for i = 1, table.getn(scoreTiles) do
        --love.graphics.setColor(10, 10, 10, 150)
        --scoreTiles[i]:draw('fill')
        --love.graphics.setFont(compyFont)
        --love.graphics.setColor(0, 256, 0)
        --love.graphics.print(scoreTiles[i].fill, scoreTiles[i].x, scoreTiles[i].y-5)
        --love.graphics.print(scoreTiles[i].number, scoreTiles[i].x, scoreTiles[i].y+10)
        --love.graphics.setFont(newFont)
      end
    end

    if portal.active == true then
      if fadeIn < 150 then
        fadeIn = fadeIn + 1
      end
      love.graphics.setColor(100, 0, 0, fadeIn)
      love.graphics.rectangle('fill', 0, 0, map.file.width * map.file.tilewidth, map.file.height * map.file.tileheight)
    end

    love.graphics.pop()

    love.graphics.setColor(256, 256, 256, 200)
    love.graphics.draw(pissBar, 10, 10, 0, ((love.graphics.getWidth() - 20) * (pissTank/pissTankMax)), 35)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print('Pee left...', 18, 5)

    love.graphics.print('Score: '..score, 10, love.graphics.getHeight() - 50)

    if staminaTimer < staminaTimerMax then
      love.graphics.setColor(256, 0, 0, 200)
      love.graphics.draw(pissBar, 10, 40, 0, ((love.graphics.getWidth() - 20) * (pissStamina/pissStaminaMax)), 5)
    else
      love.graphics.setColor(0, 0, 256, 200)
      love.graphics.draw(pissBar, 10, 40, 0, ((love.graphics.getWidth() - 20) * (pissStamina/pissStaminaMax)), 5)
    end
    love.graphics.setColor(0, 256, 0)
    if paused == true then -- paused
      love.graphics.setColor(0, 0, 0, 200)
      love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
      love.graphics.setColor(256, 256, 256)
      love.graphics.setFont(bigDefault)
      love.graphics.printf('..PAWSED..\r\nPress SPACE to continue...',
        0, 10, love.graphics.getWidth(), 'center')
      if showSignpost == true then
        love.graphics.draw(signpost, (love.graphics.getWidth()/2)-((signpost:getWidth()/2)),
          (love.graphics.getHeight()/2)-((signpost:getHeight()/2)))
        local textX = 0
        local textY = (love.graphics.getHeight()/2)-((signpost:getHeight()/2)) + 30
        love.graphics.setFont(signFont)
        love.graphics.setColor(256, 256, 256, 50)
        love.graphics.printf(bookEntries[randEntry],
          textX+1, textY+1, love.graphics.getWidth(), 'center')
        love.graphics.setColor(0, 0, 0, 100)
        love.graphics.printf(bookEntries[randEntry],
          textX-1, textY-1, love.graphics.getWidth(), 'center')
        love.graphics.setColor(48, 30, 15)
        love.graphics.printf(bookEntries[randEntry],
          textX, textY, love.graphics.getWidth(), 'center')
      end
    end

  elseif state == 3 then
    if portal.entered == true then
      love.graphics.setColor(256, 256, 256)
      love.graphics.draw(endImg, love.graphics.getWidth()/2, love.graphics.getHeight()/2, 0,
        (love.graphics.getHeight()/endImg:getHeight()), (love.graphics.getHeight()/endImg:getHeight()),
        --1, 1,
        endImg:getWidth() / 2, endImg:getHeight() / 2)

      love.graphics.setFont(bigSignFont)
      love.graphics.setColor(0, 0, 0)
      love.graphics.printf(endText, 2, startCrawl+2, love.graphics.getWidth(), 'center')
      love.graphics.setColor(256, 256, 256)
      love.graphics.printf(endText, 0, startCrawl, love.graphics.getWidth(), 'center')
      startCrawl = startCrawl - 1
      if startCrawl < -950 then
        startCrawl = -950
        love.graphics.setFont(signFont)
        love.graphics.setColor(0, 0, 0, textFade)
        love.graphics.print("Press ESC to quit.\r\nPress R to restart...", 10, love.graphics.getHeight()-60)
        love.graphics.setColor(256, 256, 256, textFade)
        love.graphics.print("Press ESC to quit.\r\nPress R to restart...", 12, love.graphics.getHeight()-58)
        textFade = textFade + 1
        if textFade > 256 then textFade = 256 end
      end



    else
      love.graphics.push()
      love.graphics.scale(love.graphics.getWidth()/(map.file.width * map.file.tilewidth),
        love.graphics.getWidth()/(map.file.width * map.file.tilewidth))
      drawMap(map, 1, 100)
      love.graphics.translate(0, 0)
      love.graphics.pop()
      love.graphics.setColor(10, 10, 10, 150)
      love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
      love.graphics.setColor(256, 256, 256)
      gameovertext = love.graphics.newText(newFont, 'Game Over!')
      love.graphics.rectangle('fill', 100, 175, love.graphics.getWidth()-200, 1)
      love.graphics.printf('Game over!\r\nYou got '..score..' litres of peep on target\r\nLuigi drank '
        ..luigiScore..' litres of peep\r\n\r\nYour final score is: \r\n'..(score-luigiScore),
        0, 200, love.graphics.getWidth(), 'center')
      love.graphics.rectangle('fill', 100, 430, love.graphics.getWidth()-200, 1)
      love.graphics.print('Press ESC to Exit.\r\nPress R to restart...', 10, love.graphics.getHeight() - 80)
    end
  elseif state == 1 then
    love.graphics.push()
    love.graphics.scale(love.graphics.getWidth()/(map.file.width * map.file.tilewidth),
      love.graphics.getWidth()/(map.file.width * map.file.tilewidth))
    drawMap(map, 1, 100)
    love.graphics.translate(0, 0)
    love.graphics.pop()
    love.graphics.setColor(0, 0, 0, 200)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(256, 256, 256)
    --love.graphics.rectangle('fill', 100, 75, love.graphics.getWidth()-200, 1)
    local splashScreen = love.graphics.newImage('assets/SplashScreen.png')
    love.graphics.draw(splashScreen, (love.graphics.getWidth()/2)-(splashScreen:getWidth()/2), (love.graphics.getHeight()/2)-(splashScreen:getHeight()/2))

  end
  --love.graphics.setColor(256, 256, 256)
  --text = endImg:getHeight()
  --love.graphics.print(text,10, 100)


end --love.draw()
