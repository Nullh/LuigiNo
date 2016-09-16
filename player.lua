local anim8 = require 'anim8'
local player = {}
  local score = 0
  local speed = 150
  local peespeed = 200
  local deceleration = 25

  function player.incrementScore()
    score = score + 1
  end

  function player.getScore()
    return score
  end

  function player.resetScore()
    score = 0
  end

  function player.goHome()
    player.x = getPlayerStart(map).x
    player.y = getPlayerStart(map).y
  end

  -- set up the player
  function player.newPlayer()
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
    return player
  end

  function player.updateAnimations(dt)
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
end

  function player.moveLU(dt)
    if player.x > (player.grid.frameWidth/2) and player.y > (player.grid.frameHeight/2) then
      player.x = player.x - (player.speed * dt)
      player.y = player.y - (player.speed * dt)
      player.direction = 3
      player.moving = true
      --return player
    end
  end

  function player.moveLD(dt)
    if player.y < (map.file.height * map.file.tileheight) - (player.grid.frameHeight/2) and player.x > (player.grid.frameWidth/2) then
      player.x = player.x - (player.speed * dt)
      player.y = player.y + (player.speed * dt)
      player.direction = 1
      player.moving = true
    end
  end

  function player.moveL(dt)
    if player.x > (player.grid.frameWidth/2) then
      player.x = player.x - (player.speed * dt)
      player.direction = 2
      player.moving = true
    end
  end

  function player.moveRU(dt)
    if player.y > (player.grid.frameHeight/2) and player.x < (map.file.width * map.file.tilewidth) - (player.grid.frameWidth/2) then
      player.x = player.x + (player.speed * dt)
      player.y = player.y - (player.speed * dt)
      player.direction = 5
      player.moving = true
    end
  end

  function player.moveRD(dt)
    if player.y < (map.file.height * map.file.tileheight) - (player.grid.frameHeight/2) and player.x < (map.file.width * map.file.tilewidth) - (player.grid.frameWidth/2) then
      player.x = player.x + (player.speed * dt)
      player.y = player.y + (player.speed * dt)
      player.direction = 7
      player.moving = true
    end
  end

  function player.moveR(dt)
    if player.x < (map.file.width * map.file.tilewidth) - (player.grid.frameWidth/2) then
      player.x = player.x + (player.speed * dt)
      player.direction = 6
      player.moving = true
    end
  end

  function player.moveU(dt)
    if player.y > (player.grid.frameHeight/2) then
      player.y = player.y - (player.speed * dt)
      player.direction = 4
      player.moving = true
    end
  end

  function player.moveD(dt)
    if player.y < (map.file.height * map.file.tileheight) - (player.grid.frameHeight/2) then
      player.y = player.y + (player.speed * dt)
      player.direction = 0
      player.moving = true
    end
  end

  function player.drawScore()
    love.graphics.setColor(0, 0, 0)
    love.graphics.print('Score: '..score, 11, love.graphics.getHeight() - 49)
    love.graphics.setColor(256, 256, 256)
    love.graphics.print('Score: '..score, 10, love.graphics.getHeight() - 50)
  end

  function player.draw()
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
    love.graphics.draw(player.arrow, player.x, player.y, math.rad(findRotation(player.x, player.y, luigi:getX(), luigi:getY())), 1, 1, player.arrow:getWidth()/2, player.arrow:getHeight()/2)
end

return player
