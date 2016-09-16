local anim8 = require 'anim8'
local HC = require 'HC'
local shack = require 'shack'
local playerLib = require 'player'
local peeOrbLib = require 'peeOrb'
local portalLib = require 'portal'
local luigiLib = require 'luigi'
local pissTankLib = require 'pissTank'
require 'TEsound'
require 'bookEntries'
require 'mapLoader'
require 'mover'
require 'partSystems'
debug = true
text = ''
player = {}
pissStream = {}
chaseObject = {}
collisionTiles = {}
peeOrbs = {}
portal = {}
luigi = {}
map = {}
screen = {}
--peeOrb = {}
state = 0
glowUp = true
-- STATES:
-- 0 - Init
-- 1 - Intro
-- 2 - Gameplay
-- 3 - End game

-- troubleshooting text
--text = ''


function flipGlugAllowed(list)
  glugAllowed = true
end

function flipWalkAllowed(list)
  walkAllowed = true
end

function love.load()
  newFont = love.graphics.newFont('assets/ComingSoon.ttf', 25)
  --compyFont = love.graphics.newFont('assets/256BYTES.TTF', 15)
  signFont = love.graphics.newFont('assets/Cinzel-Black.ttf', 20)
  signFont = love.graphics.newFont('assets/Cinzel-Black.ttf', 20)
  bigSignFont = love.graphics.newFont('assets/Cinzel-Black.ttf', 40)
  bigDefault = love.graphics.newFont('assets/ComingSoon.ttf', 40)
  endImg = love.graphics.newImage('assets/ending.png')
  leaves01 = love.sound.newSoundData("assets/leaves01.ogg")
  leaves02 = love.sound.newSoundData("assets/leaves02.ogg")
  walklist = {[1]=leaves01, [2]=leaves02}
  shack:setDimensions(love.graphics.getWidth(), love.graphics.getHeight())
  collider = HC.new(150)
  -- do my awesome map loading!
  map = loadMap("maps/map3.lua", "assets/atlas64.png")
  collisionTiles = getMapObjectLayer(map, collider, 'blocking')
  plyerExcTiles = getMapObjectLayer(map, collider, 'playerblock')

  for i, object in ipairs(getScoreObjects(map, collider, 'score')) do
    table.insert(peeOrbs, peeOrbLib.newPeeOrb(object.x, object.y, object.width, object.height, object.number))
    --text = text.."\r\n"..object.x..','..object.y
  end


  signpost = love.graphics.newImage('assets/Signpost.png')
  player = playerLib.newPlayer()
  portal = portalLib.newPortal()
  luigi = luigiLib.new(player.x + math.random(-200, 200), player.y + math.random(-200, 200))
  pissTank = pissTankLib.newPissTank()

  chaseObject.dist = 10000000
  chaseObject.x = player.x
  chaseObject.y = player.y
  chaseObject.radius = 10



  love.mouse.setGrabbed(true)
end --love.load()




