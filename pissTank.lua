local pissTank = {}

  local pissTankMax = 1400
  local pissStaminaMax = 100
  local staminaTimerMax = 10

  local fill = pissTankMax
  local stamina = pissStaminaMax
  local staminaTimer = staminaTimerMax

  local pissBar = love.graphics.newImage('assets/yellowblock.png')

  function pissTank.newPissTank()
    return pissTank
  end

  function pissTank.resetTank()
    fill = pissTankMax
  end

  function pissTank.getFill()
    return fill
  end

  function pissTank.decrementFill()
    fill = fill - 1
  end

  function pissTank.resetStamina()
    stamina = pissStaminaMax
  end

  function pissTank.resetStaminaTimer()
    staminaTimer = staminaTimerMax
  end

  function pissTank.getStamina()
    return stamina
  end

  function pissTank.hasStamina()
    if staminaTimer >= staminaTimerMax then
      return true
    else
      return false
    end
  end

  function pissTank.decrementStamina(dt)
    stamina = stamina - (20 * dt)
    if stamina <= 0 then staminaTimer = 0 end
  end

  function pissTank.incrementStamina(dt)
    stamina = stamina + (20 * dt)
    if stamina > pissStaminaMax then sStamina = pissStaminaMax end
    if staminaTimer < staminaTimerMax then staminaTimer = staminaTimer + (10 * dt) end
  end

 function pissTank.drawBar()
    love.graphics.setColor(256, 256, 256, 200)
    love.graphics.draw(pissBar, 10, 10, 0, ((love.graphics.getWidth() - 20) * (fill/pissTankMax)), 35)
    love.graphics.setColor(256, 256, 256)
    love.graphics.print('Pee remaining...', 19, 3)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print('Pee remaining...', 18, 2)
    if staminaTimer < staminaTimerMax then
      love.graphics.setColor(256, 0, 0, 200)
      love.graphics.draw(pissBar, 10, 40, 0, ((love.graphics.getWidth() - 20) * (stamina/pissStaminaMax)), 5)
    else
      love.graphics.setColor(0, 0, 256, 200)
      love.graphics.draw(pissBar, 10, 40, 0, ((love.graphics.getWidth() - 20) * (stamina/pissStaminaMax)), 5)
    end
  end

return pissTank
