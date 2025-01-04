local defs = require("defs")
local utils = require("utils")
local abilities = require("abilities")

local Entities = {
    ["dummy"] = {
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
      targetable = true,
      damage = 10,
      shoot_speed = 1,
      range = 0.4,
      max_hp = 200,
      move_speed = 0.75,
      drops = {}
    },
    ["bigbot"] = {
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
      max_hp = 100,
      move_speed = 0.9,
      drops = {
      }
    },
    ["cat"] = {
      targetable = true,
      shoot_speed = 2,
      damage = 10,
      range = 0.8,
      max_hp = 200,
      move_speed = 0.9,
    },
    ["player"] = {
      shoot_speed = 4,
      range = 1,
      damage = 10,
      max_hp = defs.PLAYER_HP,
      move_speed = 1
    }
  }

local entities = {}

function entities.create_player(sprite,x,y,w,h,abils,name)
  local entity = entities.create("player",sprite,true,nil,x,y,w,h,abils,name)
  entity.player = true
  entity.ephemeral = true
  return entity
end

function entities.create_summon(type,sprite,x,y,w,h,name,parent,parent_ability)
  local entity = entities.create(type,sprite,true,nil,x,y,w,h,Entities[type].abils,name)
  entity.parent = parent
  entity.parent_ability = parent_ability
  entity.summon = true
  entity.ephemeral = true
  return entity
end

function entities.create_enemy(type,sprite,visible,zone,x,y,w,h,name)
  local entity = entities.create(type,sprite,visible,zone,x,y,w,h,Entities[type].abils,name)
  entity.enemy = true
  return entity
end

function entities.create(type,sprite,visible,zone,x,y,w,h,abils,name)
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

    local entity_abils = {}
    local entity_abilmap = {}
    local entity_active_abils = {}
    if abils ~= nil then
      for aname,abil in pairs(abils) do
        entity_abils[aname] = {
          locked = abil.locked,
          times_used = abil.times_used,
          slot = abil.slot
        }
        if abil.slot ~= - 1 then
          entity_abilmap[abil.slot] = aname
        end

        entity_active_abils[aname] = {}
      end
    end

    local entity = {
      -- Args
        name = name,
        sprite = sprite,
        visible = visible == true,
        zone = zone,
        x = x,
        y = y,
        w = w,
        h = h,
        type = type,
        alive = true,
        charge = 0,
        last_shoot = nil,
        ability_channeling = nil,
        shooting = false,
        ephemeral = false,
        -- Identity
        player = false,
        enemy = false,
        summon = false,
        -- Substructures
        parent = nil,
        parent_ability = nil,
        drops = entity_drops,
        abilities = entity_abils,
        ability_map = entity_abilmap,
        active_abilities = entity_active_abils,
        -- Type def
        targetable = etype.targetable == true,
        shoot_speed = etype.shoot_speed,
        damage = etype.damage,
        range = etype.range,
        hp = etype.max_hp,
        max_hp = etype.max_hp,
        move_speed = etype.move_speed,
        -- Player
        player_discovered_zones = {},
        player_loot = {},
        player_ability_book_open = false
    }

    return entity
end

----> Have entity shoot at something
function entities.shoot_bullet(world,entity)
  if entity == nil then return false end

  if entity.shoot_target ~= nil then
    local new_bullet = {
      source = entity.name,
      x = entity.x,
      y = entity.y,
      flying = true,
      target = entity.shoot_target
    }

    table.insert(world.bullets,new_bullet)
  end
end

function entities.update(world,entity)
  if not entity.alive then return end

  local pixelrange = utils.get_pixel_range(entity.range)

  if entity.player then
  
    -- Player abilities
    for aname,aabils in pairs(entity.active_abilities) do
      for id,aabil in pairs(aabils) do
        local ability_def = abilities[aname]
        local cancel = false
  
        -- Cancel stationary ability if player moves
        if ability_def.stationary then
          if entity.move_target ~= nil then
            cancel = true
          end
        end
  
        -- Cancel channeling if player uses another ability or shoots
        if ability_def.channel then
          if entity.ability_channeling ~= aabil or entity.shooting ~= false then
            cancel = true
          end
        end
  
        if not cancel then
          local active = aabil.update()
          if not active then cancel = true end
        end
  
        if cancel then
          aabils[id] = nil
        end
      end
    end
  
    if entity.shooting and entity.shoot_target ~= nil then
      local shoot_speed = entity.shoot_speed
      for _,rage in pairs(entity.active_abilities["rage"]) do
        shoot_speed = shoot_speed * 2
      end
      local shoot_period = defs.TPS / shoot_speed
  
      local target_pos = get_target_pos(entity.shoot_target)
      if target_pos ~= nil then
        local target_dist = utils.euclid(target_pos.x,target_pos.y,entity.x,entity.y)
        if target_dist <= utils.get_pixel_range(entity.range) then
          if entity.last_shoot == nil or world.tick - entity.last_shoot > shoot_period then
            entities.shoot_bullet(world,entity)
            entity.last_shoot = world.tick
          end
        end
      end
    end
  
    -- Discover zones
    if world.zones ~= nil then
      for name,zone in pairs(world.zones) do
        if not entity.player_discovered_zones[name] then
          for i,region in pairs(zone.regions) do
            if region.x1 < entity.x and entity.x < region.x2 and region.y1 < entity.y and entity.y < region.y2 then
              entity.player_discovered_zones[name] = true
              zone.discovered = true
              log_info("Discovered " .. name)
              goto continuezone
            end
          end
        end
  
        ::continuezone::
      end
    end
  else
    -- Get summon parent
    local summon_parent = nil
    if entity.summon then
      summon_parent = world.entities[entity.parent]
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
    else
      entity.shooting = true

      -- Get the nearest player
      local nearest_entity = nil
      local nearest_dist = nil
      for ename,e in pairs(world.entities) do
        if e.enemy ~= entity.enemy then
          local d = utils.euclid(e.x,e.y,entity.x,entity.y)
          if nearest_entity == nil or d < nearest_dist then
            nearest_entity = e
            nearest_dist = d
          end
        end
      end

      if nearest_entity ~= nil and nearest_dist < 2 * pixelrange then
        entity.shoot_target = nearest_entity.name
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
          entity.shoot_target = summon_parent.shoot_target
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


  
  
end

return entities