local json = require("json")

--> CONSTANTS
----> Util
local Color = {
  ["red"] = { 1, 0, 0 },
  ["green"] = { 0, 1, 0 },
  ["blue"] = { 0, 0, 1 },
  ["black"] = { 0, 0, 0 },
  ["white"] = { 1, 1, 1 },
  ["lightgrey"] = {0.8, 0.8, 0.8}
}

local Alphabet = "abcdefghijklmnopqrstuvwxyz"
local Digits = "0123456789"

local LegalKeys = {
  ["space"] = " ",
  ["shift space"] = " ",
  ["shift -"] = "_",
  ["."] = ".",
}

for i = 1,#Alphabet do
  local c = Alphabet:sub(i,i)
  local C = string.upper(c)
  LegalKeys[c] = c
  LegalKeys["shift " .. c] = C
end
for i = 1,#Digits do
  local c = Digits:sub(i,i)
  LegalKeys[c] = c
end

----> State
local View = {
  INIT = "init",
  MENU = "menu",
  GAME = "game",
}
local Debug = {
  HIDDEN = "hidden",
  SHOWN = "shown",
  CAPTURING = "cap"
}

----> Game
local AbilityKey = { 
  ["1"] = 1, 
  ["2"] = 2, 
  ["3"] = 3, 
  ["4"] = 4, 
  ["5"] = 5, 
  ["q"] = 6, 
  ["w"] = 7, 
  ["e"] = 8, 
  ["r"] = 9, 
  ["t"] = 10,
}
local BIGNUM = 1000000
local DEFAULT_USERNAME = "jason"
local MOVE_DELAY_S = 0.15
local PLAYER_L = 75
local DROP_L = 40
local MOVE_SPEED = 800
local PLAYER_HP = 1000
local BULLET_SPEED = 1500
local BULLET_RADIUS = 10
local INTERACT_DIST = 100
local TPS = 60
local CHARGE_TO_UNLOCK = 8
local MAX_UNLOCKED = 3
local OFFSET_X = 0
local OFFSET_Y = -20
local ENTITY_FOLLOW_THRESH = 250
local ENTITY_FOLLOW_DIST = 100
local ENTITY_JUMP_DIST = 1000

local Images = {
  ["bin"] = "bin.png",
  ["love"] = "love.png",
  ["broken"] = "broken.png",
  ["invis"] = "invis.png",
  ["beam"] = "beam.png",
  ["cantrip"] = "cantrip.png",
  ["root"] = "root.png",
  ["negate"] = "negate.png",
  ["push"] = "push.png",
  ["rage"] = "rage.png",
  ["reflect"] = "reflect.png",
  ["stun"] = "stun.png",
  ["pull"] = "pull.png",
  ["jason"] = "jason.png",
  ["target"] = "target.png",
  ["dummy"] = "dummy.png",
  ["skeleton"] = "skeleton.png",
  ["stab"] = "stab.png",
  ["lectern"] = "lectern.png",
  ["lock"] = "lock.png",
  ["summon"] = "summon.png",
  ["summon2"] = "summon.png",
  ["summon3"] = "summon.png"
}
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
local Entities = {
  ["dummy"] = {
    enemy = true,
    targetable = true,
    ephemeral = false,
    damage = 1,
    shoot_speed = 1,
    range = 1,
    hp = 987654321,
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
    ephemeral = false,
    shoot_speed = 1.5,
    damage = 10,
    range = 1,
    hp = 200,
    drops = {
      {
        name = "ability stab",
        rate = 1
      }
    }
  },
  ["minion"] = {
    enemy = false,
    targetable = true,
    ephemeral = true,
    hp = 100,
    drops = {
    }
  }
}
local Objects = {
  ["lectern"] = {
    interactable = "true"
  }
}
local DEFAULT_WORLD = {
  spawn = {x = 0, y = 0 },
  background = "tiles lightgrey white 100 100",
  entities = {
    ["dummy1"] = {
      sprite = "dummy",
      visible = "true",
      isa = "dummy",
      x = -200,
      y = -200,
      w = 80,
      h = 80
    },
    ["dummy2"] = {
      sprite = "dummy",
      visible = "true",
      isa = "dummy",
      x = 0,
      y = -200,
      w = 80,
      h = 80
    },
    ["skele1"] = {
      sprite = "skeleton",
      visible = "true",
      isa = "skeleton",
      x = 200,
      y = -200,
      w = 80,
      h = 160
    },
    ["skele2"] = {
      sprite = "skeleton",
      visible = "true",
      isa = "skeleton",
      x = 400,
      y = -200,
      w = 80,
      h = 160
    },
    ["skele3"] = {
      sprite = "skeleton",
      visible = "true",
      isa = "skeleton",
      x = 600,
      y = -200,
      w = 80,
      h = 160
    }
  },
  objects = { 
    ["above"] = {},
    ["below"] = {
      ["bin1"] = {
        sprite = "bin",
        x = 200,
        y = 200,
        w = 100,
        h = 100
      },
      ["bin2"] = {
        sprite = "bin",
        x = 200,
        y = 400,
        w = 100,
        h = 100
      },
    },
    ["collide"] = {
      ["love1"] = {
        sprite = "love",
        x = 1000,
        y = 1000,
        w = 100,
        h = 100
      },
      ["lectern1"] = {
        sprite = "lectern",
        isa = "lectern",
        x = 600,
        y = 1000,
        w = 100,
        h = 100
      }
    }
 }
}
local DEFAULT_PLAYER = {
  abilities = {
    ["summon"] = {
      locked = true,
      times_used = 0,
      slot = 1,
    },
    ["summon2"] = {
      locked = true,
      times_used = 0,
      slot = 2,
    },
    ["summon3"] = {
      locked = true,
      times_used = 0,
      slot = 3
    },
    ["invis"] = {
      locked = true,
      times_used = 0,
      slot = 4,
    },
    ["beam"] = {
      locked = true,
      times_used = 0,
      slot = 5,
    },
    ["cantrip"] = {
      locked = true,
      times_used = 0,
      slot = 6,
    },
    ["root"] = {
      locked = true,
      times_used = 0,
      slot = 7,
    },
    ["rage"] = {
      locked = true,
      times_used = 0,
      slot = 8
    },
    ["reflect"] = {
      locked = true,
      times_used = 0,
      slot = 9
    },
    ["stun"] = {
      locked = true,
      times_used = 0,
      slot = 10
    },
    
  },
  avatar = "jason",
  shoot_speed = 4,
  range = 1,
  damage = 10,
  hp = PLAYER_HP
}


----> UI
local Anchor = {
  RIGHT = "r",
  BOTTOM_RIGHT = "br",
  BOTTOM = "b",
  BOTTOM_LEFT = "bl",
  LEFT = "l",
  TOP_LEFT = "tl",
  TOP = "t",
  TOP_RIGHT = "tr",
  CENTRE = "c"
}
local UI_ABILITY_LEN = 80
local UI_ABILITY_MARGIN = 8
local UI_ABILITY_ICON_LEN = 60
local UI_ABILITY_ICON_MARGIN = 6
local UI_ABILITYBOOK_HEADER = 20
local UI_ABILITYBOOK_MARGIN = 10

--> VARIABLES
----> State
local view = nil
local debug = nil
local paused = nil

----> Debug
local log_ledger = nil
local n_logs = nil
local log_file = nil
local debug_input = nil

----> Assets
local loaded_images = nil

----> Menu

----> World
local world = nil
local world_dbg_tick = nil

----> Game
local game_keyhandlers = nil
local clicking = nil
local last_move_s = nil
local game_dbg_pos = nil
local particles = nil

----> UI
local ui = nil

----> LOVE
local key_release_callbacks = nil
local mouse_release_callbacks = nil

Abilities["beam"].use = function(world,player)
  -- Get ability target
  local target = world.entities[player.shoot_target.name]
  if target == nil then return nil end

  local a = {}

  -- Beam won't follow the target
  a.target = {
    x = target.x,
    y = target.y
  }

  a.t0 = world.tick
  a.last_dmg = nil
  a.id = id()

  a.get_endpoint = function()
    local dx = player.x - a.target.x
    local dy = player.y - a.target.y

    if dx == 0 then
      if dy < 0 then 
        return {
          x = player.x,
          y = player.y - BIGNUM
        }
      else
        return { 
          x = player.x,
          y = player.y - BIGNUM
        }
      end
    else
      local m = dy/dx

      if dx < 0 then
        return { 
          x = player.x + BIGNUM,
          y = player.y + BIGNUM * m
        }
      else
        return {
          x = player.x - BIGNUM,
          y = player.y - BIGNUM * m
        }
      end
    end
  end

  -- Update
  a.update = function()

    -- Deal damage
    if a.last_dmg == nil or world.tick > (a.last_dmg + math.floor(TPS / Abilities["beam"].frequency)) then
      a.last_dmg = world.tick

      local endpoint = a.get_endpoint()

      -- Find the first object that the beam collides with
      for ename,e in pairs(world.entities) do
        local etype = Entities[e.isa]
        if etype.enemy and line_intersects_rect(player.x,player.y,endpoint.x,endpoint.y,e.x-e.w/2,e.y-e.h/2,e.w,e.h) then
          deal_entity_damage(ename,Abilities["beam"].damage)
        end
      end
    end

    return true
  end

  -- Draw
  a.draw = function()
    local endpoint = a.get_endpoint()
    local targetpos = world_to_screen(endpoint.x,endpoint.y)
    local playerpos = world_to_screen(player.x,player.y)

    love.graphics.setColor(triangle(10,a.t0) * 0.5 + 0.5,triangle(10,a.t0) * 0.5 + 0.5,1)
    love.graphics.line(playerpos.x,playerpos.y,targetpos.x,targetpos.y)
  end

  return a
end

Abilities["stab"].use = function(world,player)
  -- Get ability target
  local target = world.entities[player.shoot_target.name]
  if target == nil then return nil end

  -- Deal damage
  deal_entity_damage(player.shoot_target.name,Abilities["stab"].damage)
end

Abilities["rage"].use = function(world,player)
  local a = {}
  a.t0 = world.tick
  a.tf = world.tick + Abilities["rage"].duration * TPS
  a.id = id()

  a.update = function()
    if world.tick > a.tf then
      return false
    else
      return true
    end
  end

  a.draw = function()

  end

  return a
end

Abilities["cantrip"].use = function(world,player)
  unlock_random(player.username,"cantrip",false)
end

