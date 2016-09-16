local luigi = {}

  function luigi.new(x, y)
    local self = {}
    local score = 0
    x = x or 0
    y = y or 0
    speed = 300
    sprite = love.graphics.newImage('assets/luigi.png')
    bbox = collider:circle(x - (sprite:getWidth()/2),
      y - (sprite:getHeight()/2), sprite:getWidth() /3)
    bbox.name = 'luigi'

    local function updateBbox()
      bbox:moveTo(x, y)
    end

    updateBbox()

    function self:getBbox()
      return bbox
    end

    function self:incrementScore()
      score = score + 1
    end

    function self:resetScore()
      score = 0
    end

    function self:getScore()
      return score
    end

    function self:moveTo(tox, toy)
      x = tox
      y = toy
      updateBbox()
    end

    function self:getX()
      return x
    end

    function self:getY()
      return y
    end

    function self:moveTowards(dt, tox, toy)
      --if toluigi.name == 'player' then
        -- walk around the player
        --rotateTargetX = toluigi.x + (100 * math.cos(math.rad(rotateAngle)))
        --rotateTargetY = toluigi.y + (100 * math.sin(math.rad(rotateAngle)))

        --local angle = math.atan2((rotateTargetY - y), (rotateTargetX - x))
        local angle = math.atan2((toy - y), (tox - x))
        local dx = (math.cos(angle) * speed) * dt
        local dy = (math.sin(angle) * speed) * dt
          x = x + dx
          y = y + dy
    --  else
    --    local angle = math.atan2((toy - y), (tox - x))
      --  local dx = (math.cos(angle) * speed) * dt
    --    local dy = (math.sin(angle) * speed) * dt
        --  x = x + dx
          --y = y + dy
          updateBbox()
      --end
    end -- moveTowards()

    function self:draw()
      love.graphics.draw(sprite, x, y, 0, 1, 1, sprite:getWidth()/2, sprite:getHeight()/2)
    end
  return self
end
return luigi
