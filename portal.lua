local anim8 = require 'anim8'

local portal = {}
local fadeIn = 0

 local function loadEndParticles()
     -- set up the big particle system
     local particle = love.graphics.newImage('assets/particle.png')
     local partSystem = love.graphics.newParticleSystem(particle, 200)
     partSystem:setParticleLifetime(3, 5) -- Particles live at least 2s and at most 5s.
     partSystem:setEmissionRate(40)
     partSystem:setSizeVariation(1)
     partSystem:setLinearAcceleration(40, -10, -40, -40)
     partSystem:setColors(255, 255, 255, 255, 255, 255, 255, 255,255,255,255,0) -- Fade to transparency.
     partSystem:start()
     return partSystem
  end

  function portal.newPortal()
    portal.sprite = love.graphics.newImage('assets/Portal.png')
    portal.grid = anim8.newGrid(128, 128, portal.sprite:getWidth(), portal.sprite:getHeight())
    portal.active = false
    portal.entered = false
    portal.x = ((map.file.width * map.file.tilewidth)/2)-44
    portal.y = ((map.file.height * map.file.tileheight)/2)-264
    portal.bbox = {}
    portal.an1 = anim8.newAnimation(portal.grid('1-3', 1, '1-3', 2, '1-3', 3, '1-3', 4), 0.2)
    portal.ps = loadEndParticles()
    return portal
  end

  function portal.updateAnimations(dt)
    portal.an1:update(dt)
    portal.ps:update(dt)
  end

  function portal.draw()
    if portal.active == true then
      love.graphics.draw(portal.ps, portal.x+64, portal.y+30)
      portal.an1:draw(portal.sprite, portal.x, portal.y)
      if fadeIn < 150 then
        fadeIn = fadeIn + 1
      end
      love.graphics.setColor(100, 0, 0, fadeIn)
      love.graphics.rectangle('fill', 0, 0, map.file.width * map.file.tilewidth, map.file.height * map.file.tileheight)
    end
  end

return portal
