local defs = require("defs")
local utils = require("utils")

local Entities = {
    ["dummy"] = {
      enemy = true,
      targetable = true,
      damage = 0,
      shoot_speed = 0.5,
      range = 0.8,
      max_hp = 987654321,
      move_speed = 0,
      drops = {
        {
          name = "ability cantrip",
          rate = 1
        }
      }
    },
    ["meleebot"] = {
      enemy = true,
      targetable = true,
      damage = 10,
      shoot_speed = 1,
      range = 0.4,
      max_hp = 200,
      move_speed = 0.75,
      drops = {}
    },
    ["bigbot"] = {
      enemy = true,
      targetable = true,
      damage = 15,
      shoot_speed = 1,
      range = 0.9,
      max_hp = 800,
      move_speed = 0.5,
      drops = {
        {
          name = "ability cantrip",
          rate = 1
        }
      }
    },
    ["skeleton"] = {
      enemy = true,
      targetable = true,
      shoot_speed = 1.5,
      damage = 10,
      range = 1,
      max_hp = 200,
      move_speed = 0.75,
      drops = {
        {
          name = "ability stab",
          rate = 1
        }
      }
    },
    ["minion"] = {
      targetable = true,
      ephemeral = true,
      max_hp = 100,
      move_speed = 0.9,
      drops = {
      }
    },
    ["cat"] = {
      targetable = true,
      summon = true,
      ephemeral = true,
      shoot_speed = 0.75,
      damage = 10,
      range = 0.8,
      max_hp = 200,
      move_speed = 0.9,
    }
  }

local entities = {}

function entities.create(type,sprite,visible,zone,x,y,w,h,parent)
    local etype = Entities[type]

    if etype == nil then return nil end

    local entity_drops = {}
    if etype.drops ~= nil then
      for _,drop in pairs(etype.drops) do
          table.insert(entity_drops,{
              name = drop.name,
              rate = drop.rate
          })
      end
    end

    local entity_parent = nil
    if parent ~= nil then
      entity_parent = {
        type = parent.type,
        name = parent.name
      }
    end

    local entity = {
      -- Args
        sprite = sprite,
        visible = visible == true,
        zone = zone,
        x = x,
        y = y,
        w = w,
        h = h,
        type = type,
        alive = true,
        -- Substructures
        parent = entity_parent,
        drops = entity_drops,
        -- Type def
        enemy = etype.enemy == true,
        targetable = etype.targetable == true,
        ephemeral = etype.ephemeral == true,
        summon = etype.summon == true,
        shoot_speed = etype.shoot_speed,
        damage = etype.damage,
        range = etype.range,
        hp = etype.max_hp,
        max_hp = etype.max_hp,
        move_speed = etype.move_speed,
        -- Summons
        summon_following = false
    }

    return entity
end

function entities.update(world,entity)
  if not entity.alive then return end

  -- Summon
  if entity.summon then
    local player_name = entity.parent.name
    local player = world.players[player_name]
    if player == nil then
      entity.alive = false
      return
    end

    local dist_to_player = euclid(entity.x,entity.y,player.x,player.y)
    if dist_to_player > defs.ENTITY_JUMP_DIST then
      entity.x = player.x
      entity.y = player.y
    elseif dist_to_player > defs.ENTITY_FOLLOW_THRESH then
      entity.summon_following = true
    elseif dist_to_player < defs.ENTITY_FOLLOW_DIST then
      entity.summon_following = false
    end

    if entity.summon_following then
      local pos = new_pos(entity.x,entity.y,player.x,player.y,defs.MOVE_SPEED)
      adjust_pos_for_collisions(pos,entity.w,entity.h)

      entity.x = pos.x
      entity.y = pos.y
    end

    entity.shoot_target = player.shoot_target
  -- Enemy
  elseif entity.enemy then
    if not entity.shooting then
      entity.shooting = true
    end

    -- Get the nearest player
    local nearest_player = nil
    local nearest_dist = nil
    for username,player in pairs(world.players) do
      local d = euclid(player.x,player.y,entity.x,entity.y)
      if nearest_player == nil or d < nearest_dist then
        nearest_player = player
        nearest_dist = d
      end
    end

    local pixelrange = utils.get_pixel_range(entity.range)

    -- Walk towards the player
    if nearest_dist > 0.9 * pixelrange then
      entity.moving = true
    elseif nearest_dist < 0.75 * pixelrange then
      entity.moving = false
    end

    if entity.moving then
      entity.move_target = {
        x = nearest_player.x,
        y = nearest_player.y
      }
    else
      entity.move_target = nil
    end

    entity.shoot_target = {
      type = "player",
      name = nearest_player.username
    }
  end
end

return entities