Abilities["summon"].use = function(world,player)
  local a = {}
  a.t0 = world.tick
  a.tf = world.tick + Abilities["summon"].duration * TPS
  a.id = id()
  a.following = false

  local entity = {
    sprite = "summon",
    visible = true,
    isa = "minion",
    hp = 100,
    shoot_target = nil,
    last_shoot = nil,
    shoot_speed = Abilities["summon"].shoot_speed,
    damage = Abilities["summon"].damage,
    range = Abilities["summon"].range,
    x = player.x,
    y = player.y,
    w = PLAYER_L,
    h = PLAYER_L
  }

  entity.update = function()
    local dist_to_player = euclid(entity.x,entity.y,player.x,player.y)
    if dist_to_player > ENTITY_JUMP_DIST then
      entity.x = player.x
      entity.y = player.y
    elseif dist_to_player > ENTITY_FOLLOW_THRESH then
      a.following = true
    elseif dist_to_player < ENTITY_FOLLOW_DIST then
      a.following = false
    end

    if a.following then
      local pos = new_pos(entity.x,entity.y,player.x,player.y,MOVE_SPEED)
      adjust_pos_for_collisions(pos,entity.w,entity.h)

      entity.x = pos.x
      entity.y = pos.y
    end

    entity.shoot_target = player.shoot_target
  end

  world.entities["summon." .. player.username .. "." .. a.id] = entity

  a.update = function()
    if world.tick > a.tf then
      return false
    else
      return true
    end
  end

  a.draw = function()

  end

  return a
end

Abilities["summon2"].use = function(world,player)
  local a = {}
  a.t0 = world.tick
  a.tf = world.tick + Abilities["summon2"].duration * TPS
  a.id = id()
  a.following = false

  local entity = {
    sprite = "summon2",
    visible = true,
    isa = "minion",
    hp = 100,
    shoot_target = nil,
    last_shoot = nil,
    shoot_speed = Abilities["summon2"].shoot_speed,
    damage = Abilities["summon2"].damage,
    range = Abilities["summon2"].range,
    x = player.x,
    y = player.y,
    w = PLAYER_L,
    h = PLAYER_L
  }

  entity.update = function()
    local dist_to_player = euclid(entity.x,entity.y,player.x,player.y)
    if dist_to_player > ENTITY_JUMP_DIST then
      entity.x = player.x
      entity.y = player.y
    elseif dist_to_player > ENTITY_FOLLOW_THRESH then
      a.following = true
    elseif dist_to_player < ENTITY_FOLLOW_DIST then
      a.following = false
    end

    if a.following then
      local pos = new_pos(entity.x,entity.y,player.x,player.y,MOVE_SPEED)
      adjust_pos_for_collisions(pos,entity.w,entity.h)

      entity.x = pos.x
      entity.y = pos.y
    end

    entity.shoot_target = player.shoot_target
  end

  world.entities["summon2." .. player.username .. "." .. a.id] = entity

  a.update = function()
    if world.tick > a.tf then
      return false
    else
      return true
    end
  end

  a.draw = function()

  end

  return a
end

Abilities["summon3"].use = function(world,player)
  local a = {}
  a.t0 = world.tick
  a.tf = world.tick + Abilities["summon3"].duration * TPS
  a.id = id()
  a.following = false

  local entity = {
    sprite = "summon3",
    visible = true,
    isa = "minion",
    hp = 100,
    shoot_target = nil,
    last_shoot = nil,
    shoot_speed = Abilities["summon3"].shoot_speed,
    damage = Abilities["summon3"].damage,
    range = Abilities["summon3"].range,
    x = player.x,
    y = player.y,
    w = PLAYER_L,
    h = PLAYER_L
  }

  entity.update = function()
    local dist_to_player = euclid(entity.x,entity.y,player.x,player.y)
    if dist_to_player > ENTITY_JUMP_DIST then
      entity.x = player.x
      entity.y = player.y
    elseif dist_to_player > ENTITY_FOLLOW_THRESH then
      a.following = true
    elseif dist_to_player < ENTITY_FOLLOW_DIST then
      a.following = false
    end

    if a.following then
      local pos = new_pos(entity.x,entity.y,player.x,player.y,MOVE_SPEED)
      adjust_pos_for_collisions(pos,entity.w,entity.h)

      entity.x = pos.x
      entity.y = pos.y
    end

    entity.shoot_target = player.shoot_target
  end

  world.entities["summon3." .. player.username .. "." .. a.id] = entity

  a.update = function()
    if world.tick > a.tf then
      return false
    else
      return true
    end
  end

  a.draw = function()

  end

  return a
end

Abilities["reflect"].use = function(world,player)
  local a = {}
  a.t0 = world.tick
  a.tf = world.tick + Abilities["rage"].duration * TPS
  a.id = id()
  a.rad = math.sqrt(2*(PLAYER_L/2)^2)

  a.update = function()
    if world.tick > a.tf then
      return false
    else
      return true
    end
  end

  a.draw = function()
    local pos = world_to_screen(player.x,player.y)

    love.graphics.setColor(1,0.2,0,0.2)
    love.graphics.circle("fill",pos.x,pos.y,a.rad)
  end

  return a
end

--> UTILS
----> Get screen world bounds
function id()
    local template ='xxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function screen_coords(x,y)
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  
  return {
    xc = x,
    yc = y,
    x1 = x - w/2,
    x2 = x + w/2,
    y1 = y - h/2,
    y2 = y + h/2
  }
end

function triangle(hz,phase)
  if phase == nil then phase = 0 end
  local period = 1 / hz
  local half_period = period / 2
  local x = (love.timer.getTime() + phase) % period
  if x < half_period then
    return x / half_period
  else
    return 1 - ((x - half_period) / half_period)
  end
end

function saw(hz,phase)
  if phase == nil then phase = 0 end
  local period = 1 / hz
  local x = (love.timer.getTime() + phase) % period
  return x / period
end

function square(hz,phase)
  if phase == nil then phase = 0 end
  local period = 1 / hz
  local half_period = period / 2
  local x = (love.timer.getTime() + phase) % period
  if x < half_period then
    return 1
  else
    return 0
  end
end

function new_pos(x1,y1,x2,y2,speed)
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

function split_delim(str,delim)
  local str_arr = {}
  for x in str:gmatch("([^"..delim.."]+)"..delim.."?") do
    table.insert(str_arr,x)
  end

  return str_arr
end

function split_spaces(str)
  local str_arr = {}
  for x in str:gmatch("([^ ]+) ?") do
    table.insert(str_arr,x)
  end

  return str_arr
end

function euclid(x1,y1,x2,y2)
  return math.sqrt((x1 - x2) ^2 + (y1 - y2) ^2)
end

function quadrant(x,y)
  if y >= 0 then
    if x >= 0 then return 1 else return 2 end
  else
    if x < 0 then return 3 else return 4 end
  end
end

function line_intersects_rect(lx1,ly1,lx2,ly2,rx,ry,rw,rh)
  -- Get corners of rectangle
  local rx1 = rx
  local ry1 = ry
  local rx2 = rx + rw
  local ry2 = ry + rh

  -- Check in rectangle
  if rx1 < lx1 and lx1 < rx2 and ry1 < ly1 and ly1 < ry2 then
    return true
  end
  if rx1 < lx2 and lx2 < rx2 and ry1 < ly2 and ly2 < ry2 then
    return true
  end

  -- Get corner deltas
  local drx1 = rx1 - lx1
  local dry1 = ry1 - ly1
  local drx2 = rx2 - lx1
  local dry2 = ry2 - ly1

  -- Get endpoint deltas
  local dlx = lx2 - lx1
  local dly = ly2 - ly1

  -- Get quadrant for each corner
  local c1q = quadrant(drx2,dry2)
  local c2q = quadrant(drx1,dry2)
  local c3q = quadrant(drx1,dry1)
  local c4q = quadrant(drx2,dry1)

  -- Get endpoint quadrant
  local eq = quadrant(dlx,dly)

  -- Get the first and last quadrants for the rectangle's corners
  local first_quad = c1q
  local last_quad = c1q

  if c2q > last_quad then 
    last_quad = c2q
  elseif c2q < first_quad then 
    first_quad = c2q 
  end

  if c3q > last_quad then
    last_quad = c3q
  elseif c3q < first_quad then
    first_quad = c3q
  end

  if c4q > last_quad then
    last_quad = c4q
  elseif c4q < first_quad then
    first_quad = c4q
  end
  
  -- Check if first or last quadrant are shared with endpoint
  if eq ~= first_quad and eq ~= last_quad then
    return false
  end

  -- Check if quadrants are the same
  local mono_quad = (first_quad == last_quad)
  if mono_quad then
    -- All in one quad

    -- Check if shooting vertically
    if math.abs(dlx) < 0.0001 then
      if math.abs(drx1) < 0.0001 or math.abs(drx2) < 0.0001 then
        return true
      else
        return false
      end
    end

    local m = dly / dlx
    local mr_lower = nil
    local mr_upper = nil

    if first_quad == 1 then
      mr_lower = dry1 / drx2
      mr_upper = dry2 / drx1
    elseif first_quad == 2 then
      mr_lower = dry2 / drx2
      mr_upper = dry1 / drx1
    elseif first_quad == 3 then
      mr_lower = dry2 / drx1
      mr_upper = dry1 / drx2
    else
      mr_lower = dry1 / drx1
      mr_upper = dry2 / drx2
    end

    if mr_lower < m and m < mr_upper then
      return true
    else
      return false
    end
  else
    -- Rectangle straddles quads
    
    -- Check if invgrad should be used to prevent sign flip
    local invgrad = false
    if first_quad == 1 and last_quad == 2 then
      invgrad = true
    elseif first_quad == 3 and last_quad == 4 then
      invgrad = true
    end

    local dl = nil
    local dr1 = nil
    local dr2 = nil
    
    if not invgrad then
      dl = dlx
      dr1 = drx1
      dr2 = drx2
    else
      dl = dly
      dr1 = dry1
      dr2 = dry2
    end

    -- Check if shooting vertically
    if math.abs(dl) < 0.0001 then
      if math.abs(dr1) < 0.0001 or math.abs(dr2) < 0.0001 then
        return true
      else
        return false
      end
    end

    local m = nil
    if not invgrad then
      m = dly / dlx
    else
      m = dlx / dly
    end

    -- Calculate grad for all corners
    local mc1 = nil
    local mc2 = nil
    local mc3 = nil
    local mc4 = nil

    if not invgrad then
      mc1 = dry2 / drx2
      mc2 = dry2 / drx1
      mc3 = dry1 / drx1
      mc4 = dry1 / drx2
    else
      mc1 = drx2 / dry2
      mc2 = drx1 / dry2
      mc3 = drx2 / dry1
      mc4 = drx2 / dry1
    end

    local mcmin = mc1
    local mcmax = mc1

    if mc2 < mcmin then
      mcmin = mc2
    elseif mc2 > mcmax then
      mcmax = mc2
    end

    if mc3 < mcmin then
      mcmin = mc3
    elseif mc3 > mcmax then
      mcmax = mc3
    end

    if mc4 < mcmin then
      mcmin = mc4
    elseif mc4 > mcmax then
      mcmax = mc4
    end

    if mcmin < m and m < mcmax then
      return true
    else
      return false
    end
  end

