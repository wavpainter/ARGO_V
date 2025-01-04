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

    if target.type == defs.TargetType.PLAYER then
        local player = world.players[target.name]
        if player == nil then
            return nil
        else 
            return {
                x = player.x,
                y = player.y 
            }
        end
    elseif target.type == defs.TargetType.ENTITY then
        local entity = world.entities[target.name]
        if entity == nil or not entity.alive then 
            return nil
        else
            return {
                x = entity.x,
                y = entity.y
            }
        end
    end
end

return utils