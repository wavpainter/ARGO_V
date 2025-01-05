local defs = require("defs")
local utils = require("utils")
local abilities = require("abilities")
local json = require("json")
local logging = require("logging")

local log_info = logging.log_info
local log_warning = logging.log_warning
local log_error = logging.log_error

local Entities = {
    ["dummy"] = {
      targetable = true,
      damage = 0,
      shoot_speed = 1,
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
      damage = 5,
      shoot_speed = 2,
      range = 0.4,
      max_hp = 200,
      move_speed = 0.75,
      abilities = {
        ["reflect"] = {
          locked = true,
          times_used = 0,
          slot = 2
        }
      },
      drops = {}
    },
    ["bigbot"] = {
      targetable = true,
      damage = 5,
      shoot_speed = 4,
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

function entities.create_summon(type,sprite,x,y,w,h,name,parent,parent_ability,enemy)
  local entity = entities.create(type,sprite,true,nil,x,y,w,h,Entities[type].abilities,name)
  entity.parent = parent
  entity.parent_ability = parent_ability
  entity.summon = true
  entity.ephemeral = true
  entity.enemy = enemy
  return entity
end

function entities.create_enemy(type,sprite,visible,zone,x,y,w,h,name)
  local entity = entities.create(type,sprite,visible,zone,x,y,w,h,Entities[type].abilities,name)
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

function entities.unlock_random(world,entity,exclude,reset_charge)
  if reset_charge == nil then reset_charge = true end

  if entity == nil or entity.abilities == nil then
    return
  end
  
  local n_unlocked = 0
  local n_locked = 0
  local locked_abils = {}
  for aname,abil in pairs(entity.abilities) do
    if not abil.locked then
      n_unlocked = n_unlocked + 1
    elseif abil.slot ~= -1 then
      if exclude ~= aname then
        table.insert(locked_abils,aname)
        n_locked = n_locked + 1
      end
    end
  end

  if n_locked ~= 0 and n_unlocked < defs.MAX_UNLOCKED then
    local i = math.random(1,n_locked)
    local unlocking = locked_abils[i]
    if reset_charge then entity.charge = 0 end
    entity.abilities[unlocking].locked = false
  end
end

function entities.use_ability(world,entity,ability_name)
  abilities.use(world,entity,ability_name)

  -- Unlock abilities
  if entity.charge >= defs.CHARGE_TO_UNLOCK then
    entities.unlock_random(world,entity)
  end
end

----> Can use ability
function entities.can_use_ability(world,entity,ability_name)
  local ability_def = abilities[ability_name]
  if ability_def == nil or entity.abilities[ability_name] == nil then return false end

  if entity.abilities[ability_name].locked then return false end

  if ability_def.target then
    if entity.shoot_target == nil then
      return false
    end
    
    local target = world.entities[entity.shoot_target]
    if target == nil or not target.alive then
      return false
    end

    local pixelrange = ability_def.range * entity.move_speed * defs.MOVE_SPEED
    local dist = utils.euclid(target.x,target.y,entity.x,entity.y)

    if dist > pixelrange then
      return false
    end
  end

  return true
end

function entities.update(world,entity)
  if not entity.alive then return end

  local pixelrange = utils.get_pixel_range(entity.range)

  if entity.player then
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
    -- AI
    if entity.zone ~= nil and not world.zones[entity.zone].discovered then
      return
    end

    -- Get summon parent
    local summon_parent = nil
    if entity.summon then
      summon_parent = world.entities[entity.parent]
      local parent_ability = entity.parent_ability
      if summon_parent == nil then
        entity.alive = false
        return
      end
      local name_parts = split_delim(entity.name,".")
      local id = name_parts[2]

      local active = false
      if summon_parent ~= nil and summon_parent.active_abilities[parent_ability] ~= nil and summon_parent.active_abilities[parent_ability][id] ~= nil then
        active = true
      end

      if not active then
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
      -- Get the nearest player
      local nearest_entity = nil
      local nearest_dist = nil
      for ename,e in pairs(world.entities) do
        if e.alive and (e.enemy ~= entity.enemy) then
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

    -- Decide to use abilities
    if entity.abilities ~= nil then
      local counts = {}
      local unlocked_abils = {}

      for _,class in pairs(defs.AbilityClass) do
        counts[class] = 0
        unlocked_abils[class] = {}
      end

      for aname,a in pairs(entity.abilities) do
        if not a.locked then
          local class = abilities[aname].class
          counts[class] = counts[class] + 1
          table.insert(unlocked_abils[class],aname)
        end
      end

      local low_hp = entity.hp < (entity.max_hp * 0.25)

      if entity.ability_channeling ~= nil then
        local chan = abilities[entity.ability_channeling.name]
        if (low_hp and chan.class == defs.AbilityClass.DEFENCE)
          or (not low_hp and chan.class == defs.AbilityClass.OFFENSE) then
          -- Use nothing
          goto finishedabils
        end
      end

      if counts[defs.AbilityClass.OPTIMISE] > 0 then
        -- Use an optimise ability
        local uas = unlocked_abils[defs.AbilityClass.OPTIMISE]
        for i = 1,counts[defs.AbilityClass.OPTIMISE] do
          if entities.can_use_ability(world,entity,uas[i]) then
            entities.use_ability(world,entity,uas[i])
            goto finishedabils
          end
        end
      end

      if counts[defs.AbilityClass.SHORT] > 0 then
        local usable_short_abils = {}
        local n_usable_short = 0
        for _,aname in pairs(unlocked_abils[defs.AbilityClass.SHORT]) do
          if entities.can_use_ability(world,entity,aname) then
            table.insert(usable_short_abils,aname)
            n_usable_short = n_usable_short + 1
          end
        end

        if n_usable_short > 0 then
          -- Use a short ability
          entities.use_ability(world,entity,unlocked_abils[defs.AbilityClass.SHORT][1])
        end
      end

      if low_hp and counts[defs.AbilityClass.DEFENCE] > 0 then
        -- Use a defense ability
        local uas = unlocked_abils[defs.AbilityClass.DEFENCE]
        for i = 1,counts[defs.AbilityClass.DEFENCE] do
          if entities.can_use_ability(world,entity,uas[i]) then
            entities.use_ability(world,entity,uas[i])
            goto finishedabils
          end
        end
      end

      if counts[defs.AbilityClass.BURST] > 0 then
        -- Use a burst ability
        local uas = unlocked_abils[defs.AbilityClass.BURST]
        for i = 1,counts[defs.AbilityClass.BURST] do
          if entities.can_use_ability(world,entity,uas[i]) then
            entities.use_ability(world,entity,uas[i])
            goto finishedabils
          end
        end
      end

      local n_channeled_abils = 0
      local channeled_abils = {}
      local n_non_channeled_abils = 0
      local non_channeled_abils = {}

      for _,aname in pairs(unlocked_abils[defs.AbilityClass.OFFENSE]) do
        if abilities[aname].channel then
          n_channeled_abils = n_channeled_abils + 1
          table.insert(channeled_abils,aname)
        else
          n_non_channeled_abils = n_non_channeled_abils + 1
          table.insert(non_channeled_abils,aname)
        end
      end

      if n_non_channeled_abils > 0 then
        -- Use a non-channeled abilities
        for i = 1,n_non_channeled_abils do
          if entities.can_use_ability(world,entity,non_channeled_abils[i]) then
            entities.use_ability(world,entity,non_channeled_abils[i])
            goto finishedabils
          end
        end
      end

      local n_burst_active = 0
      for aname,aabils in pairs(entity.active_abilities) do
        if abilities[aname].class == defs.AbilityClass.BURST then
          for id,aabil in pairs(aabils) do
            n_burst_active = n_burst_active + 1
          end
        end
      end

      if n_burst_active == 0 and n_channeled_abils > 0 then
        -- Use a channeled ability
        for i = 1,n_channeled_abils do
          if entities.can_use_ability(world,entity,channeled_abils[i]) then
            entities.use_ability(world,entity,channeled_abils[i])
            goto finishedabils
          end
        end
      end

      ::finishedabils::
    end

    if entity.ability_channeling == nil then
      entity.shooting = true
    else
      entity.shooting = false
    end
  end

  -- Active abilities
  for aname,aabils in pairs(entity.active_abilities) do
    for id,aabil in pairs(aabils) do
      abilities.update(world,entity,aabil)
    end
  end

  -- Entity shoot
  if entity.shooting and entity.shoot_target ~= nil then
    local shoot_speed = entity.shoot_speed
    if entity.active_abilities["rage"] ~= nil then
      for _,rage in pairs(entity.active_abilities["rage"]) do
        shoot_speed = shoot_speed * 2
      end
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

  -- Entity move
  if entity.move_target ~= nil then
    local new_pos = utils.new_pos(entity.x,entity.y,entity.move_target.x,entity.move_target.y,defs.MOVE_SPEED * entity.move_speed)
    adjust_pos_for_collisions(new_pos,defs.PLAYER_L,defs.PLAYER_L)
    
    entity.x = new_pos.x
    entity.y = new_pos.y
    if new_pos.arrived then
      entity.move_target = nil
    end
  end
end

return entities