end

function get_anchor_point(anchor,x_off,y_off,w,h)
  local sw = love.graphics.getWidth()
  local sh = love.graphics.getHeight()

  if x_off == nil then x_off = 0 end
  if y_off == nil then y_off = 0 end

  -- X anchor
  local ax = x_off
  if anchor == Anchor.TOP or anchor == Anchor.CENTRE or anchor == Anchor.BOTTOM then
    ax = ax + sw / 2 - w / 2
  elseif anchor == Anchor.RIGHT or anchor == Anchor.TOP_RIGHT or anchor == Anchor.BOTTOM_RIGHT then
    ax = ax + sw - w
  end

  -- Y anchor
  local ay = y_off
  if anchor == Anchor.LEFT or anchor == Anchor.CENTRE or anchor == Anchor.RIGHT then
    ay = ay + sh / 2 - h / 2
  elseif anchor == Anchor.BOTTOM_LEFT or anchor == Anchor.BOTTOM or anchor == Anchor.BOTTOM_RIGHT then
    ay = ay + sh - h
  end

  return {
    x = ax,
    y = ay
  }
end

----> Add game UI
function ui_add_game()
  ui["abilities"] = {
    visible = true,
    anchor = Anchor.BOTTOM,
    x_off = 0,
    y_off = -10,
    w = UI_ABILITY_LEN * 5 + UI_ABILITY_MARGIN * 4,
    h = UI_ABILITY_LEN * 2 + UI_ABILITY_MARGIN
  }

  ui["abilities_book"] = {
    visible = false,
    anchor = Anchor.CENTRE,
    selected =nil,
    learning = false,
    x_off = 0,
    y_off = 0,
    w = (UI_ABILITYBOOK_MARGIN + UI_ABILITYBOOK_MARGIN/2 + UI_ABILITY_ICON_LEN * 5 + UI_ABILITY_ICON_MARGIN * 4 + UI_ABILITYBOOK_MARGIN) * 2,
    h = UI_ABILITYBOOK_MARGIN*3 + UI_ABILITYBOOK_HEADER * 2 + UI_ABILITY_ICON_LEN * 2 + UI_ABILITY_ICON_MARGIN + UI_ABILITY_ICON_LEN * 10 + UI_ABILITY_ICON_MARGIN * 9
  }

  ui["charge_bar"] = {
    visible = true,
    anchor = Anchor.BOTTOM,
    x_off = 0,
    y_off = ui["abilities"].y_off - ui["abilities"].h - 10,
    w = ui["abilities"].w,
    h = 20
  }

  ui["health_bar"] = {
    visible = true,
    anchor = Anchor.BOTTOM,
    x_off = 0,
    y_off = ui["charge_bar"].y_off - ui["charge_bar"].h - 10,
    w = ui["abilities"].w,
    h = 20
  }
end

----> Remove game UI
function ui_remove_game()
  ui["abilities"] = nil
  ui["abilities_book"] = nil
  ui["charge_bar"] = nil
  ui["health_bar"] = nil
end


----> Log information
function log_info(message)
  if message == nil then
    message = "????"
  end
  local new_log = {
    logtype = "info",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  }
  
  table.insert(log_ledger,new_log)
  n_logs = n_logs + 1
  log_file:write(log_text(new_log) .. "\r\n")
  log_file:flush()
end

----> Log warning
function log_warning(message)
  if message == nil then
    message = "????"
  end
  local new_log = {
    logtype = "warn",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  }
  
  table.insert(log_ledger,new_log)
  n_logs = n_logs + 1
  log_file:write(log_text(new_log) .. "\r\n")
  log_file:flush()
end

----> Log error
function log_error(message)
  if message == nil then
    message = "????"
  end
  local new_log = {
    logtype = "err",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  }
  
  table.insert(log_ledger,new_log)
  n_logs = n_logs + 1
  log_file:write(log_text(new_log) .. "\r\n")
  log_file:flush()
end

--> STATE
----> Initialise
function state_init()
  view = nil
  debug = nil
  paused = nil
end



--> ASSETS
----> Initialise
function assets_init()
  loaded_images = {}
  for name,path in pairs(Images) do
    local image = love.graphics.newImage(path)
    local width = image:getWidth()
    local height = image:getHeight()
    loaded_images[name] = {
      img = image,
      w = width,
      h = height,
    }
  end
end

----> Get an image asset
function get_image(name)
  local img = loaded_images[name]
  if img == nil then
    return loaded_images["broken"]
  else
    return img
  end
end

--> MENU
----> Key handler
function menu_keyhandler(key,pressed)
  if pressed then
    if key == "space" then
      view = View.GAME
      return
    end
  end
end

----> Mouse handler
function menu_mousehandler(x,y,button,pressed)
  
end

--> WORLD
----> Initialise
function world_init()
  world = nil
  world_dbg_tick = nil
end

----> Serialize world to a file
function save_world_to(savename)
  if world ~= nil then
    local encoded = json.encode(get_world_deets())
    local f = love.filesystem.newFile(savename .. ".json")
    f:open("w")
    f:write(encoded)
    f:close()

    log_info("Saved to " .. savename)
  else
    log_warning("Cannot save, no world loaded")
  end
end

----> Deserialize world and join
function load_world_from(savename)
  local savefile = savename .. ".json"
  local f_details = love.filesystem.getInfo(savefile)
  if f_details == nil then
    log_warning("No save file called " .. savefile)
    return
  end
  local f = love.filesystem.newFile(savefile)
  f:open("r")
  local encoded = f:read()
  f:close()
  local world_deets = json.decode(encoded)
  world_load(world_deets)
  world_join(DEFAULT_USERNAME)
  view = View.GAME
  ui_add_game()
end

----> Draw backgroudn
function draw_background(bg,x,y)
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  
  local pattern = split_spaces(bg)
  
  if pattern[1] == "tiles" then
    local col1 = pattern[2]
    local col2 = pattern[3]
    local tilew = tonumber(pattern[4])
    local tileh = tonumber(pattern[5])

    local x1 = x - w/2
    local y1 = y - h/2
    local x2 = x + w/2
    local y2 = y + h/2
    
    local i1 = math.floor(x1 / tilew)
    local i2 = math.ceil(x2 / tilew)
    local j1 = math.floor(y1 / tileh)
    local j2 = math.ceil(y2 / tileh)
    
    for i = i1,i2,1 do
      for j = j1,j2,1 do
        local x = i*tilew - x1
        local y = j*tileh - y1
        
        local col = nil
        if (i + j) % 2 == 0 then
          col = Color[col1]
        else
          col = Color[col2]
        end
        
        love.graphics.setColor(col)
        love.graphics.rectangle('fill',x,y,tilew,tileh)
      end
    end
  end
end

----> Create entity update
function create_entity_update(entity)
  if entity.isa == "skeleton" then
    return function()
      if not entity.shooting then
        entity.shooting = true
      end

      local closest_player = nil
      local min_dist = nil
      for username,player in pairs(world.players) do
        local d = euclid(player.x,player.y,entity.x,entity.y)

        if closest_player == nil or d < min_dist then
          closest_player = username
          min_dist = d
        end
      end

      if closest_player ~= nil then
        entity.shoot_target = {
          type = "player",
          name = closest_player
        }
      end
    end
  elseif entity.isa == "dummy" then
    return function()
      if not entity.shooting then
        entity.shooting = true
      end

      local closest_player = nil
      local min_dist = nil
      for username,player in pairs(world.players) do
        local d = euclid(player.x,player.y,entity.x,entity.y)

        if closest_player == nil or d < min_dist then
          closest_player = username
          min_dist = d
        end
      end

      if closest_player ~= nil then
        entity.shoot_target = {
          type = "player",
          name = closest_player
        }
      end
    end
  else
    return function() end
  end
end

----> Get entity
function get_entity(name)
  if world ~= nil and world.entities[name] ~= nil then
    return world.entities[name]
  end
end

function world_draw_objects(layername)
  if world ~= nil and world.objects[layername] ~= nil then
    local objs = world.objects[layername]

    for _,o in pairs(objs) do
      local pos = world_to_screen(o.x,o.y)
      local img = get_image(o.sprite)
      local xscale = o.w / img.w
      local yscale = o.h / img.h
      love.graphics.setColor(1,1,1)
      love.graphics.draw(img.img, pos.x-o.w/2,pos.y-o.h/2,0,xscale,yscale)
    end
  end
end

----> Get shoot target position
function get_target_pos(target)
  if target.type == "entity" then
    local entity = world.entities[target.name]
    if entity == nil then return nil end
    return {
      x = entity.x,
      y = entity.y
    }
  elseif target.type == "player" then
    local player = world.players[target.name]
    if player == nil then return nil end
    return {
      x = player.x,
      y = player.y
    }
  elseif target.type == "pos" then
    return {
      x = target.x,
      y = target.y
    }
  else return nil end
end

