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

function entities.summon_get_parent(world,entity)
  local player_name = entity.parent.name
  local player = world.players[player_name]
  if player == nil then
    return nil
  end

  return player
end

function entities.update(world,entity)
  if not entity.alive then return end

  local pixelrange = utils.get_pixel_range(entity.range)

  -- Get summon parent
  local summon_parent = nil
  if entity.summon then
    summon_parent = entities.summon_get_parent(world,entity)
    if summon_parent == nil then
      entity.alive = false
      return
    end

    if utils.euclid(entity.x,entity.y,summon_parent.x,summon_parent.y) > defs.ENTITY_JUMP_DIST then
      log_info("Jump")
      entity.shoot_target = nil
      entity.move_target = nil
      entity.x = summon_parent.x
      entity.y = summon_parent.y
    end
  end

  -- Enemy target player
  if entity.enemy then
    entity.shooting = true

    -- Get the nearest player
    local nearest_player = nil
    local nearest_dist = nil
    for username,player in pairs(world.players) do
      local d = utils.euclid(player.x,player.y,entity.x,entity.y)
      if nearest_player == nil or d < nearest_dist then
        nearest_player = player
        nearest_dist = d
      end
    end

    if nearest_player ~= nil and nearest_dist < 2 * pixelrange then
      entity.shoot_target = {
        type = "player",
        name = nearest_player.username
      }
    else
      entity.shoot_target = nil
    end
  end

  -- Summon get target from parent
  if entity.summon then
    entity.shooting = true

    -- Stop targeting something that's far away
    local target_dist = utils.get_target_dist(entity.x,entity.y,entity.shoot_target,world)
    if target_dist == nil or target_dist > 2 * pixelrange then
      entity.shoot_target = nil
    end

    if entity.shoot_target == nil then
      local dist = utils.get_target_dist(entity.x,entity.y,summon_parent.shoot_target,world)

      if dist ~= nil and dist < 2 * pixelrange then
        entity.shoot_target = {
          type = summon_parent.shoot_target.type,
          name = summon_parent.shoot_target.name
        }
      end
    end
  end

  local target_dist = utils.get_target_dist(entity.x,entity.y,entity.shoot_target,world)
  if target_dist ~= nil then
    if target_dist > 0.9 * pixelrange then
      entity.move_target = utils.get_target_pos(entity.shoot_target,world)
    elseif target_dist < 0.75 * pixelrange then
      entity.move_target = nil
    end
  else
    if entity.summon then
      local dist_to_parent = utils.euclid(entity.x,entity.y,summon_parent.x,summon_parent.y)
      if dist_to_parent > defs.ENTITY_FOLLOW_THRESH then
        entity.move_target = {
          x = summon_parent.x,
          y = summon_parent.y
        }
      else
        entity.move_target = nil
      end
    end
  end
  
end

return entities