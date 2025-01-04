local Abilities = {
["invis"] = {
    index = 1,
    name = "Invisibility",
    description = "Turn invisible",
    interrupt = false,
    target = false,
    channel = false,
    stationary = false,
    use = function(world,player) return nil end
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
    use = function(world,player) return true end
},
["cantrip"] = {
    index = 3,
    name = "Think",
    description = "Unlock another random ability",
    interrupt = false,
    target = false,
    channel = false,
    stationary = false,
    use = function(world,player) return nil end
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
    use = function(world,player) return nil end
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
    use = function(world,player) return nil end
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
    use = function(world,player) return nil end
},
["reflect"] = {
    index = 8,
    name = "Reflective barrier",
    description = "",
    interrupt = false,
    target = false,
    channel = false,
    stationary = false,
    duration = 10,
    use = function(world,player) return nil end
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
    use = function(world,player) return nil end
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
    use = function(world,player) return nil end
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
    use = function(world,player) return nil end
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
    use = function(world,player) return nil end
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
    use = function(world,player) return nil end
}
}

return Abilities