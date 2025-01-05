local defs = require("defs")
local utils = require("utils")
local json  = require("json")
local logging = require("logging")

local abilities = {
    ["invis"] = {
        index = 1,
        name = "Invisibility",
        description = "Turn invisible",
        interrupt = false,
        target = false,
        channel = false,
        stationary = false,
        class = defs.AbilityClass.DEFENCE
    },
    ["beam"] = {
        index = 2,
        name = "Beam",
        description = "Shoot a light beam that cuts through enemies.",
        interrupt = false,
        target = true,
        range = 10,
        channel = true,
        stationary = true,
        frequency = 10,
        damage = 10,
        class = defs.AbilityClass.OFFENSE
    },
    ["cantrip"] = {
        index = 3,
        name = "Think",
        description = "Unlock another random ability",
        interrupt = false,
        target = false,
        channel = false,
        stationary = false,
        class = defs.AbilityClass.OPTIMISE
    },
    ["root"] = {
        index = 4,
        name = "Root",
        description = "",
        interrupt = true,
        target = true,
        range = 10,
        channel = false,
        stationary = false,
        class = defs.AbilityClass.OFFENSE
    },
    ["summon"] = {
        index = 5,
        name = "Summon",
        description = "",
        interrupt = false,
        target = false,
        channel = false,
        stationary = false,
        duration = 20,
        shoot_speed = 2,
        range = 1,
        damage = 10,
        class = defs.AbilityClass.OFFENSE
    },
    ["rage"] = {
        index = 7,
        name = "Rage",
        description = "",
        interrupt = false,
        target = false,
        channel = false,
        stationary = false,
        duration = 5,
        class = defs.AbilityClass.BURST
    },
    ["reflect"] = {
        index = 8,
        name = "Reflective barrier",
        description = "",
        interrupt = false,
        target = false,
        channel = true,
        stationary = false,
        duration = 10,
        class = defs.AbilityClass.DEFENCE
    },
    ["stun"] = {
        index = 9,
        name = "Stun",
        description = "",
        interrupt = true,
        target = true,
        range = 10,
        channel = false,
        stationary = false,
        class = defs.AbilityClass.DEFENCE
    },
    ["pull"] = {
        index = 10,
        name = "Pull",
        description = "",
        interrupt = true,
        target = true,
        range = 10,
        channel = false,
        stationary = true,
        class = defs.AbilityClass.OFFENSE
    },
    ["stab"] = {
        index = 11,
        name = "Stab",
        description = "",
        interrupt = false,
        target = true,
        range = 0.1,
        channel = false,
        stationary = false,
        damage = 1000,
        class = defs.AbilityClass.SHORT
    },
    ["summon2"] = {
        index = 12,
        name = "Summon2",
        description = "",
        interrupt = false,
        target = false,
        channel = false,
        stationary = false,
        duration = 20,
        shoot_speed = 2,
        range = 1,
        damage = 10,
        class = defs.AbilityClass.OFFENSE
    },
    ["summon3"] = {
        index = 14,
        name = "Summon 3",
        description = "",
        interrupt = false,
        target = false,
        channel = false,
        stationary = false,
        duration = 20,
        shoot_speed = 2,
        range = 1,
        damage = 10,
        class = defs.AbilityClass.OFFENSE
    }
}

abilities.use = function(world,entity,aname)
    local abil = abilities[aname]

    -- Lock ability
    entity.abilities[aname].locked = true

    -- Stationary ability
    if abil.stationary then
        entity.move_target = nil -- Stationary
    end

    local active_abil = nil
    if abil.channel or (abil.duration ~= nil) then
        active_abil = {}
        active_abil.t0 = world.tick
        if abil.duration then
            active_abil.tf = world.tick + abil.duration * defs.TPS
        end
        active_abil.id = utils.id()
        active_abil.name = aname
    end

    if abilities[aname].use ~= nil then
        abilities[aname].use(world,entity,active_abil)
        table.insert(world.new_particles,"ability " .. aname .. " " .. tostring(entity.x) .. " " .. tostring(entity.y) .. " " .. tostring(entity.h/2 + 20))
    end

    -- Channel ability
    if abil.channel then
        entity.ability_channeling = active_abil
        entity.shooting = false
    else
        entity.ability_channeling = nil
    end

    if active_abil ~= nil then
        local id = active_abil.id

        entity.active_abilities[aname][id] = active_abil
        entity.abilities[aname].times_used = entity.abilities[aname].times_used + 1
    end
end

abilities.update = function(world,entity,active_abil)
    local abil = abilities[active_abil.name]
    local persist = true
    if active_abil.tf and world.tick > active_abil.tf then
        persist = false
    elseif abil.stationary and entity.move_target ~= nil then
        persist = false
    elseif abil.channel and (entity.ability_channeling ~= active_abil or entity.shooting ~= false) then
        persist = false
    else
        if abil.update ~= nil then
            persist = abil.update(world,entity,active_abil)
        end
    end

    if not persist then
        entity.active_abilities[active_abil.name][active_abil.id] = nil
        if entity.ability_channeling == active_abil then
            entity.ability_channeling = nil
        end
    end
end

abilities.draw = function(world,entity,active_abil)
    local abil = abilities[active_abil.name]
    if abil.draw ~= nil then
        abil.draw(world,entity,active_abil)
    end
end

return abilities