----> Draw
function world_draw()
  local player = world.players[DEFAULT_USERNAME]
  local bg = world.background
  
  if bg ~= nil then
    draw_background(bg,player.x - OFFSET_X,player.y - OFFSET_Y)
  end

  world_draw_objects("below")

  world_draw_objects("collide")

  local entities = world.entities
  for ename,e in pairs(entities) do
    if e.visible then
      -- Entity image
      local entity = Entities[e.isa] 
      local pos = world_to_screen(e.x,e.y)
      local img = get_image(e.sprite)
      local xscale = e.w / img.w
      local yscale = e.h / img.h
      love.graphics.setColor(1,1,1)
      love.graphics.draw(img.img,pos.x-e.w/2,pos.y-e.h/2,0,xscale,yscale)

      if entity.targetable and entity.enemy then
        love.graphics.setColor(1,triangle(0.5),0)
        love.graphics.rectangle("line",pos.x-e.w/2-5,pos.y-e.h/2-5,e.w+10,e.h+10)
      end

      -- Entity HP bar
      local hpw = 80
      local hph = 10
      love.graphics.setColor(0,0,0)
      love.graphics.rectangle("fill",pos.x - hpw/2,pos.y + e.h/2 + hph,hpw,hph)
      local hpv = (e.hp / entity.hp) * hpw
      love.graphics.setColor(0,1,0)
      love.graphics.rectangle("fill",pos.x - hpw/2,pos.y + e.h/2 + hph,hpv,hph)

    end
  end
  

  local players = world.players
  for username,p in pairs(players) do
    -- Move target
    if username == DEFAULT_USERNAME and p.move_target ~= nil then
      local tpos = world_to_screen(p.move_target.x,p.move_target.y)
      love.graphics.setColor(0,1,0)
      love.graphics.circle("fill",tpos.x,tpos.y,PLAYER_L/8)
    end

    -- Player drops
    for _,drop in pairs(p.drops) do
      local parts = split_spaces(drop.name)
      local pos = world_to_screen(drop.x,drop.y)
      if parts[1] == "ability" then
        local img = get_image(parts[2])
        local xscale = DROP_L / img.w
        local yscale = DROP_L / img.h
        love.graphics.setColor(1,1,1)
        love.graphics.draw(img.img,pos.x-DROP_L/2,pos.y- DROP_L/2,0,xscale,yscale)

        love.graphics.setColor(0.615,0,1)
        love.graphics.rectangle("line",pos.x-DROP_L/2,pos.y - DROP_L/2,DROP_L,DROP_L)
      end
    end

    -- Player avatar
    local pos = world_to_screen(p.x,p.y)
    local img = get_image(p.avatar)
    local xscale = PLAYER_L / img.w
    local yscale = PLAYER_L / img.h
    love.graphics.setColor(1,1,1)
    love.graphics.draw(img.img,pos.x - PLAYER_L/2,pos.y - PLAYER_L/2,0,xscale,yscale)

    -- Player abilities
    for aname,aabils in pairs(player.active_abilities) do
      for _,aabil in pairs(aabils) do
        aabil.draw()
      end
    end

    -- Player shoot target
    if username == DEFAULT_USERNAME and p.shoot_target ~= nil then
      local spos = nil
      local wt = PLAYER_L
      local ht = PLAYER_L
      if p.shoot_target.type == "pos" then
        spos = world_to_screen(p.shoot_target.x,p.shoot_target.y)
      elseif p.shoot_target.type == "entity" then
        local ent = get_entity(p.shoot_target.name)
        if ent == nil then
          goto notarget
        end
        spos = world_to_screen(ent.x,ent.y)
        wt = ent.w
        ht = ent.h
      else
        spos = world_to_screen(0,0)
      end
      local img = get_image("target")
      local xscale = PLAYER_L / img.w / 2
      local yscale = PLAYER_L / img.h / 2
      love.graphics.setColor(1,1,1)
      love.graphics.draw(img.img,spos.x - PLAYER_L / 4, spos.y - PLAYER_L / 4,0,xscale,yscale)
    end



    ::notarget::
  end

  local bullets = world.bullets
  for _,bullet in pairs(bullets) do
    local bpos = world_to_screen(bullet.x,bullet.y)
    love.graphics.setColor(1,0,0)
    love.graphics.circle("fill",bpos.x,bpos.y,BULLET_RADIUS)
  end

  world_draw_objects("above")

end

----> Have player shoot at something
function shoot_bullet(player)
  if player.shoot_target ~= nil then
    local new_bullet = {
      source = "player " .. player.username,
      x = player.x,
      y = player.y,
      flying = true,
    }

    if player.shoot_target.type == "entity" then
      local ent = get_entity(player.shoot_target.name)
      if ent == nil then
        player.shoot_target = nil
        return
      end

      new_bullet.target = {
        type = "entity",
        name = player.shoot_target.name
      }
    elseif player.shoot_target.type == "pos" then
      new_bullet.target = {
        type = "pos",
        x = player.shoot_target.x,
        y = player.shoot_target.y
      }
    else
      new_bullet.target = {
        type = "pos",
        x = 0,
        y = 0
      }
    end

    table.insert(world.bullets,new_bullet)
  end
end

----> Have entity shoot at something
function entity_shoot_bullet(ename)
  local entity = world.entities[ename]
  if entity == nil then return false end

  if entity.shoot_target ~= nil then
    local new_bullet = {
      source = "entity " .. ename,
      x = entity.x,
      y = entity.y,
      flying = true,
    }

    if entity.shoot_target.type == "entity" then
      local ent = get_entity(entity.shoot_target.name)
      if ent == nil then
        entity.shoot_target = nil
        return
      end

      new_bullet.target = {
        type = "entity",
        name = entity.shoot_target.name
      }
    elseif entity.shoot_target.type == "pos" then
      new_bullet.target = {
        type = "pos",
        x = entity.shoot_target.x,
        y = entity.shoot_target.y
      }
    elseif entity.shoot_target.type == "player" then
      local player = world.players[entity.shoot_target.name]
      if player == nil then
        entity.shoot_target = nil
        return
      end

      new_bullet.target = {
        type = "player",
        name = entity.shoot_target.name
      }
    else
      new_bullet.target = {
        type = "pos",
        x = 0,
        y = 0
      }
    end

    table.insert(world.bullets,new_bullet)
  end
end

function check_collision(x,y,w,h,xo,yo,wo,ho)
  local x_coll = (x <= xo and (x + w / 2 >= xo - wo / 2)) or (x >= xo and (x - w / 2 <= xo + wo / 2))
  local y_coll = (y <= yo and (y + h / 2 >= yo - ho / 2)) or (y >= yo and (y - h / 2 <= yo + ho / 2))

  if x_coll and y_coll then
    -- There is a collision
    -- Which side of the object is colliding?
    -- i.e. Which side of the object is furthest from the adjacent side of the entity?
    local sides = {}
    sides[1] = (x - w/2 + 2) - (xo + wo/2)
    sides[2] = (y - h/2 + 2) - (yo + ho/2)
    sides[3] = (xo - wo/2) - (x + w/2 - 2)
    sides[4] = (yo - ho/2) - (y + h/2 - 2)
    
    local furthest = 1
    
    if sides[2] > sides[furthest] then furthest = 2 end
    if sides[3] > sides[furthest] then furthest = 3 end
    if sides[4] > sides[furthest] then furthest = 4 end

    return furthest
  end

  return nil
end

function check_all_collisions(x,y,w,h)
  local collisions = {}

  -- Check collisions
  if world.objects["collide"] ~= nil then
    for name,obj in pairs(world.objects["collide"]) do
      local side = check_collision(x,y,w,h,obj.x,obj.y,obj.w,obj.h)

      if side ~= nil then
        table.insert(collisions,{
          obj = obj,
          side = side
        })
      end
    end
  end

  return collisions
end

function adjust_pos_for_collisions(pos,w,h)
  local collisions = check_all_collisions(pos.x,pos.y,w,h)

  for _,collision in pairs(collisions) do
    pos.arrived = false
    if collision.side == 1 then
      pos.x = collision.obj.x + collision.obj.w / 2 + w / 2
    elseif collision.side == 2 then
      pos.y = collision.obj.y + collision.obj.h / 2 + h / 2
    elseif collision.side == 3 then
      pos.x = collision.obj.x - collision.obj.w / 2 - w / 2
    elseif collision.side == 4 then
      pos.y = collision.obj.y - collision.obj.h / 2 - h / 2
    end
  end
end

----> Update player
function update_player(player,tick)
  if player.move_target ~= nil then
    local new_pos = new_pos(player.x,player.y,player.move_target.x,player.move_target.y,MOVE_SPEED)
    adjust_pos_for_collisions(new_pos,PLAYER_L,PLAYER_L)
    
    player.x = new_pos.x
    player.y = new_pos.y
    if new_pos.arrived then
      player.move_target = nil
    end
  end

  -- Player abilities
  for aname,aabils in pairs(player.active_abilities) do
    for id,aabil in pairs(aabils) do
      local ability_def = Abilities[aname]
      local cancel = false

      -- Cancel stationary ability if player moves
      if ability_def.stationary then
        if player.move_target ~= nil then
          cancel = true
        end
      end

      -- Cancel channeling if player uses another ability or shoots
      if ability_def.channel then
        if player.ability_channeling ~= aabil or player.shooting ~= false then
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

  if player.shooting and player.shoot_target ~= nil then
    local shoot_speed = player.shoot_speed
    for _,rage in pairs(player.active_abilities["rage"]) do
      shoot_speed = shoot_speed * 2
    end
    local shoot_period = TPS / shoot_speed

    local target_pos = get_target_pos(player.shoot_target)
    if target_pos ~= nil then
      local target_dist = euclid(target_pos.x,target_pos.y,player.x,player.y)
      if target_dist <= get_pixel_range(player.range) then
        if player.last_shoot == nil or tick - player.last_shoot > shoot_period then
          shoot_bullet(player)
          player.last_shoot = tick
        end
      end
    end
  end

  game_dbg_pos = {
    x = player.x,
    y = player.y
  }
end

function get_pixel_range(range)
  return range * MOVE_SPEED
end

----> Can use ability
function can_use_ability(username,ability_name)
  local ability_def = Abilities[ability_name]
  local player = world.players[username]
  if ability_def == nil or player == nil then return false end

  if player.abilities[ability_name].locked then return false end

  if ability_def.target then
    if player.shoot_target == nil then
      return false
    end
    
    local target = nil
    if player.shoot_target.type == "entity" then
      local ent = world.entities[player.shoot_target.name]
      if ent == nil then
        return false
      end

      target = {
        x = ent.x,
        y = ent.y
      }
    elseif player.shoot_target.type == "player" and world.entities[player.shoot_target.name] == nil then
      local player = world.players[player.shoot_target.name]
      if player == nil then
        return false
      end

      target = {
        x = player.x,
        y = player.y
      }
    elseif player.shoot_target.type == "pos" then
      target = {
        x = player.shoot_target.x,
        y = player.shoot_target.y
      }
    end

    local pixelrange = ability_def.range * MOVE_SPEED
    local dist = euclid(target.x,target.y,player.x,player.y)

    if dist > pixelrange then
      return false
    end
  end

  return true
end

