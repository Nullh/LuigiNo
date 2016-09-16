local partSystems = {}
  function loadOrbParticles()
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



return partSystems
