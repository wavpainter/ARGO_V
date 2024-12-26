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
local Abilities = {
  [1] = "invis",
  [2] = "beam",
  [3] = "cantrip",
  [4] = "root",
  [5] = "negate",
  [6] = "push",
  [7] = "rage",
  [8] = "reflect",
  [9] = "stun",
  [10] = "pull",
  [11] = "stab"
}
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
  ["lectern"] = "lectern.png"
}
local Entities = {
  ["dummy"] = {
    targetable = "true",
    hp = 987654321,
    drops = {
      {
        name = "ability cantrip",
        rate = 1
      }
    }
  },
  ["skeleton"] = {
    targetable = "true",
    hp = 100,
    drops = {
      {
        name = "ability stab",
        rate = 1
      }
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
    ["invis"] = {
      times_used = 0,
      slot = 1,
    },
    ["beam"] = {
      times_used = 0,
      slot = 2,
    },
    ["cantrip"] = {
      times_used = 0,
      slot = 3,
    },
    ["root"] = {
      times_used = 0,
      slot = 4,
    },
    ["negate"] = {
      times_used = 0,
      slot = 5,
    },
    ["push"] = {
      times_used = 0,
      slot = 6,
    },
    ["rage"] = {
      times_used = 0,
      slot = 7
    },
    ["reflect"] = {
      times_used = 0,
      slot = 8
    },
    ["stun"] = {
      times_used = 0,
      slot = 9
    },
    ["pull"] = {
      times_used = 0,
      slot = 10
    },
    ["stab"] = {
      times_used = 0,
      slot = -1
    },
  },
  avatar = "jason",
  shoot_speed = 4,
  damage = 10
}
local DEFAULT_USERNAME = "jason"
local MOVE_DELAY_S = 0.15
local PLAYER_L = 75
local DROP_L = 40
local MOVE_SPEED = 1000
local BULLET_SPEED = 1500
local BULLET_RADIUS = 10
local INTERACT_DIST = 100

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
local UI_ABILITYBOOK_TITLE = 20
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
local ability_index_map = nil
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

--> UTILS
----> Get screen world bounds
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
    anchor = Anchor.BOTTOM_LEFT,
    x_off = 10,
    y_off = -10,
    w = UI_ABILITY_LEN * 5 + UI_ABILITY_MARGIN * 4,
    h = UI_ABILITY_LEN * 2 + UI_ABILITY_MARGIN
  }

  ui["abilities_book"] = {
    visible = false,
    anchor = Anchor.CENTRE,
    x_off = 0,
    y_off = 0,
    w = (UI_ABILITYBOOK_MARGIN + UI_ABILITYBOOK_MARGIN/2 + UI_ABILITY_ICON_LEN * 5 + UI_ABILITY_ICON_MARGIN * 4 + UI_ABILITYBOOK_MARGIN) * 2,
    h = UI_ABILITYBOOK_MARGIN*3 + UI_ABILITY_ICON_LEN * 2 + UI_ABILITY_ICON_MARGIN + UI_ABILITY_ICON_LEN * 10 + UI_ABILITY_ICON_MARGIN * 9
  }
end

----> Remove game UI
function ui_remove_game()
  ui["abilities"] = nil
  ui["abilities_book"] = nil
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
function draw_background(bg,sc)
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  
  local pattern = split_spaces(bg)
  
  if pattern[1] == "tiles" then
    local col1 = pattern[2]
    local col2 = pattern[3]
    local tilew = tonumber(pattern[4])
    local tileh = tonumber(pattern[5])
    
    local i1 = math.floor(sc.x1 / tilew)
    local i2 = math.ceil(sc.x2 / tilew)
    local j1 = math.floor(sc.y1 / tileh)
    local j2 = math.ceil(sc.y2 / tileh)
    
    for i = i1,i2,1 do
      for j = j1,j2,1 do
        local x = i*tilew - sc.x1
        local y = j*tileh - sc.y1
        
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

----> Draw
function world_draw()
  local player = world.players[DEFAULT_USERNAME]
  local sc = screen_coords(player.x,player.y)
  local bg = world.background
  
  if bg ~= nil then
    draw_background(bg,sc)
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

      if entity.targetable then
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