----> Player uses ability
function use_ability(username,ability_num)
  if world ~= nil and world.players[username] ~= nil then
    local player = world.players[username]

    local ability_name = player.ability_map[ability_num]
    local ability_def = Abilities[ability_name]
    if not can_use_ability(player.username,ability_name) then
      log_info("Can't use" .. ability_name)
      return
    end

    -- Lock ability
    player.abilities[ability_name].locked = true

    -- Stationary ability
    if ability_def.stationary then
      player.move_target = nil -- Stationary
      last_move_s = love.timer.getTime()
    end

    -- Call use
    local active_ability = ability_def.use(world,player)
    if active_ability == nil then
      log_info("Failed to use " .. ability_name)
      return
    end

    -- Unlock abilities
    if player.charge >= CHARGE_TO_UNLOCK then
      unlock_random(username)
    end

    -- Channel ability
    if ability_def.channel then
      player.ability_channeling = active_ability
      player.shooting = false
    else
      player.ability_channeling = nil
    end

    if active_ability ~= nil then
      local id = active_ability.id
      if id == nil then id = id() end

      player.active_abilities[ability_name][id] = active_ability
      player.abilities[ability_name].times_used = player.abilities[ability_name].times_used + 1 -- Lua moment
    end
  end
end

----> Create hit particle
function create_hit_particle(damage,x,y,h)
  local t0 = love.timer.getTime()
  local freq = 2
  local phase = math.random() / freq
  table.insert(particles,{
    text = "-" .. tostring(damage),
    size = 20,
    color = {1,0,0},
    x = x,
    y = y,
    should_destroy = function(p)
      p.color = {1,0,triangle(freq,phase)}
      p.y = p.y + ((y - h) - p.y) / 16
      p.x = x + 10 * (triangle(freq,phase) - 0.5)
      if love.timer.getTime() - t0 > 0.7 then
        return true
      else
        return false
      end
    end
  })
end

----> Deal entity damage
function deal_entity_damage(ename,dmg,interrupt)
  if interrupt == nil then interrupt = false end

  local ent = get_entity(ename)

  local entitytype = Entities[ent.isa]
  ent.hp = ent.hp - dmg

  create_hit_particle(dmg,ent.x,ent.y,ent.h/2 + 20)
  
  -- Die
  if ent.hp <= 0 then
    if entitytype.drops ~= nil then
      local players = world.players
      for name,player in pairs(players) do
        for _,drop in pairs(entitytype.drops) do
          if math.random() < drop.rate then
            table.insert(player.drops,{
              name = drop.name,
              x = ent.x + (0.5 - math.random()) * DROP_L / 2,
              y = ent.y + (0.5 - math.random()) * DROP_L / 2
            })
          end
        end
      end
    end

    -- Remove the entity
    world.entities[ename] = nil
  end
end

----> Deal player damage
function deal_player_damage(username,dmg,interrupt)
  if interrupt == nil then interrupt = false end

  local player = world.players[username]
  if player == nil then return end

  player.hp = player.hp - dmg

  create_hit_particle(dmg,player.x,player.y,PLAYER_L/2 + 20)
  
  -- Die
  if player.hp <= 0 then
    -- Remove the entity
    world_join(username)
  end
end

----> Unlock a random ability
function unlock_random(username,exclude,reset_charge)
  if reset_charge == nil then reset_charge = true end

  if world.players[username] == nil then
    return
  end
  
  local player = world.players[username]
  local n_unlocked = 0
  local n_locked = 0
  local locked_abils = {}
  for aname,abil in pairs(player.abilities) do
    if not abil.locked then
      n_unlocked = n_unlocked + 1
    elseif abil.slot ~= -1 then
      if exclude ~= aname then
        table.insert(locked_abils,aname)
        n_locked = n_locked + 1
      end
    end
  end

  if n_unlocked < MAX_UNLOCKED then
    local i = math.random(1,n_locked)
    local unlocking = locked_abils[i]
    if reset_charge then player.charge = 0 end
    player.abilities[unlocking].locked = false
  end
end

----> Resolve bullet
function resolve_bullet(bullet)
  -- Create hit particle
  local source = bullet.source
  local source_parts = split_spaces(source)
  if source_parts[1] == "player" then
    if world.players[source_parts[2]] ~= nil then
      local player = world.players[source_parts[2]]
      if bullet.target.type == "entity" then
        deal_entity_damage(bullet.target.name,player.damage)
      end

      player.charge = player.charge + 1
      if player.charge >= CHARGE_TO_UNLOCK then
        player.charge = CHARGE_TO_UNLOCK
        unlock_random(source_parts[2])
      end
    end
  elseif source_parts[1] == "entity" then
    if world.entities[source_parts[2]] ~= nil then
      local entity = world.entities[source_parts[2]]
      if bullet.target.type == "entity" then
        deal_entity_damage(bullet.target.name,entity.damage)
      elseif bullet.target.type == "player" then
        deal_player_damage(bullet.target.name,entity.damage,false)
      end
    end
  end
end

----> Player pickup drop
function pickup(username,i)
  local player = world.players[username]
  if player ~= nil then
    local drop_name = player.drops[i].name
    local parts = split_spaces(drop_name)

    if parts[1] == "ability" then
      if player.abilities[parts[2]] == nil then
        player.abilities[parts[2]] = {
          slot = -1,
          times_used = 0
        }
      end
    end

    player.drops[i] = nil
  end
end

----> Interact with object
function interact(username,layer,objname)
  local player = world.players[username]
  if player ~= nil and world.objects[layer] ~= nil then
    local obj = world.objects[layer][objname]

    if obj.isa ~= nil then
      if obj.isa == "lectern" then
        if ui["abilities_book"] ~= nil then
          ui["abilities_book"].visible = true
        end
      end
    end
  end
end

----> Update
function world_update()
  if world ~= nil then
    world.tick = world.tick + 1
    world_dbg_tick = world.tick
    
    local players = world.players
    for name,player in pairs(players) do
      update_player(player,world.tick)
    end

    local entities = world.entities
    for ename,entity in pairs(entities) do
      local parts = split_delim(ename,".")

      -- Update entity
      if entity.update ~= nil then
        entity.update()
      end

      -- Check minion ability is still active
      if entity.isa == "minion" then
        local player_name = parts[2]

        local active = false
        local summon_ability = parts[1]
        local id = parts[3]

        local player = world.players[player_name]
        if player ~= nil and player.active_abilities[summon_ability] ~= nil and player.active_abilities[summon_ability][id] ~= nil then
          active = true
        end

        if not active then
          world.entities[ename] = nil
          goto continue
        end
      end

      -- Entity shoot
      if entity.shoot_target ~= nil then
        local shoot_speed = entity.shoot_speed
        local shoot_period = TPS / shoot_speed

        local target_pos = get_target_pos(entity.shoot_target)
        if target_pos ~= nil then
          local target_dist = euclid(entity.x,entity.y,target_pos.x,target_pos.y)
          if target_dist <= get_pixel_range(entity.range) then
            if entity.last_shoot == nil or world.tick - entity.last_shoot > shoot_period then
              entity_shoot_bullet(ename)
              entity.last_shoot = world.tick
            end
          end
        end
      end

      ::continue::
    end

    local bullets = world.bullets
    for i,bullet in pairs(bullets) do
      local source_parts = split_spaces(bullet.source)

      if bullet.target ~= nil then
        local p = nil
        if bullet.target.type == "entity" then
          local ent = get_entity(bullet.target.name)
          if ent == nil then
            bullets[i] = nil
            goto continue
          end
          p = new_pos(bullet.x,bullet.y,ent.x,ent.y,BULLET_SPEED)
        elseif bullet.target.type == "pos" then
          p = new_pos(bullet.x,bullet.y,bullet.target.x,bullet.target.y,BULLET_SPEED)
        elseif bullet.target.type == "player" then
          local player = world.players[bullet.target.name]
          if player == nil then
            bullets[i] = nil
            goto continue
          end

          p = new_pos(bullet.x,bullet.y,player.x,player.y,BULLET_SPEED)
        else return
        end

        local collisions = check_all_collisions(p.x,p.y,BULLET_RADIUS*1.4,BULLET_RADIUS*1.4)

        for _,collision in pairs(collisions) do
          bullets[i] = nil
          goto continue
        end

        bullet.x = p.x
        bullet.y = p.y
        if p.arrived then
          bullet.flying = false
        end
      end

      if not bullet.flying then
        local has_reflect = false

        if bullet.target.type == "player" then
          local player = world.players[bullet.target.name]

          for i,abil in pairs(player.active_abilities["reflect"]) do
            has_reflect = true
          end
        end

        if has_reflect then
          bullet.target.type = source_parts[1]
          bullet.target.name = source_parts[2]
          bullet.flying = true
        else
          resolve_bullet(bullet)
          bullets[i] = nil 
        end
      end
      ::continue::
    end
  end
end

----> Get world deets
function get_world_deets()
  if world == nil then return nil end

  local world_objs = {}
  for layername,layer in pairs(world.objects) do
    world_objs[layername] = {}
    for name,o in pairs(layer) do
      world_objs[layername][name] = {
        sprite = o.sprite,
        isa = o.isa,
        x = o.x,
        y = o.y,
        w = o.w,
        h = o.h
      }
    end
  end

  local world_ents = {}
  for ename,e in pairs(world.entities) do
    if not Entities[e.isa].ephemeral then
      world_ents[ename] = {
        sprite = e.sprite,
        visible = e.visible,
        isa = e.isa,
        x = e.x,
        y = e.y,
        w = e.w,
        h = e.h
      }
    end
  end

  local world_deets = {
    spawn = {
      x = world.spawn.x,
      y = world.spawn.y,
    },
    background = world.background,
    entities = world_ents,
    objects = world_objs
  }

  return world_deets
end

----> Load world
function world_load(world_deets)
  log_info("Loading a new world.")

  local new_world_objs = {}
  if world_deets.objects ~= nil then
    for layername,layer in pairs(world_deets.objects) do
      new_world_objs[layername] = {}
      for name,o in pairs(layer) do
        new_world_objs[layername][name] = {
          sprite = o.sprite,
          isa = o.isa,
          x = o.x,
          y = o.y,
          w = o.w,
          h = o.h
        }
      end
    end
  end

  local new_world_entities = {}
  if world_deets.entities ~= nil then
    for ename,edef in pairs(world_deets.entities) do
      local entitytype = Entities[edef.isa]
      new_world_entities[ename] = {
        sprite = edef.sprite,
        visible = edef.visible,
        shoot_speed = entitytype.shoot_speed,
        damage = entitytype.damage,
        range = entitytype.range,
        isa = edef.isa,
        hp = entitytype.hp,
        x = edef.x,
        y = edef.y,
        w = edef.w,
        h = edef.h
      }

      new_world_entities[ename].update = create_entity_update(new_world_entities[ename])
    end
  end
  
  local new_world = {
    tick = 0,
    spawn = {
      x = world_deets.spawn.x,
      y = world_deets.spawn.y,
    },
    background = world_deets.background,
    players = {},
    objects = new_world_objs,
    entities = new_world_entities,
    bullets = {}
  }
  
  world = new_world
end