function love.update(dt)
  TEsound.cleanup()
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
      pissTank.resetTank()
      pissTank.resetStamina()
      pissTank.resetStaminaTimer()
      rotateAngle = 0
      luigi.resetScore()
      player.resetScore()
      portal.active = false
      portal.entered = false
      startCrawl = love.graphics.getHeight() + 50
      textFade = 0
      imgFade = 0
      glow = 0
      glowUp = true
      TEsound.playLooping('assets/hiss.mp3', 'hiss', nil, 0.05, 0.8)
      TEsound.pause('hiss')
      screen.transformationX = math.floor(-player.x + (love.graphics.getWidth()/2))
      screen.transformationY = math.floor(-player.y + (love.graphics.getHeight()/2))
      for i, peeOrb in ipairs(peeOrbs) do
        peeOrb:reset()
      end
      glugAllowed = true
      walkAllowed = true
      TEsound.stop('ending')
      TEsound.stop('bgm')
      TEsound.playLooping('assets/MSTR_-_MSTR_-_Choro_bavario_Loop.ogg', 'bgm', nil, 0.6)
      state = 1
      player.goHome()
      math.randomseed(os.time())
      --luigi:getX(), luigi:getY() = player.x + math.random(-200, 200), player.y + math.random(-200, 200)
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
      for i, v in ipairs(peeOrbs) do
        if v.active == true then
          v.particles:update(dt)
        end
      end

      shack:update(dt)
      shack:setShake(20)

      player.moving = false
      rotateAngle = rotateAngle + 1
      if rotateAngle > 360 then rotateAngle = 0 end
          -- NEW! 8 direction movement
          if love.keyboard.isScancodeDown('left', 'a') then
            if love.keyboard.isScancodeDown('up', 'w') then
              player.moveLU(dt)
            elseif love.keyboard.isScancodeDown('down', 's') then
              player.moveLD(dt)
            else
              player.moveL(dt)
            end
          elseif love.keyboard.isScancodeDown('right', 'd') then
            if love.keyboard.isScancodeDown('up', 'w') then
              player.moveRU(dt)
            elseif love.keyboard.isScancodeDown('down', 's') then
              player.moveRD(dt)
            else
              player.moveR(dt)
            end
          elseif love.keyboard.isScancodeDown('up', 'w') then
            player.moveU(dt)
          elseif love.keyboard.isScancodeDown('down', 's') then
            player.moveD(dt)
          end

      if player.moving == true then
        if walkAllowed == true then
          local randWalk = love.math.random(1, 2)
          walkAllowed = false
          TEsound.play(walklist[randWalk], 'walk', 1, 1, flipWalkAllowed)
        end
      end

      player.updateAnimations(dt)
      for i, peeOrb in ipairs(peeOrbs) do
        peeOrb:updateAnimations(dt)
      end
      portal.updateAnimations(dt)

      if peeOrbs[1].active == true
        and peeOrbs[2].active == true
        and peeOrbs[3].active == true
        and peeOrbs[4].active == true
        and peeOrbs[5].active == true then
          portal.active = true
      end

      if portal.active == true then
        portal.bbox =  collider:rectangle(portal.x, portal.y, 128, 128)
        portal.bbox.name = 'portal'
        TEsound.stop('bgm', false)
        TEsound.playLooping('assets/Undead_Rising_Low_Tension_1_.ogg', 'ending', nil, 0.8)
        TEsound.playLooping('assets/equake6.mp3', 'rumble', nil, 1.5)
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
      if pissTank.getStamina() > 0 and love.mouse.isDown(1) and pissTank.hasStamina() then
        pissTank.decrementStamina(dt)
        TEsound.pause('hiss')
      elseif love.mouse.isDown(2) and debug == true then
        TEsound.pause('hiss')
      elseif pissTank.getFill() > 0 then
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
          pissTank.decrementFill()
          TEsound.resume('hiss')
          pissTank.incrementStamina(dt)
      end

      --update player bounding bbox

      for shape, delta in pairs(collider:collisions(luigi.getBbox())) do
        if shape.name ~= 'piss' and shape.name ~= 'playerblock' and shape.name ~= 'portal' then
          luigi:moveTo(luigi:getX() + delta.x, luigi:getY() + delta.y)
        end
      end

      for shape, delta in pairs(collider:collisions(player.bbox)) do
        if shape.name ~= 'piss' and shape.name ~= 'luigi' then
          player.y = player.y + delta.y
          player.x = player.x + delta.x
          if shape.name == 'portal' then
            portal.entered = true
            collider:remove(portal.bbox)
            TEsound.stop('rumble', false)
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
              player.incrementScore()
              if glugAllowed == true then
                local pitch = 0.5 + (shape.fill/2)/100
                TEsound.play('assets/glug.mp3', 'glug', 0.8, pitch, flipGlugAllowed)
                glugAllowed = false
              end
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
            luigi:incrementScore()
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
          local sd = math.dist(luigi:getX(), luigi:getY(), v.x, v.y)
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
      luigi:moveTowards(dt, chaseObject.x, chaseObject.y)

      -- end the game if we're out of piss
      if pissTank.getFill() <= 0 and table.getn(pissStream) == 0 then
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
    TEsound.stop('hiss')
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
    if peeOrbs[1].active == true then
      if peeOrbs[4].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(peeOrbs[1].x+(peeOrbs[1].width/2), peeOrbs[1].y+(peeOrbs[1].height/2),
          peeOrbs[4].x+(peeOrbs[4].width/2), peeOrbs[4].y+(peeOrbs[4].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(peeOrbs[1].x+(peeOrbs[1].width/2), peeOrbs[1].y+(peeOrbs[1].height/2),
          peeOrbs[4].x+(peeOrbs[4].width/2), peeOrbs[4].y+(peeOrbs[4].height/2))
      end
      if peeOrbs[3].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(peeOrbs[1].x+(peeOrbs[1].width/2), peeOrbs[1].y+(peeOrbs[1].height/2),
          peeOrbs[3].x+(peeOrbs[3].width/2), peeOrbs[3].y+(peeOrbs[3].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(peeOrbs[1].x+(peeOrbs[1].width/2), peeOrbs[1].y+(peeOrbs[1].height/2),
          peeOrbs[3].x+(peeOrbs[3].width/2), peeOrbs[3].y+(peeOrbs[3].height/2))
      end
    end
    if peeOrbs[2].active == true then
      if peeOrbs[4].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(peeOrbs[2].x+(peeOrbs[2].width/2), peeOrbs[2].y+(peeOrbs[2].height/2),
          peeOrbs[4].x+(peeOrbs[4].width/2), peeOrbs[4].y+(peeOrbs[4].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(peeOrbs[2].x+(peeOrbs[2].width/2), peeOrbs[2].y+(peeOrbs[2].height/2),
          peeOrbs[4].x+(peeOrbs[4].width/2), peeOrbs[4].y+(peeOrbs[4].height/2))
      end
      if peeOrbs[5].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(peeOrbs[2].x+(peeOrbs[2].width/2), peeOrbs[2].y+(peeOrbs[2].height/2),
          peeOrbs[5].x+(peeOrbs[5].width/2), peeOrbs[5].y+(peeOrbs[5].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(peeOrbs[2].x+(peeOrbs[2].width/2), peeOrbs[2].y+(peeOrbs[2].height/2),
          peeOrbs[5].x+(peeOrbs[5].width/2), peeOrbs[5].y+(peeOrbs[5].height/2))
      end
    end
    if peeOrbs[3].active == true then
      if peeOrbs[5].active == true then
        love.graphics.setLineWidth(6)
        love.graphics.setColor(237, 133, 67, (glow/4)*3)
        love.graphics.line(peeOrbs[3].x+(peeOrbs[3].width/2), peeOrbs[3].y+(peeOrbs[3].height/2),
          peeOrbs[5].x+(peeOrbs[5].width/2), peeOrbs[5].y+(peeOrbs[5].height/2))
        love.graphics.setLineWidth(2)
        love.graphics.setColor(200, 0, 0, glow)
        love.graphics.line(peeOrbs[3].x+(peeOrbs[3].width/2), peeOrbs[3].y+(peeOrbs[3].height/2),
          peeOrbs[5].x+(peeOrbs[5].width/2), peeOrbs[5].y+(peeOrbs[5].height/2))
      end
    end

    for i, v in ipairs(peeOrbs) do
      if v.active == true then
        love.graphics.setColor(200, 0, 0, glow/3.5)
        love.graphics.circle('fill', v.x+(v.width/2),
          v.y+(v.height/2)+5, 25, 20)
      end
    end

    love.graphics.setColor(256, 256, 256)


    for i, v in ipairs(peeOrbs) do
      if v.active == true then
        love.graphics.draw(v.particles, v.x+(v.width/2), v.y+3)
      end
    end

    -- draw the pee orbs
    for i, peeOrb in ipairs(peeOrbs) do
      peeOrb:draw()
    end

    love.graphics.setColor(256, 256, 256)
    luigi.draw()
    player.draw()
    portal.draw()
    -- draw overlay layer
    drawMap(map, 4, 10)


    love.graphics.pop()
    pissTank.drawBar()
    player.drawScore()

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
      if imgFade < 256 then
        love.graphics.setColor(256, 256, 256, imgFade)
        love.graphics.draw(endImg, love.graphics.getWidth()/2, love.graphics.getHeight()/2, 0,
          (love.graphics.getHeight()/endImg:getHeight()), (love.graphics.getHeight()/endImg:getHeight()),
          --1, 1,
          endImg:getWidth() / 2, endImg:getHeight() / 2)
          imgFade = imgFade + 1
      else
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
      love.graphics.printf('Game over!\r\nYou got '..player.getScore()..' litres of peep on target\r\nLuigi drank '
        ..luigi.getScore()..' litres of peep\r\n\r\nYour final score is: \r\n'..(player.getScore()-luigi.getScore()),
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
  love.graphics.setColor(256, 256, 256)
  love.graphics.print(text,10, 100)


end --love.draw()