----> Update player
function update_player(player,tick)
  if player.move_target ~= nil then
    local new_pos = new_pos(player.x,player.y,player.move_target.x,player.move_target.y,MOVE_SPEED)
    local collisions = check_all_collisions(new_pos.x,new_pos.y,PLAYER_L,PLAYER_L)

    for _,collision in pairs(collisions) do
      new_pos.arrived = false
      if collision.side == 1 then
        new_pos.x = collision.obj.x + collision.obj.w / 2 + PLAYER_L / 2
      elseif collision.side == 2 then
        new_pos.y = collision.obj.y + collision.obj.h / 2 + PLAYER_L / 2
      elseif collision.side == 3 then
        new_pos.x = collision.obj.x - collision.obj.w / 2 - PLAYER_L / 2
      elseif collision.side == 4 then
        new_pos.y = collision.obj.y - collision.obj.h / 2 - PLAYER_L / 2
      end
    end
    
    player.x = new_pos.x
    player.y = new_pos.y
    if new_pos.arrived then
      player.move_target = nil
    end
  end

  if player.shooting and player.shoot_target ~= nil then
    local shoot_period = 60 / player.shoot_speed

    if player.last_shoot == nil or tick - player.last_shoot > shoot_period then
      shoot_bullet(player)
      player.last_shoot = tick
    end
  end

  game_dbg_pos = {
    x = player.x,
    y = player.y
  }
end

----> Player uses ability
function use_ability(username,ability_num)
  if world ~= nil and world.players[username] ~= nil then
    player = world.players[username]
    
    local ability_name = player.ability_map[ability_num]
    player.abilities[ability_name].times_used = player.abilities[ability_name].times_used + 1 -- Lua moment
    local ability_index = ability_index_map[ability_name]
    log_info(username .. " used ability: " .. ability_name)
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
function deal_entity_damage(ename,dmg)
  local ent = get_entity(ename)

  local entitytype = Entities[ent.isa]
  ent.hp = ent.hp - dmg
  
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

----> Resolve bullet
function resolve_bullet(bullet)
  -- Create hit particle
  local source = bullet.source
  local source_parts = split_spaces(source)
  if source_parts[1] == "player" and source_parts[2] == DEFAULT_USERNAME then
    if world.players[source_parts[2]] ~= nil then
      local player = world.players[source_parts[2]]
      local h = 50
      local x = bullet.x
      local y = bullet.y
      if bullet.target.type == "entity" then
        local ent = get_entity(bullet.target.name)
        deal_entity_damage(bullet.target.name,player.damage)
        y = y
        h = ent.h/2 + 20
      end

      create_hit_particle(player.damage,x,y,h)
    end
  end
end

