-- Simple library to move an object towards another
-- Neil Holmes 2016

local mover = {}
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
return mover