----> Get player deets
function get_player_deets(username)
  
end

----> Join world
function world_join(username)
  log_info(username .. " joined!")
  
  local abils = {}
  local abilmap = {}
  for name,abil in pairs(DEFAULT_PLAYER.abilities) do
    abils[name] = {
      locked = abil.locked,
      times_used = abil.times_used,
      slot = abil.slot
    }
    if abil.slot ~= -1 then
      abilmap[abil.slot] = name
    end
  end

  local active_abils = {}
  for name,abildef in pairs(Abilities) do
    active_abils[name] = {}
  end


  local spawn = world.spawn
  local new_player = {
    username = username,
    abilities = abils,
    ability_map = abilmap,
    active_abilities = active_abils,
    avatar = DEFAULT_PLAYER.avatar,
    shoot_speed = DEFAULT_PLAYER.shoot_speed,
    damage = DEFAULT_PLAYER.damage,
    hp = DEFAULT_PLAYER.hp,
    range = DEFAULT_PLAYER.range,
    charge = 0,
    drops = {},
    x = spawn.x,
    y = spawn.y,
    move_target = nil,
    shoot_target = nil,
    shooting = false,
    last_shoot = nil,
  }
  
  world.players[username] = new_player
end

----> Set move target
function set_target(username,x,y)
  if world ~= nil and world.players[username] ~= nil then
    local player = world.players[username]
    player.move_target = {
      x = x,
      y = y
    }
  end
end

----> Check if player is shooting
function is_shooting(username)
  if world ~= nil and world.players[username] ~= nil then
    return world.players[username].shooting
  end
end

----> Set player shooting
function set_shooting(username,is_shooting)
  if world ~= nil and world.players[username] ~= nil then
    world.players[username].shooting = is_shooting
  end
end
function toggle_shooting(username)
  log_info("Toggling shooting for " .. username)
  if world ~= nil and world.players[username] ~= nil then
    world.players[username].shooting = not world.players[username].shooting
  end
end

----> Set shoot target position
function set_shoot_target(username,x,y)
  if world ~= nil and world.players[username] ~= nil then
    local player = world.players[username]
    
    local closest = nil
    local distance = nil
    for ename,e in pairs(world.entities) do
      local etype = Entities[e.isa]
      if etype.targetable and etype.enemy and e.hp > 0 then
        local d = euclid(x,y,e.x,e.y)
        if closest == nil or d < distance then
          closest = ename
          distance = d
        end
      end
    end

    if closest ~= nil then
      player.shoot_target = {
        type = "entity",
        name = closest
      }
    end
  end
end
function clear_shoot_target(username)
  if world ~= nil and world.players[username] ~= nil then
    local player = world.players[username]

    player.shoot_target = nil
  end
end

function shoot_nearest(username)
  if world ~= nil and world.players[username] ~= nil then
    local player = world.players[username]
    set_shoot_target(username,player.x,player.y)
  end
end

----> Convert screen to world
function screen_to_world(x,y)
  if world == nil or world.players[DEFAULT_USERNAME] == nil then
    return nil
  end
  
  local player = world.players[DEFAULT_USERNAME]
  local sc = screen_coords(player.x,player.y)
  
  return {
    x = x + sc.x1 - OFFSET_X,
    y = y + sc.y1 - OFFSET_Y,
  }
end

----> Convert world to screen
function world_to_screen(x,y)
  if world == nil or world.players[DEFAULT_USERNAME] == nil then
    return nil
  end
  
  local player = world.players[DEFAULT_USERNAME]
  local sc = screen_coords(player.x,player.y)
  
  return {
    x = x - sc.x1 + OFFSET_X,
    y = y - sc.y1 + OFFSET_Y,
  }
end

--> GAME

----> Initialise
function game_init()
  game_keyhandlers = {}
  clicking = false
  last_move_s = love.timer.getTime()
  game_dbg_pos = nil
  particles = {}
end

----> Move
function move_char()
  local mx, my = love.mouse.getPosition()  
  local new_pos = screen_to_world(mx,my)
      
  set_target(DEFAULT_USERNAME,new_pos.x,new_pos.y)
end

----> Update
function game_update()
  if world == nil then
    world_load(DEFAULT_WORLD)
    world_join(DEFAULT_USERNAME)
    ui_add_game()
  end
  
  --if clicking and t - last_move_s > MOVE_DELAY_S then
  --  move_char()
  --end
  
  world_update()
end

----> Draw particles
function game_draw_particles()
  local f = love.graphics.getFont()

  local n = 0
  for i,part in pairs(particles) do
    if part.text ~= nil then
      local tw = f:getWidth(part.text)
      local th = f:getHeight(part.text)
      local pos = world_to_screen(part.x,part.y)

      love.graphics.setColor(part.color)
      love.graphics.print(part.text,pos.x - tw/2,pos.y - th/2)

      if part.should_destroy(part) then
        particles[i] = nil
      end
    end

    n = n + 1
  end
end

----> Draw
function game_draw()
  if world ~= nil and world.players[DEFAULT_USERNAME] ~= nil then
    world_draw()
    game_draw_particles()
  else
    love.graphics.printf("Loading",0,0,800)
  end
end

----> Generic action
function action()
  if world ~= nil and world.players[DEFAULT_USERNAME] ~= nil then
    local player = world.players[DEFAULT_USERNAME]
    local closest = nil
    local dist = nil
    if player.drops ~= nil then
      for i,drop in pairs(player.drops) do
        local ddrop = euclid(player.x,player.y,drop.x,drop.y)
        if ddrop < INTERACT_DIST and (closest == nil or ddrop < dist) then
          closest = "drop " .. tostring(i)
          dist = ddrop
        end
      end
    end

    for layer,objs in pairs(world.objects) do
      for objname,obj in pairs(objs) do
        if obj.isa ~= nil then
          local objtype = Objects[obj.isa]
          if objtype.interactable then
            -- Just use the collision detection code to check the interaction
            local side = check_collision(player.x,player.y,PLAYER_L + 2 * INTERACT_DIST,PLAYER_L + 2 * INTERACT_DIST,obj.x,obj.y,obj.w,obj.h)

            if side ~= nil then
            
              local d = 0
              if side == 1 then
                d = player.x - obj.x - PLAYER_L / 2 - obj.w / 2
              elseif side == 2 then
                d = player.y - obj.y - PLAYER_L / 2 - obj.h / 2
              elseif side == 3 then
                d = obj.x - player.x - PLAYER_L / 2 - obj.w / 2
              elseif side == 4 then
                d = obj.y - player.y - PLAYER_L / 2 - obj.h / 2
              end

              if d < INTERACT_DIST and (closest == nil or d < dist) then
                closest = "object " .. layer .. " " .. objname
                dist = d
              end
            end
          end
        end
      end
    end

    if closest ~= nil then
      local parts = split_spaces(closest)

      -- Pick up drop
      if parts[1] == "drop" then
        local i = tonumber(parts[2])
        pickup(DEFAULT_USERNAME,i)
      elseif parts[1] == "object" then
        interact(DEFAULT_USERNAME,parts[2],parts[3])
      end
    end
  end
end

----> Use ability
function ability_handler(key, pressed)
  if pressed then
    local ability_num = AbilityKey[key]
    use_ability(DEFAULT_USERNAME,ability_num)
  end
end

----> Map keys
function register_key_handlers()
  for k,v in pairs(AbilityKey) do
    game_keyhandlers[k] = ability_handler
  end
  game_keyhandlers["space"] = function(key,pressed) if pressed then action() end end
  game_keyhandlers["f"] = function(key,pressed) if pressed then toggle_shooting(DEFAULT_USERNAME) end end
  game_keyhandlers["d"] = function(key,pressed) 
    if pressed then 
      clear_shoot_target(DEFAULT_USERNAME) 
      set_shooting(DEFAULT_USERNAME,false)
    end 
  end
  game_keyhandlers["tab"] = function(key,pressed) if pressed then shoot_nearest(DEFAULT_USERNAME) end end
end

----> Key handler
function game_keyhandler(key,pressed)  
  local handler = game_keyhandlers[key]
  if handler ~= nil then
    handler(key,pressed)
  end
end

function game_mouse_released(button)
  if button == 1 then
    clicking = false
  end
end

----> Mouse handler
function game_mousehandler(x,y,button,pressed)
  if pressed then
    if button == 1 then
      move_char()
      last_move_s = love.timer.getTime()
      
      clicking = true
    elseif button == 2 then
      local pos = screen_to_world(x,y)
      set_shoot_target(DEFAULT_USERNAME,pos.x,pos.y)
    end
  end
end


--> UI
----> Initialise
function ui_init()
  ui = {}
end


----> Draw the abilities bar
function ui_draw_abilities()

  local uidef = ui["abilities"]
  if uidef == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)
  
  local player = world.players[DEFAULT_USERNAME]
  local abilities = player.ability_map

  if abilities ~= nil then

    local ability_key_inv = {}
    for key,ability_num in pairs(AbilityKey) do
      ability_key_inv[ability_num] = key:upper()
    end
    
    local l = UI_ABILITY_LEN
    local m = UI_ABILITY_MARGIN
    local r = 10

    local dx = 0
    local dy = 0

    local imgl = l - m
    local lockl = (l-m) * 2/3

    for i = 1,10 do
      local abil_def = Abilities[abilities[i]]

      love.graphics.setColor(Color["blue"])
      love.graphics.rectangle('fill',p0.x + dx,p0.y + dy,l,l)

      local ability_img = get_image(abilities[i])
      local xscale = imgl / ability_img.w
      local yscale = imgl / ability_img.h
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(ability_img.img,p0.x + dx + m / 2, p0.y + dy+ m/2, 0, xscale, yscale)

      if not can_use_ability(player.username,abilities[i]) then
        love.graphics.setColor(1,0,0,0.5)
        love.graphics.rectangle("fill",p0.x + dx + m/2, p0.y + dy + m/2,imgl,imgl)
      end

      if player.abilities[abilities[i]].locked then
        local lock_img = get_image("lock")
        local xscale = lockl / lock_img.w
        local yscale = lockl / lock_img.h
        love.graphics.setColor(1,1,1)
        love.graphics.draw(lock_img.img,p0.x + dx + m / 2 + imgl / 2 - lockl / 2, p0.y + dy + m / 2 + imgl / 2 - lockl / 2,0,xscale,yscale)
      end

      love.graphics.setColor(Color["black"])
      love.graphics.circle("fill",p0.x + dx + r, p0.y + dy + r + 2,r)

      love.graphics.setColor(Color["white"])
      love.graphics.print(ability_key_inv[i],p0.x + dx + m/2 + 2,p0.y + dy + m/2)

      dx = dx + m + l
      if i == 5 then
        dx = 0
        dy = dy + m + l
      end
    end
  end
