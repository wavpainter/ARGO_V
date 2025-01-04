local defs = require("defs")

local utils = {}

function utils.get_pixel_range(range)
    return range * defs.MOVE_SPEED
end

function utils.euclid(x1,y1,x2,y2)
    return math.sqrt((x1 - x2) ^2 + (y1 - y2) ^2)
  end

function utils.get_target_dist(x,y,target,world)
    local target_pos = utils.get_target_pos(target,world)
    if target_pos == nil then return nil end

    return utils.euclid(x,y,target_pos.x,target_pos.y)
end

function utils.get_target_pos(target,world)
    if target == nil then return nil end

    local entity = world.entities[target]
    if entity == nil or not entity.alive then 
        return nil
    else
        return {
            x = entity.x,
            y = entity.y
        }
    end
end

function utils.new_pos(x1,y1,x2,y2,speed)
    local target_dist = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    local t_remain = target_dist / speed
    local dt = love.timer.getDelta()
    if t_remain <= dt then
        return {
        arrived = true,
        x = x2,
        y = y2,
        }
    else
        local scale = dt / t_remain
        return {
        arrived = false,
        x = x1 + (x2 - x1) * scale,
        y = y1 + (y2 - y1) * scale
        }
    end
end

return utils