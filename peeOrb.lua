local anim8 = require 'anim8'

local peeOrb = {}

function peeOrb.newPeeOrb(x, y, width, height, number)

  local self ={}
  full = false
  fill = 0
  active = false
  number = number or 0
  x = x or 0
  y = y or 0
  width = width or 0
  height = height or 0

  sprite = love.graphics.newImage('assets/peeorb.png')
  bbox = collider:circle(x - (sprite:getWidth()/2),
    y - (sprite:getHeight()/2), sprite:getWidth() /3)
  bbox.name = 'score'
  grid = anim8.newGrid(52, 52, sprite:getWidth(), sprite:getHeight())

  -- create the pee orb animations
  anEmpty = anim8.newAnimation(grid(1, 1), 0.2)
  anFull = anim8.newAnimation(grid(2, 1), 0.2)
  an25 = anim8.newAnimation(grid('2-5', 2, '5-2', 2), 0.2)
  an50 = anim8.newAnimation(grid('2-5', 3, '5-2', 3), 0.2)
  an75 = anim8.newAnimation(grid('2-5', 4, '5-2', 4), 0.2)
  ps = loadOrbParticles()

    local function loadOrbParticles()
      local particle = love.graphics.newImage('assets/particle.png')
      local partSystem = love.graphics.newParticleSystem(particle, 32)
      partSystem:setParticleLifetime(2, 4)
      partSystem:setEmissionRate(5)
      partSystem:setSizeVariation(1)
      partSystem:setLinearAcceleration(5, -8, -5, -40)
      partSystem:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.
      partSystem:stop()
      return partSystem
    end

    function self:getX()
      return x
    end

    function self:getY()
      return y
    end

    function self:reset()
      full = false
      fill = 0
      active = false
    end

    function self:updateAnimations(dt)
      -- update the pee orbs
      an25:update(dt)
      an50:update(dt)
      an75:update(dt)
    end

    function self:draw()
      --love.graphics.draw(peeOrb.test, x, y)
      if fill == 0 then
        anEmpty:draw(sprite, x-8, y)
      elseif fill > 0 and fill < 33 then
        an25:draw(sprite, x-8, y)
      elseif fill >= 33 and fill < 66 then
        an50:draw(sprite, x-8, y)
      elseif fill >= 66 and fill < 100 then
        an75:draw(sprite, x-8, y)
      elseif fill >= 100 then
        anFull:draw(sprite, x-8, y)
      else
        anEmpty:draw(sprite, x-8, y)
      end
    end

    return self
  end

return peeOrb