end

function ui_divide_abilities_book()
  local uidef = ui["abilities_book"]
  if uidef == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  local bm = UI_ABILITYBOOK_MARGIN
  local bh = UI_ABILITYBOOK_HEADER
  local il = UI_ABILITY_ICON_LEN
  local im = UI_ABILITY_ICON_MARGIN

  local divs = {}
  divs.x_left_margin = p0.x + bm/2
  divs.x_learned = divs.x_left_margin + bm / 2
  divs.x_centre_margin = p0.x + bm * 3 /2 + 5 * il + 4 * im
  divs.x_ability_info = divs.x_centre_margin + bm/2
  divs.x_right_margin = p0.x + uidef.w - bm/2
  divs.x_close = divs.x_right_margin - bm/2 - bh
  
  divs.y_top_margin = p0.y + bm/2
  divs.y_learned_title = divs.y_top_margin + bm/2
  divs.y_learned = divs.y_learned_title + bh
  divs.y_learned_known_margin = divs.y_learned + il*2 + im + bm/2
  divs.y_known_title = divs.y_learned_known_margin + bm/2
  divs.y_known = divs.y_known_title + bh
  divs.y_bottom_margin = p0.y + uidef.h - bm/2
  divs.y_close = divs.y_top_margin + bm/2

  return divs
end

----> Draw the abilities book
function ui_draw_abilities_book()
  local uidef = ui["abilities_book"]
  if uidef == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  local divs = ui_divide_abilities_book()

  local player = world.players[DEFAULT_USERNAME]
  local ability_map = player.ability_map
  local abilities = player.abilities

  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill",p0.x,p0.y,uidef.w,uidef.h)

  local bm = UI_ABILITYBOOK_MARGIN
  local bh = UI_ABILITYBOOK_HEADER
  local il = UI_ABILITY_ICON_LEN
  local im = UI_ABILITY_ICON_MARGIN

  local default_font = love.graphics.getFont()
  local large_font = love.graphics.newFont(20)

  -- Draw outline
  love.graphics.setColor(1,1,1)
  love.graphics.line(divs.x_left_margin,divs.y_top_margin,divs.x_left_margin,divs.y_bottom_margin) -- Left margin
  love.graphics.line(divs.x_left_margin,divs.y_top_margin,divs.x_right_margin,divs.y_top_margin) -- Top margin
  love.graphics.line(divs.x_right_margin,divs.y_top_margin,divs.x_right_margin,divs.y_bottom_margin) -- Right margin
  love.graphics.line(divs.x_left_margin,divs.y_bottom_margin,divs.x_right_margin,divs.y_bottom_margin) -- Bottom margin
  love.graphics.line(divs.x_centre_margin,divs.y_top_margin,divs.x_centre_margin,divs.y_bottom_margin) -- Centre margin
  love.graphics.line(divs.x_left_margin,divs.y_learned_known_margin,divs.x_centre_margin,divs.y_learned_known_margin) -- Learned-known margin

  -- Draw close button
  love.graphics.setColor(1,0,0)
  love.graphics.rectangle("fill",divs.x_close,divs.y_close,bh,bh)
  love.graphics.setColor(1,1,1)
  love.graphics.line(divs.x_close+4,divs.y_close+4,divs.x_close+bh-4,divs.y_close+bh-4)
  love.graphics.line(divs.x_close+4,divs.y_close+bh-4,divs.x_close+bh-4,divs.y_close+4)

  -- Draw learned abilities
  love.graphics.setColor(1,1,1)
  love.graphics.print("Learned",divs.x_learned,divs.y_learned_title)

  local x = divs.x_learned
  local y = divs.y_learned
  for i = 1,10 do
    local ability_img = get_image(ability_map[i])
    local xscale = il / ability_img.w
    local yscale = il / ability_img.h
    love.graphics.setColor(1,1,1)
    love.graphics.draw(ability_img.img,x,y,0,xscale,yscale)
    if uidef.learning and uidef.selected ~= ability_map[i] then
      love.graphics.setColor(1,1,0,0.25)
      love.graphics.rectangle("fill",x,y,il,il)
    end
    x = x + il + im
    if i == 5 then
      x = divs.x_learned
      y = y + il + im
    end
  end

  -- Draw known abilities
  love.graphics.setColor(1,1,1)
  love.graphics.print("Known",divs.x_learned,divs.y_known_title)

  x = divs.x_learned+80
  y = divs.y_known_title+8
  love.graphics.setColor(1,1,0)
  love.graphics.circle("fill",x,y,4)
  x = x + 10
  love.graphics.setColor(1,1,1)
  love.graphics.print("= never used    (right-click to learn)",x,divs.y_known_title)

  x = divs.x_learned
  y = divs.y_known
  local i = 1
  for aname,ability in pairs(abilities) do
    local ability_img = get_image(aname)
    local xscale = il / ability_img.w
    local yscale = il / ability_img.h
    love.graphics.setColor(1,1,1)
    love.graphics.draw(ability_img.img,x,y,0,xscale,yscale)

    if ability.times_used == 0 then
      love.graphics.setColor(1,1,0)
      love.graphics.circle("fill",x+5,y+5,4)
    end

    if aname == uidef.selected then
      love.graphics.setColor(0.2,0.2,1,0.4)
      love.graphics.rectangle("fill",x,y,il,il)
    end

    if ability.slot ~= -1 then
      love.graphics.setColor(0,1,0)
      love.graphics.rectangle("line",x-1,y-1,il+2,il+2)
    end
    

    
    x = x + il + im

    if i % 5 == 0 then
      x = divs.x_learned
      y = y + il + im
    end
    i = i + 1
  end

  -- Draw selected ability
  love.graphics.setColor(1,1,1)
  love.graphics.print("Ability Info",divs.x_ability_info,divs.y_learned_title)

  if uidef.selected ~= nil then
    local selected_ability = Abilities[uidef.selected]

    local img = get_image(uidef.selected)
    local xscale = UI_ABILITY_LEN / img.w
    local yscale = UI_ABILITY_LEN / img.h

    love.graphics.setColor(1,1,1)
    love.graphics.draw(img.img,divs.x_ability_info,divs.y_learned,0,xscale,yscale)

    love.graphics.setFont(large_font)

    local name_w = divs.x_right_margin - divs.x_ability_info + UI_ABILITY_LEN
    local text_w = large_font:getWidth(selected_ability.name)
    local text_h = large_font:getHeight(selected_ability.name)

    love.graphics.setColor(1,1,1)
    love.graphics.print(selected_ability.name,divs.x_ability_info + name_w/2 - text_w/2,divs.y_learned + UI_ABILITY_LEN/2-text_h/2)
  
    love.graphics.setFont(default_font)

    -- Ability details
    local x = divs.x_ability_info
    local y = divs.y_learned + UI_ABILITY_LEN + UI_ABILITY_MARGIN
    local details_w = divs.x_right_margin - divs.x_ability_info - bm / 2

    -- Write description
    local desc_w,wrappedtext = default_font:getWrap(selected_ability.description,details_w)
    for i,line in ipairs(wrappedtext) do
      love.graphics.setColor(1,1,1)
      love.graphics.print(line,x,y)

      y = y + default_font:getHeight(line)
    end
    x = x + details_w/2
    y = y + UI_ABILITY_MARGIN

    -- Targeted
    if selected_ability.target then
      local t = "TARGETED"

      love.graphics.setColor(1,0.2,0.2)
      love.graphics.print(t,x - default_font:getWidth(t)/2,y)

      y = y + default_font:getHeight(t) + UI_ABILITY_MARGIN
    end

    -- Interrupt
    if selected_ability.interrupt then
      local t = "INTERRUPT"

      love.graphics.setColor(1,1,0)
      love.graphics.print(t,x - default_font:getWidth(t)/2,y)

      y = y + default_font:getHeight(t) + UI_ABILITY_MARGIN
    end

    -- Channel
    if selected_ability.channel then
      local t = "CHANNELED"

      love.graphics.setColor(0.5,0.7,1)
      love.graphics.print(t,x - default_font:getWidth(t)/2,y)

      y = y + default_font:getHeight(t) + UI_ABILITY_MARGIN
    end

    -- Stationary
    if selected_ability.stationary then
      local t = "STATIONARY"

      love.graphics.setColor(0,0.8,1)
      love.graphics.print(t,x - default_font:getWidth(t)/2,y)

      y = y + default_font:getHeight(t) + UI_ABILITYBOOK_MARGIN
    end

  end
end

function ui_draw_charge_bar()
  local uidef = ui["charge_bar"]

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  local player = world.players[DEFAULT_USERNAME]

  local charge_ratio = player.charge / CHARGE_TO_UNLOCK

  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill",p0.x,p0.y,uidef.w,uidef.h)
  love.graphics.setColor(0.3,0.6,1)
  love.graphics.rectangle("fill",p0.x,p0.y,charge_ratio * uidef.w,uidef.h)
end

function ui_draw_health_bar()
  local uidef = ui["health_bar"]

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  local player = world.players[DEFAULT_USERNAME]

  local health_ratio = player.hp / PLAYER_HP

  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill",p0.x,p0.y,uidef.w,uidef.h)
  love.graphics.setColor(0,1,0)
  love.graphics.rectangle("fill",p0.x,p0.y,health_ratio * uidef.w,uidef.h)

  love.graphics.setColor(0,0,0)
  love.graphics.print("HP: " .. player.hp .. " / " .. tostring(PLAYER_HP),p0.x + 10,p0.y + 2)
end

----> Draw
function ui_draw()
  if ui["charge_bar"] ~= nil and ui["charge_bar"].visible then
    ui_draw_charge_bar()
  end

  if ui["health_bar"] ~= nil and ui["health_bar"].visible then
    ui_draw_health_bar()
  end

  if ui["abilities"] ~= nil and ui["abilities"].visible then
    ui_draw_abilities()
  end

  if ui["abilities_book"] ~= nil and ui["abilities_book"].visible then
    ui_draw_abilities_book()
  end
end