----> Player pickup drop
function pickup(username,i)
  local player = world.players[username]
  if player ~= nil then
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

    local bullets = world.bullets
    for i,bullet in pairs(bullets) do

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
        resolve_bullet(bullet)
        bullets[i] = nil
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
        isa = edef.isa,
        hp = entitytype.hp,
        x = edef.x,
        y = edef.y,
        w = edef.w,
        h = edef.h
      }
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
      times_used = abil.times_used,
      slot = abil.slot
    }
    if abil.slot ~= -1 then
      abilmap[abil.slot] = name
    end
  end


  local spawn = world.spawn
  local new_player = {
    username = username,
    abilities = abils,
    ability_map = abilmap,
    avatar = DEFAULT_PLAYER.avatar,
    shoot_speed = DEFAULT_PLAYER.shoot_speed,
    damage = DEFAULT_PLAYER.damage,
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
      if etype.targetable and e.hp > 0 then
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

----> Convert screen to world
function screen_to_world(x,y)
  if world == nil or world.players[DEFAULT_USERNAME] == nil then
    return nil
  end
  
  local player = world.players[DEFAULT_USERNAME]
  local sc = screen_coords(player.x,player.y)
  
  return {
    x = x + sc.x1,
    y = y + sc.y1,
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
    x = x - sc.x1,
    y = y - sc.y1,
  }
end

--> GAME

----> Initialise
function game_init()
  game_keyhandlers = {}
  ability_index_map = {}
  for k,v in pairs(Abilities) do
    ability_index_map[v] = k
  end
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
  local t = love.timer.getTime()
  if world == nil then
    world_load(DEFAULT_WORLD)
    world_join(DEFAULT_USERNAME)
    ui_add_game()
  end
  
  if clicking and t - last_move_s > MOVE_DELAY_S then
    move_char()
    last_move_s = t
  end
  
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
end

----> Key handler
function game_keyhandler(key,pressed)  
  local handler = game_keyhandlers[key]
  if handler ~= nil then
    handler(key,pressed)
  end
end

----> Mouse handler
function game_mousehandler(x,y,button,pressed)
  if not pressed and button == 1 then
    clicking = false
  end

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
    
    for i = 1,10 do
      love.graphics.setColor(Color["blue"])
      love.graphics.rectangle('fill',p0.x + dx,p0.y + dy,l,l)

      local ability_img = get_image(abilities[i])
      local xscale = imgl / ability_img.w
      local yscale = imgl / ability_img.h
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(ability_img.img,p0.x + dx + m / 2, p0.y + dy+ m/2, 0, xscale, yscale)

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

----> Draw the abilities book
function ui_draw_abilities_book()
  local uidef = ui["abilities_book"]
  if uidef == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  local player = world.players[DEFAULT_USERNAME]
  local ability_map = player.ability_map
  local abilities = player.abilities

  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("fill",p0.x,p0.y,uidef.w,uidef.h)

  local bm = UI_ABILITYBOOK_MARGIN
  local il = UI_ABILITY_ICON_LEN
  local im = UI_ABILITY_ICON_MARGIN

  -- Draw outline
  local x1 = p0.x + bm/2
  local x2 = p0.x + uidef.w - bm/2
  local y1 = p0.y + bm/2
  local y2 = p0.y + uidef.h - bm/2
  local xc = p0.x + bm * 3 /2 + 5 * il + 4 * im
  local yc = p0.y + bm * 3 /2 + 2 * il + im
  love.graphics.setColor(1,1,1)
  love.graphics.line(x1,y1,x2,y1)
  love.graphics.line(x1,y1,x1,y2)
  love.graphics.line(x2,y1,x2,y2)
  love.graphics.line(x1,y2,x2,y2)
  love.graphics.line(xc,y1,xc,y2)
  love.graphics.line(x1,yc,xc,yc)

  -- Draw learned abilities
  local dx = bm
  local dy = bm
  for i = 1,10 do
    local ability_img = get_image(ability_map[i])
    local xscale = il / ability_img.w
    local yscale = il / ability_img.h
    love.graphics.setColor(1,1,1)
    love.graphics.draw(ability_img.img,p0.x + dx,p0.y + dy,0,xscale,yscale)
    dx = dx + il + im
    if i == 5 then
      dx = bm
      dy = dy + il + im
    end
  end

  -- Draw known abilities
  local dx = bm
  local dy = bm * 2 + il * 2 + im
end

----> Draw
function ui_draw()
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
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    
    local l = 80
    local m = l / 10
    
    local xm = 5
    local ym = 5
    
    local yp = h - y - ym
    local xp = x - xm
    
    local yi = math.floor(yp / (l + m)) + 1
    local xi = math.floor(xp / (l + m)) + 1
    
    local yr = yp % (l + m)
    local xr = xp % (l + m)
    
    if 1 <= yi and yi <= 2 and 1 <= xi and xi <= 5 and xr <= l and yr <= l then
      local i = (2 - yi) * 5 + xi
      use_ability(DEFAULT_USERNAME,i)
      return true
    end
  end
  
  return false
end

----> Mousehandler
function ui_mousehandler(x,y,button,pressed)
  if ui["abilities"] ~= nil then
    if ui_mousehandler_abilities(x,y,button,pressed) then
      return true
    end
  end
end

function ui_keyhandler(key,pressed)

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
  local n = 10
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
    for _,line in pairs(wrappedtext) do
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
end

----> Capturing debug mous handler
function debug_mousehandler(x,y,button,pressed)
  
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
    return debug_keyhandler(key,pressed)
  end
  
  -- Route to view
  if view == View.MENU then
    return menu_keyhandler(key,pressed)
  elseif view == View.GAME then
    return game_keyhandler(key,pressed)
  end
end

----> Key pressed
function love.keypressed(key, scancode, isrepeat)
  key_release_callbacks[key] = keyrouter(key,true)
end

----> Key released
function love.keyreleased(key, scancode, isrepeat)
  keyrouter(key,false)
  
  if key_release_callbacks[key] ~= nil then
    key_release_callbacks[key]()
    key_release_callbacks[key] = nil
  end
end

----> Mouse router
function mouserouter(x,y,button,pressed)
  -- Capture debug
  if debug == Debug.CAPTURING then
    return debug_mousehandler(x,y,button,pressed)
  end

  -- UI
  if ui_mousehandler(x,y,button,pressed) then
    return
  end
  
  -- Route to view
  if view == View.MENU then
    return menu_mousehandler(x,y,button,pressed)
  elseif view == View.GAME then
    return game_mousehandler(x,y,button,pressed)
  end
end

----> Mousepressed
function love.mousepressed(x, y, button, istouch, presses)
  mouse_release_callbacks[button] = mouserouter(x,y,button,true)
end

function love.mousereleased(x, y, button, istouch, presses)
  mouserouter(x,y,button,false)
  
  if mouse_release_callbacks[button] ~= nil then
    mouse_release_callbacks[button]()
    mouse_release_callbacks[button] = nil
  end
end