----> Abilities bar mouse click
function ui_mousehandler_abilities(x,y,button,pressed)
  if pressed and button == 1 then
    local uidef = ui["abilities"]
    if uidef == nil then return end
  
    local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)
    
    if x < p0.x or x > (p0.x + uidef.w) or y < p0.y or y > (p0.y + uidef.h) then
      return false
    end

    local yp = y - p0.y - UI_ABILITY_MARGIN / 2
    local xp = x - p0.x - UI_ABILITY_MARGIN / 2

    local l = UI_ABILITY_LEN + UI_ABILITY_MARGIN

    local yi = math.floor(yp / l) + 1
    local xi = math.floor(xp / l) + 1
    
    if 1 <= yi and yi <= 2 and 1 <= xi and xi <= 5 then
      local i = (yi - 1) * 5 + xi
      use_ability(DEFAULT_USERNAME,i)
      return true
    end
  end
  
  return false
end

----> Abilties book mouse click
function ui_mousehandler_abilities_book(x,y,button,pressed)
  local uidef = ui["abilities_book"]
  if uidef == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  if x < p0.x or x > (p0.x + uidef.w) or y < p0.y or y > (p0.y + uidef.h) then
    uidef.visible = false
    uidef.selected = nil
    uidef.learning = false
    return false
  end

  local bh = UI_ABILITYBOOK_HEADER
  local bm = UI_ABILITYBOOK_MARGIN
  local il = UI_ABILITY_ICON_LEN
  local im = UI_ABILITY_ICON_MARGIN

  local player = world.players[DEFAULT_USERNAME]
  local ability_map = player.ability_map
  local abilities = player.abilities

  local abilities_indices = {}
  for aname,ability in pairs(abilities) do
    table.insert(abilities_indices,aname)
  end

  local divs = ui_divide_abilities_book()

  -- Check close button
  if x > divs.x_close and x < divs.x_close + bh and y > divs.y_close and y < divs.y_close + bh then
    uidef.visible = false
    uidef.selected = nil
    uidef.learning = false
    return true
  end

  -- Check left click learned abilities
  if x > divs.x_learned and x < divs.x_centre_margin - bm/2 and y > divs.y_learned and y < divs.y_learned_known_margin - bm/2 then
    local xp = x - divs.x_learned
    local yp = y - divs.y_learned

    local xi = math.floor(xp / (il + im))
    local yi = math.floor(yp / (il + im))

    local i = (xi % 5 + 1) + yi * 5

    if uidef.learning and uidef.selected ~= ability_map[i] then
      uidef.learning = false

      local selected_ability_def = abilities[uidef.selected]
      
      local prev_ability = ability_map[i]
      local prev_ability_def = abilities[prev_ability]
      local prev_slot = prev_ability_def.slot

      if selected_ability_def.slot ~= -1 then
        -- Swap
        prev_ability_def.slot = selected_ability_def.slot
        selected_ability_def.slot = prev_slot

        ability_map[prev_ability_def.slot] = prev_ability
        ability_map[selected_ability_def.slot] = uidef.selected
      else
        -- Replace
        prev_ability_def.slot = -1
        prev_ability_def.locked = true
        selected_ability_def.slot = prev_slot
        selected_ability_def.locked = true

        ability_map[selected_ability_def.slot] = uidef.selected
      end

    else
      uidef.selected = ability_map[i]
      if button == 2 then
        uidef.learning = true
      end
    end
    return true
  end

  -- Check click known abilities
  if x > divs.x_learned and x < divs.x_centre_margin - bm/2 and y > divs.y_known and y < divs.y_bottom_margin - bm/2 then    
    uidef.learning = false

    local xp = x - divs.x_learned
    local yp = y - divs.y_known

    local xi = math.floor(xp / (il + im))
    local yi = math.floor(yp / (il + im))

    local i = (xi % 5 + 1) + yi * 5

    local ability_clicked = abilities_indices[i]

    if ability_clicked ~= nil then
      uidef.selected = ability_clicked
      if button == 2 then
        uidef.learning = true
      end
    end
    return true
  end

  uidef.learning = false

  return true
end

----> Mousehandler
function ui_mousehandler(x,y,button,pressed)
  if ui["abilities_book"] ~= nil and ui["abilities_book"].visible then
    if ui_mousehandler_abilities_book(x,y,button,pressed) then
      return true
    end
  end

  if ui["abilities"] ~= nil and ui["abilities"].visible then
    if ui_mousehandler_abilities(x,y,button,pressed) then
      return true
    end
  end

  return false
end

function ui_keyhandler_abilities_book(key,pressed)
  if key == "escape" and pressed then
    ui["abilities_book"].visible = false
    return true
  end
end

function ui_keyhandler_abilities(key,pressed)
  return false
end

function ui_keyhandler(key,pressed)
  if ui["abilities"] ~= nil and ui["abilities"].visible then
    if ui_keyhandler_abilities(key,pressed) then
      return true
    end
  end

  if ui["abilities_book"] ~= nil and ui["abilities_book"].visible then
    if ui_keyhandler_abilities_book(key,pressed) then
      return true
    end
  end
end

--> DEBUG
----> Initialise
function debug_init()
  log_ledger = {}
  n_logs = 0
  love.filesystem.createDirectory("logs")
  local log_filename = "logs/" .. os.date("%Y%m%d%H%M%S") .. ".txt"
  log_file = love.filesystem.newFile(log_filename)
  log_file:open("w")
  debug_input = ""
end

----> Log to text
function log_text(log)
  return log.logtype .. " - " .. log.datetime .. ": " .. log.message
end

----> Draw
function debug_draw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  local f = love.graphics.getFont()
  local lh = f:getHeight()
  
  -- Fade background
  love.graphics.setColor(0,0,0,0.7)
  love.graphics.rectangle("fill",0,0,w,h)
  
  -- Player position
  love.graphics.setColor(1,1,1,1)
  if game_dbg_pos ~= nil then
    love.graphics.printf("Player position: " .. math.floor(game_dbg_pos.x * 10) / 10 .. " " .. math.floor(game_dbg_pos.y * 10) / 10,0,0,w)
  end
  
  -- Tick
  if world_dbg_tick ~= nil then
    love.graphics.printf("World tick: " .. tostring(world_dbg_tick),0,lh,w)
  end
  
  -- Logs
  local y = h - 3 * lh
  local n = 20
  local li = n_logs
  local l = 1
  
  while l <= n do
    if li < 1 then
      break
    end
    
    local log = log_ledger[li]
    local logtext = log_text(log)
    
    local ltwidth, wrappedtext = f:getWrap(logtext,w - f:getWidth("\t"))
    local n_lines = 0
    for _,line in ipairs(wrappedtext) do
      n_lines = n_lines + 1
    end
    
    for i = n_lines,1,-1 do
      love.graphics.setColor(1,1,1,1)
      if i == 1 then
        love.graphics.printf(wrappedtext[i],0,y,w)
        y = y - lh
        l = l + 1
      else
        love.graphics.printf("\t" .. wrappedtext[i],0,y,w)
        y = y - lh
        l = l + 1
      end
    end
    
    li = li - 1
  end

  -- Input
  love.graphics.setColor(1,1,1,0.2)
  love.graphics.rectangle("fill",0.5 * lh,h - 1.5 * lh,w - lh,lh)

  love.graphics.setColor(1,1,1,1)
  love.graphics.printf(debug_input,0.5 * lh, h - 1.5 * lh,w - lh)
end


----> Debug command
function debug_command(input_str)
  log_info("> " .. input_str)

  local split_command = split_spaces(input_str)
  local command = split_command[1]
  if command == "save" then
    local savename = split_command[2]
    if savename ~= nil then
      save_world_to(savename)
    end
  elseif command == "load" then
    local savename = split_command[2]
    if savename ~= nil then
      load_world_from(savename)
    end
  else
    log_warning("Unknown command: " .. command)
  end
end

----> Capturing debug handler
function debug_keyhandler(key,pressed)
  if pressed then
    if key == 'return' then
      debug_command(debug_input)
      debug_input = ""
    elseif key == 'backspace' or key == 'delete' then
      debug_input = string.sub(debug_input,1,string.len(debug_input)-1)
    else
      local keytest = key
      if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
        keytest = "shift " .. key
      end
      local char = LegalKeys[keytest]
      if char then
        debug_input = debug_input .. char
      end
    end
  end

  return true
end

----> Capturing debug mous handler
function debug_mousehandler(x,y,button,pressed)
  return true
end

--> LOVE
----> Load
function love.load()
  state_init()
  debug_init()
  assets_init()
  world_init()
  game_init()
  ui_init()
  
  register_key_handlers()
  
  key_release_callbacks = {}
  mouse_release_callbacks = {}
  
  debug = Debug.HIDDEN
  paused = false
  view = View.INIT
  
  log_info("|    ARGO V    |")
end

----> Draw
function love.draw()
  if view == View.MENU then
    love.graphics.printf("Menu",0,0,800)
  elseif view == View.GAME then
    game_draw()
  end
  
  ui_draw()

  if debug ~= Debug.HIDDEN then
    debug_draw()
  end
end

----> Update
function love.update()
  if view == View.INIT then
    view = View.GAME
  elseif view == View.GAME then
    game_update()
  end
end

----> Key router
function keyrouter(key,pressed)
  -- Toggle Debug
  if key == "f3" and pressed then
    if debug ~= Debug.SHOWN then
      debug = Debug.SHOWN
    else
      debug = Debug.HIDDEN
    end
  end

  if ui_keyhandler(key,pressed) then return true end
  
  -- Toggle capturing Debug
  if key == "f4" and pressed then
    if debug ~= Debug.CAPTURING then
      debug = Debug.CAPTURING
    else
      debug = Debug.HIDDEN
    end
  end
  
  -- Capture debug
  if debug == Debug.CAPTURING then
    if debug_keyhandler(key,pressed) then return true end
  end
  
  -- Route to view
  if view == View.MENU then
    if menu_keyhandler(key,pressed) then return true end
  elseif view == View.GAME then
    if game_keyhandler(key,pressed) then return true end
  end
end

----> Key pressed
function love.keypressed(key, scancode, isrepeat)
  keyrouter(key,true)
end

----> Key released
function love.keyreleased(key, scancode, isrepeat)
  keyrouter(key,false)
end

----> Mouse router
function mouserouter(x,y,button,pressed)
  game_mouse_released(button)

  -- Capture debug
  if debug == Debug.CAPTURING then
    if debug_mousehandler(x,y,button,pressed) then return true end
  end

  -- UI
  if ui_mousehandler(x,y,button,pressed) then return true end
  
  -- Route to view
  if view == View.MENU then
    if menu_mousehandler(x,y,button,pressed) then return true end
  elseif view == View.GAME then
    if game_mousehandler(x,y,button,pressed) then return true end
  end
end

----> Mousepressed
function love.mousepressed(x, y, button, istouch, presses)
 mouserouter(x,y,button,true)
end

function love.mousereleased(x, y, button, istouch, presses)
  mouserouter(x,y,button,false)
end