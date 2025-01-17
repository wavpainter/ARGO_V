local json = require("json")
local entities = require("entities")
local utils = require("utils")
local defs = require("defs")
local abilities = require("abilities")
local logging = require("logging")

local log_info = logging.log_info
local log_warning = logging.log_warning
local log_error = logging.log_error

--> CONSTANTS
----> Util
local Color = {
  ["red"] = { 1, 0, 0 },
  ["green"] = { 0, 1, 0 },
  ["blue"] = { 0, 0, 1 },
  ["black"] = { 0, 0, 0 },
  ["white"] = { 1, 1, 1 },
  ["lightgrey"] = {0.8, 0.8, 0.8},
  ["darkgrey"] = {0.2,0.2,0.2}
}

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

----> Commands
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
local DROP_L = 40

local BULLET_SPEED = 1500
local BULLET_RADIUS = 10
local INTERACT_DIST = 100
local OFFSET_X = 0
local OFFSET_Y = -20

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
  ["summon3"] = "summon.png",
  ["ceiling"] = "ceiling.jpg",
  ["floor"] = "floor.jpg",
  ["smallrobot"] = "smallrobot.png",
  ["bigbot"] = "bigbot.png",
  ["knight"] = "knight.png",
  ["horizontaldoor"] = "horizontaldoor.png",
  ["verticaldoor"] = "verticaldoor.png"
}

local Objects = {
  ["lectern"] = {
    interactable = "true"
  },
  ["door"] = {
    interactable = "true"
  }
}
local DEFAULT_WORLD = {
  spawn = {x = 0, y = 0 },
  background = "tiles lightgrey white 100 100",
  fog = "tiles black darkgrey 80 80",
  entities = {
    ["bot1"] = {
      sprite = "smallrobot",
      type = "meleebot",
      zone = "A",
      x = 0,
      y = -500,
      w = 80,
      h = 80,
      visible = true
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
  },
  zones = {
    ["A"] = {
      regions = {
        [1] = {
         x1 = -10000,
         x2 = 10000,
         y1 = -10000,
         y2 = 10000
        }
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
    ["knight"] = {
      locked = true,
      times_used = 0,
      slot = 2
    },
    ["rage"] = {
      locked = true,
      times_used = 0,
      slot = 3
    },
    ["reflect"] = {
      locked = true,
      times_used = 0,
      slot = 4
    },
    ["beam"] = {
      locked = true,
      times_used = 0,
      slot = 5
    }
    
  },
  avatar = "jason"
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
local command_input = nil

----> Assets
local loaded_images = nil

----> Menu

----> World
local t_accum = 0
local k = 0
local world = nil
local prev_entities_pos = nil
local prev_bullets_pos = nil
local curr_entity = nil
local world_dbg_showfog = nil

----> Game
local game_keyhandlers = nil
local particles = nil

----> UI
local ui = nil

abilities["stab"].use = function(world,entity)
  -- Get ability target
  local target = world.entities[entity.shoot_target.name]
  if target == nil then return nil end

  -- Deal damage
  deal_damage(entity.shoot_target.name,abilities.get_ability_def("stab").damage)
end

abilities["rage"].use = function(world,entity)
  local a = {}
  a.t0 = world.tick
  a.tf = world.tick + abilities["rage"].duration * defs.TPS
  a.id = utils.id()
  a.name = "rage"

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

abilities["cantrip"].use = function(world,entity,active_abil)
  entities.unlock_random(world,entity,"cantrip",false)
end

abilities["summon"].use = function(world,entity,active_abil)
  local summon_name = "summon." .. active_abil.id
  local entity = entities.create_summon("cat","summon",entity.x,entity.y,defs.PLAYER_L,defs.PLAYER_L,summon_name,entity.name,"summon",entity.team)
  world.entities[summon_name] = entity
end

abilities["knight"].use = function(world,entity,active_abil)
  local summon_name = "knight." .. active_abil.id
  local entity = entities.create_summon("knight","knight",entity.x,entity.y,defs.PLAYER_L,defs.PLAYER_L,summon_name,entity.name,"knight",entity.team)
  world.entities[summon_name] = entity
end

abilities["reflect"].use = function(world,entity,active_abil)
  active_abil.rad = math.sqrt(2*(defs.PLAYER_L/2)^2)
end

abilities["reflect"].draw = function(world,entity,active_abil)
  local sp = get_entity_smooth_pos(entity)
  local pos = world_to_screen(sp.x,sp.y)
  love.graphics.setColor(1,0.2,0,0.2)
  love.graphics.circle("fill",pos.x,pos.y,active_abil.rad)
end

function beam_get_endpoint(world,entity,active_abil,smooth)
  local target = world.entities[active_abil.target]
  
  if target == nil or not target.alive then return nil end

  local ep = nil
  local tp = nil
  if smooth then
    ep = get_entity_smooth_pos(entity)
    tp = get_entity_smooth_pos(target)
  else
    ep = {
      x = entity.x,
      y = entity.y
    }
    tp = {
      x = target.x,
      y = target.y
    }
  end

  local dx = ep.x - tp.x
  local dy = ep.y - tp.y

  if dx == 0 then
    if dy < 0 then 
      return {
        x = ep.x,
        y = ep.y - BIGNUM
      }
    else
      return { 
        x = ep.x,
        y = ep.y - BIGNUM
      }
    end
  else
    local m = dy/dx

    if dx < 0 then
      return { 
        x = ep.x + BIGNUM,
        y = ep.y + BIGNUM * m
      }
    else
      return {
        x = ep.x - BIGNUM,
        y = ep.y - BIGNUM * m
      }
    end
  end
end

abilities["beam"].use = function(world,entity,active_abil)
  active_abil.target = entity.shoot_target
  active_abil.last_dmg = nil
end

abilities["beam"].update = function(world,entity,active_abil)
  -- Deal damage
  if active_abil.last_dmg == nil or world.tick > (active_abil.last_dmg + math.floor(defs.TPS / abilities["beam"].frequency)) then
    active_abil.last_dmg = world.tick

    local endpoint = beam_get_endpoint(world,entity,active_abil,false)
    if endpoint == nil then return false end

    for ename,e in pairs(world.entities) do
      if (e.team ~= entity.team) and e.alive and e.targetable and line_intersects_rect(entity.x,entity.y,endpoint.x,endpoint.y,e.x-e.w/2,e.y-e.h/2,e.w,e.h) then
        deal_damage(ename,abilities["beam"].damage)
      end
    end
  end

  return true
end

abilities["beam"].draw = function(world,entity,active_abil)
  local endpoint = beam_get_endpoint(world,entity,active_abil,true)

  local sp = get_entity_smooth_pos(entity)

  if endpoint == nil then return end
  local targetpos = world_to_screen(endpoint.x,endpoint.y)
  local entitypos = world_to_screen(sp.x,sp.y)

  love.graphics.setColor(triangle(10,active_abil.t0) * 0.5 + 0.5,triangle(10,active_abil.t0) * 0.5 + 0.5,1)
  love.graphics.line(entitypos.x,entitypos.y,targetpos.x,targetpos.y)
end

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
    anchor = Anchor.BOTTOM_LEFT,
    x_off = 40,
    y_off = -40,
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
    anchor = Anchor.BOTTOM_LEFT,
    x_off = 40,
    y_off = ui["abilities"].y_off - ui["abilities"].h - 10,
    w = ui["abilities"].w,
    h = 20
  }

  ui["health_bar"] = {
    visible = true,
    anchor = Anchor.BOTTOM,
    x_off = 0,
    y_off = -40,
    w = 400,
    h = 80
  }
end

----> Remove game UI
function ui_remove_game()
  ui["abilities"] = nil
  ui["abilities_book"] = nil
  ui["charge_bar"] = nil
  ui["health_bar"] = nil
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

----> Debug command
function command(input_str)
  logging.log_info("> " .. input_str)

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
  elseif command == "fog" then
      local show_hide = split_command[2]
      if show_hide == "show" then
      world_dbg_showfog = true
      elseif show_hide == "hide" then
      world_dbg_showfog = false
      else
          logging.log_warning("fog [show | hide]")
      end
  elseif command == "possess" then
      if world.entities[split_command[2]] ~= nil then
      curr_entity = split_command[2]
      else
          logging.log_warning("Could not possess that entity")
      end
  elseif command == "list" then
      local ents = ""
      for ename,e in pairs(world.entities) do
      ents = ents .. ename .. " "
      end
      logging.log_info(ents)
  elseif command == "join" then
    join_team(curr_entity,split_command[2])
    logging.log_info("Joined team: " .. split_command[2])
  else
    logging.log_warning("Unknown command: " .. command)
  end
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

  -- Framerate
  love.graphics.setColor(1,1,1,1)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)

  -- World tick
  if world then
    love.graphics.print("World tick: " .. tostring(world.tick),10,40)
  end

  -- Logs
  local y = h - 3 * lh
  local n = 20
  local li = logging.n_logs
  local l = 1

  while l <= n do
      if li < 1 then
      break
      end
      
      local log = logging.log_ledger[li]
      local logtext = logging.log_text(log)
      
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
  love.graphics.printf(command_input,0.5 * lh, h - 1.5 * lh,w - lh)
end


----> Capturing debug handler
function debug_keyhandler(key,pressed)
  if pressed then
      if key == 'return' then
          command(command_input)
      command_input = ""
      elseif key == 'backspace' or key == 'delete' then
        command_input = string.sub(command_input,1,string.len(command_input)-1)
      else
      local keytest = key
      if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
          keytest = "shift " .. key
      end
      local char = LegalKeys[keytest]
      if char then
        command_input = command_input .. char
      end
  end
end

return true
end

----> Capturing debug mous handler
function debug_mousehandler(x,y,button,pressed)
  return true
end

function debug_init()
  command_input = ""
end

--> WORLD
----> Initialise
function world_init()
  world = nil
  world_dbg_showfog = true
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
  elseif pattern[1] == "tesselate" then
    local sprite = pattern[2]
    local img = get_image(sprite)
    local tilew = tonumber(pattern[3])
    local tileh = tonumber(pattern[4])

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
        local xscale = tilew / img.w
        local yscale = tileh / img.h
        
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(img.img,x,y,0,xscale,yscale)
      end
    end
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
function get_target_pos(target_name)
  local entity = world.entities[target_name]
  if entity == nil or not entity.alive then return nil end
  return {
    x = entity.x,
    y = entity.y
  }
end

function draw_entity(e)

  if e.visible and e.alive then
    -- Entity image
    local sp = get_entity_smooth_pos(e)
    local pos = world_to_screen(sp.x,sp.y)
    local img = get_image(e.sprite)
    local xscale = e.w / img.w
    local yscale = e.h / img.h
    love.graphics.setColor(1,1,1)
    love.graphics.draw(img.img,pos.x-e.w/2,pos.y-e.h/2,0,xscale,yscale)

    local player = world.entities[curr_entity]

    if e.targetable and player ~= nil and player.team ~= e.team then
      love.graphics.setColor(1,triangle(0.5),0)
      love.graphics.rectangle("line",pos.x-e.w/2-5,pos.y-e.h/2-5,e.w+10,e.h+10)
    end

    -- Entity HP bar
    local hpw = 80
    local hph = 10
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill",pos.x - hpw/2,pos.y + e.h/2 + hph,hpw,hph)
    local hpv = (e.hp / e.max_hp) * hpw
    love.graphics.setColor(0,1,0)
    love.graphics.rectangle("fill",pos.x - hpw/2,pos.y + e.h/2 + hph,hpv,hph)

    -- Draw active abilities
    for aname,aabils in pairs(e.active_abilities) do
      for _,aabil in pairs(aabils) do
        abilities.draw(world,e,aabil)
      end
    end
  end
end

function get_entity_smooth_pos(e)
  local prev_pos = prev_entities_pos[e.name]
  if k == nil or prev_pos == nil then
    return {
      x = e.x,
      y = e.y
    }
  else
    return {
      x = k * e.x + (1 - k) * prev_pos.x,
      y = k * e.y + (1 - k) * prev_pos.y
    }
  end

end

function get_bullet_smooth_pos(b,k)
  local prev_pos = prev_bullets_pos[b.id]
  if prev_pos == nil then
    local source = world.entities[b.source]
    if source ~= nil then
      prev_pos = {
        x = source.x,
        y = source.y
      }
    end
  end

  if k == nil or prev_pos == nil then
    return {
      x = b.x,
      y = b.y
    }
  else
    return {
      x = k * b.x + (1 - k) * prev_pos.x,
      y = k * b.y + (1 - k) * prev_pos.y
    }
  end
end

----> Draw
function world_draw()
  local player = world.entities[curr_entity]
  local bg = world.background
  
  if bg ~= nil then
    local sp = get_entity_smooth_pos(player)
    draw_background(bg,sp.x - OFFSET_X,sp.y - OFFSET_Y)
  end

  world_draw_objects("below")

  world_draw_objects("collide")

  local player_entity = nil

  for ename,e in pairs(world.entities) do
    if ename == curr_entity then
      player_entity = e
    else
      draw_entity(e)
    end
  end


  -- Draw what player is seeing
  if player_entity ~= nil then
    draw_entity(player_entity)

    if player_entity.move_target ~= nil then
      local tpos = world_to_screen(player_entity.move_target.x,player_entity.move_target.y)
      love.graphics.setColor(0,1,0)
      love.graphics.circle("fill",tpos.x,tpos.y,defs.PLAYER_L/8)
    end

    for _,loot in pairs(player_entity.player_loot) do
      local parts = split_spaces(loot.name)
      local pos = world_to_screen(loot.x,loot.y)
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

    if player_entity.shoot_target ~= nil then
      local et = world.entities[player_entity.shoot_target]
      if et ~= nil and et.alive then
        local sp = get_entity_smooth_pos(et)
        local tp = world_to_screen(sp.x,sp.y)
        local img = get_image("target")
        local xscale = defs.PLAYER_L / img.w / 2
        local yscale = defs.PLAYER_L / img.h / 2
        love.graphics.setColor(1,1,1)
        love.graphics.draw(img.img,tp.x - defs.PLAYER_L / 4, tp.y - defs.PLAYER_L / 4,0,xscale,yscale)
      end
    end

    local bullets = world.bullets
    for id,bullet in pairs(bullets) do
      local sp = get_bullet_smooth_pos(bullet,k)
      local bpos = world_to_screen(sp.x,sp.y)
      local bullet_target = world.entities[bullet.target]
      if bullet_target ~= nil then
        if bullet_target.team == player_entity.team then
          love.graphics.setColor(1,0,0)
        else
          love.graphics.setColor(0,0,1)
        end
        love.graphics.circle("fill",bpos.x,bpos.y,BULLET_RADIUS)
      end
    end
  end

  world_draw_objects("above")

  local player = world.entities[curr_entity]

  if world_dbg_showfog then
    -- Create fog mask
    local maskcanvas = love.graphics.newCanvas(love.graphics.getWidth(),love.graphics.getHeight())
    
    love.graphics.setCanvas(maskcanvas)
    love.graphics.clear(1,1,1,1)
    love.graphics.setBlendMode("multiply","premultiplied")
    love.graphics.setColor(0,0,0,0)
    local zones_to_iterate = world.zones
    if player.player then
      zones_to_iterate = player.player_discovered_zones
    end
    for zname,_ in pairs(zones_to_iterate) do
      local zone = world.zones[zname]
      for i,region in pairs(zone.regions) do
        local p1 = world_to_screen(region.x1,region.y1)
        local w = region.x2 - region.x1
        local h = region.y2 - region.y1

        love.graphics.rectangle("fill",p1.x,p1.y,w,h)
      end
    end

    -- Create fog
    local fogcanvas = love.graphics.newCanvas(love.graphics.getWidth(),love.graphics.getHeight())
    love.graphics.setCanvas(fogcanvas)
    love.graphics.clear(0,0,0,1)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1,0,0,1)
    if world.fog ~= nil then
      local sp = get_entity_smooth_pos(player)
      draw_background(world.fog,sp.x - OFFSET_X,sp.y - OFFSET_Y)
    end

    -- Apply mask
    love.graphics.setBlendMode("multiply","premultiplied")
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(maskcanvas)

    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(fogcanvas)
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

function get_fog_overlap(x,y,w,h)
  local x1 = x - w/2
  local x2 = x + w/2
  local y1 = y - h/2
  local y2 = y + h/2

  local edge_points = {
    { 
      x = x2, 
      y = y2,
      outside = true,
    },
    {
      x = x1, 
      y = y2,
      outside = true,
    },
    {
      x = x1, 
      y = y1,
      outside = true,
    },
    { 
      x = x2, 
      y = y1,
      outside = true,
    }
  }

  local regions = {}

  -- iterate through all regions checking edge points
  for zname,zone in pairs(world.zones) do
    for _,region in pairs(zone.regions) do
      table.insert(regions,region)

      for i,ep in pairs(edge_points) do
        if region.x1 <= ep.x and ep.x <= region.x2 and region.y1 <= ep.y and ep.y <= region.y2 then
          ep.outside = false
        end
      end
    end
  end

  local outside_points = {}

  for i,ep in pairs(edge_points) do
    if ep.outside then
      local dmin = nil
      local dx = 0
      local dy = 0
      
      for ir,region in pairs(regions) do
        local dxr = 0

        if ep.x > region.x2 then
          -- Right of region
          dxr = ep.x - region.x2

        elseif ep.x < region.x1 then
          -- Left or region
          dxr = ep.x - region.x1
        end

        local dyr = 0

        if ep.y > region.y2 then
          -- Below region
          dyr = ep.y - region.y2
        elseif ep.y < region.y1 then
          -- Above region
          dyr = ep.y - region.y1
        end

        local d = math.sqrt(dxr^2 + dyr^2)
        if dmin == nil or d < dmin then
          dmin = d
          dx = dxr
          dy = dyr
        end
      end

      table.insert(outside_points,{
        dx = dx,
        dy = dy
      })
    end
  end

  local furthest_point = nil
  local furthest_dist = nil
  for i,op in pairs(outside_points) do
    local d = math.sqrt(op.dx^2 + op.dy^2)
    if furthest_point == nil or d > furthest_dist then
      furthest_dist = d
      furthest_point = op
    end
  end

  if furthest_point == nil then
    return {
      x = 0,
      y = 0
    }
  else
    return {
      x = furthest_point.dx,
      y = furthest_point.dy
    }
  end
end

function adjust_pos_for_collisions(pos,w,h)
  local fog_overlap = get_fog_overlap(pos.x,pos.y,w,h)

  if fog_overlap ~= nil then
    pos.x = pos.x - fog_overlap.x
    pos.y = pos.y - fog_overlap.y
  end

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

----> Player uses ability
function use_ability(entity_name,ability_num)
  local entity = world.entities[entity_name]
  if world ~= nil and entity ~= nil and entity.ability_map[ability_num] ~= nil then
    local ability_name = entity.ability_map[ability_num]
    if not entities.can_use_ability(world,entity,ability_name) then
      log_info("Can't use" .. ability_name)
      return
    end

    entities.use_ability(world,entity,ability_name)
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

----> Create ability use particle
function create_ability_particle(aname,x,y,h)
  local t0 = love.timer.getTime()
  table.insert(particles,{
    sprite = aname,
    x = x,
    y = y,
    should_destroy = function(p)
      p.y = p.y + ((y - h) - p.y) / 16
      if love.timer.getTime() - t0 > 0.7 then
        return true
      else
        return false
      end
    end
  })
end

----> Deal entity damage
function deal_damage(ename,dmg,interrupt)
  if interrupt == nil then interrupt = false end

  local ent = world.entities[ename]

  if ent == nil or not ent.alive then
    return
  end

  ent.hp = ent.hp - dmg

  table.insert(world.new_particles,"hit " .. tostring(dmg) .. " " .. tostring(ent.x) .. " " .. tostring(ent.y) .. " " .. tostring(ent.h/2 + 20))

  -- Die
  if ent.hp <= 0 then
    if ent.drops ~= nil then
      for ename,e in pairs(world.entities) do
        if e.player then
          for _,drop in pairs(ent.drops) do
            if math.random() < drop.rate then
              table.insert(e.drops,{
                name = drop.name,
                x = ent.x + (0.5 - math.random()) * DROP_L / 2,
                y = ent.y + (0.5 - math.random()) * DROP_L / 2
              })
            end
          end
        end
      end
    end

    -- Remove the entity
    ent.alive = false
  end
end

----> Resolve bullet
function resolve_bullet(bullet)
  -- Create hit particle
  local source = world.entities[bullet.source]
  if source ~= nil and source.alive then

    source.charge = source.charge + 1
    if source.charge >= defs.CHARGE_TO_UNLOCK then
      source.charge = defs.CHARGE_TO_UNLOCK
      entities.unlock_random(world,source)
    end

    deal_damage(bullet.target,source.damage)
  end
end

----> Player pickup drop
function pickup(username,i)
  local player = world.entities[username]
  if player ~= nil then
    local loot_name = player.player_loot[i].name
    local parts = split_spaces(loot_name)

    if parts[1] == "ability" then
      if player.abilities[parts[2]] == nil then
        player.abilities[parts[2]] = {
          slot = -1,
          times_used = 0
        }
        player.active_abilities[parts[2]] = {}
      end
    end

    player.player_loot[i] = nil
  end
end

----> Interact with object
function interact(username,layer,objname)
  local player = world.entities[username]
  if player ~= nil and world.objects[layer] ~= nil then
    local obj = world.objects[layer][objname]

    if obj.isa ~= nil then
      if obj.isa == "lectern" then
        player.player_ability_book_open = true
      end
    end
  end
end

----> Update
function world_update()
  if world ~= nil then
    world.tick = world.tick + 1
    world.new_particles = {}
    
    for ename,entity in pairs(world.entities) do
      -- Open ability book
      if entity.name == curr_entity then
        -- View
        if entity.player_ability_book_open and ui["abilities_book"] ~= nil then
          ui["abilities_book"].visible = true
        else
          ui["abilities_book"].visible = false
        end
      end

      -- Update entity
      entities.update(world,entity)

      ::continue::
    end

    local bullets = world.bullets
    for id,bullet in pairs(bullets) do
      local source = world.entities[bullet.source]
      local target = world.entities[bullet.target]

      if source == nil or not source.alive or target == nil or not target.alive then
        bullets[id] = nil
      else
        local p = utils.new_pos(bullet.x,bullet.y,target.x,target.y,BULLET_SPEED)
        local collisions = check_all_collisions(p.x,p.y,BULLET_RADIUS * 1.4, BULLET_RADIUS * 1.4)
        for _,collision in pairs(collisions) do
          bullets[id] = nil
          goto continue
        end

        bullet.x = p.x
        bullet.y = p.y
        if p.arrived then
          local has_reflect = false

          if target.active_abilities["reflect"] ~= nil then
            for i,abil in pairs(target.active_abilities["reflect"]) do
              has_reflect = true
            end
          end

          if has_reflect then
            local prev_target = bullet.target
            bullet.target = bullet.source
            bullet.source = prev_target
          else
            resolve_bullet(bullet)
            bullets[id] = nil
          end
        end
      end

      ::continue::
    end

    -- Clean up entities
    for ename,e in pairs(world.entities) do
      if not e.alive then
        world.entities[ename] = nil
      end
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
        condition = o.condition,
        failmsg = o.failmsg,
        x = o.x,
        y = o.y,
        w = o.w,
        h = o.h
      }
    end
  end

  local world_ents = {}
  for ename,e in pairs(world.entities) do
    if (not e.ephemeral) and e.alive then
      world_ents[ename] = {
        sprite = e.sprite,
        visible = e.visible,
        type = e.type,
        zone = e.zone,
        x = e.x,
        y = e.y,
        w = e.w,
        h = e.h
      }
    end
  end

  local world_zones = {}
  if world.zones ~= nil then
    for name,zone in pairs(world.zones) do
      local new_zone = {
        regions = {}
      }
      
      for i,region in pairs(zone.regions) do
        new_zone.regions[i] = {
          x1 = region.x1,
          x2 = region.x2,
          y1 = region.y1,
          y2 = region.y2
        }
      end

      world_zones[name] = new_zone
    end
  end

  local world_deets = {
    spawn = {
      x = world.spawn.x,
      y = world.spawn.y,
    },
    zones = world_zones,
    background = world.background,
    fog = world.fog,
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
          condition = o.condition,
          failmsg = o.failmsg,
          activated = false,
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
      new_world_entities[ename] = entities.create_enemy(edef.type,edef.sprite,edef.visible,edef.zone,edef.x,edef.y,edef.w,edef.h,ename)
    end
  end
  new_world_entities["void"] = entities.create("point",nil,false,nil,world_deets.spawn.x,world_deets.spawn.y,1,1,nil,"void")
  new_world_entities["void"].ephemeral = true

  local new_world_zones = {}
  if world_deets.zones ~= nil then
    for name,zone in pairs(world_deets.zones) do
      local new_zone = {
        discovered = false,
        regions = {}
      }
      
      for i,region in pairs(zone.regions) do
        new_zone.regions[i] = {
          x1 = region.x1,
          x2 = region.x2,
          y1 = region.y1,
          y2 = region.y2
        }
      end

      new_world_zones[name] = new_zone
    end
  end
  
  local new_world = {
    tick = 0,
    spawn = {
      x = world_deets.spawn.x,
      y = world_deets.spawn.y,
    },
    zones = new_world_zones,
    background = world_deets.background,
    fog = world_deets.fog,
    objects = new_world_objs,
    entities = new_world_entities,
    bullets = {},
    new_particles = {}
  }
  t_accum = 0
  
  world = new_world
end

----> Join world
function world_join(username)
  log_info(username .. " joined!")
  curr_entity = "player."..username

  local new_entity = entities.create_player(DEFAULT_PLAYER.avatar,world.spawn.x,world.spawn.y,defs.PLAYER_L,defs.PLAYER_L,DEFAULT_PLAYER.abilities,curr_entity)
  
  world.entities["player."..username] = new_entity
end

function join_team(username,team)
  local e = world.entities[username]
  if e ~= nil and team ~= nil then
    e.team = team
  end
end

----> Set shoot target position
function set_shoot_target(x,y)
  if world ~= nil and world.entities[curr_entity] ~= nil then
    local player = world.entities[curr_entity]
    
    local closest = nil
    local distance = nil
    for ename,e in pairs(world.entities) do
      if e.targetable and (e.team ~= player.team) and e.alive then
        local d = utils.euclid(x,y,e.x,e.y)
        if closest == nil or d < distance then
          closest = ename
          distance = d
        end
      end
    end

    if closest ~= nil then
      player.shoot_target = closest
    end
  end
end

function shoot_nearest()
  if world ~= nil and world.entities[curr_entity] ~= nil then
    local player = world.entities[curr_entity]
    set_shoot_target(player.x,player.y)
  end
end

----> Convert screen to world
function screen_to_world(x,y)
  if world == nil or world.entities[curr_entity] == nil then
    return nil
  end
  
  local player = world.entities[curr_entity]
  local sp = get_entity_smooth_pos(player)
  local sc = screen_coords(sp.x,sp.y)
  
  return {
    x = x + sc.x1 - OFFSET_X,
    y = y + sc.y1 - OFFSET_Y,
  }
end

----> Convert world to screen
function world_to_screen(x,y)
  if world == nil or world.entities[curr_entity] == nil then
    return nil
  end
  
  local player = world.entities[curr_entity]
  local sp = get_entity_smooth_pos(player)
  local sc = screen_coords(sp.x,sp.y)
  
  return {
    x = x - sc.x1 + OFFSET_X,
    y = y - sc.y1 + OFFSET_Y,
  }
end

--> GAME

----> Initialise
function game_init()
  game_keyhandlers = {}
  game_dbg_pos = nil
  particles = {}

  prev_entities_pos = {}
  prev_bullets_pos = {}
end

----> Move
function move_char()
  local mx, my = love.mouse.getPosition()  
  local new_pos = screen_to_world(mx,my)
      
  world.entities[curr_entity].move_target = {
    x = new_pos.x,
    y = new_pos.y
  }
end

function save_positions()
  if world then
    prev_entities_pos = {}
    prev_bullets_pos = {}

    for ename,e in pairs(world.entities) do
      prev_entities_pos[ename] = {
        x = e.x,
        y = e.y
      }
    end

    for id,bullet in pairs(world.bullets) do
      prev_bullets_pos[id] = {
        x = bullet.x,
        y = bullet.y
      }
    end
  end
end

----> Update
function game_update()
  if world == nil then
    world_load(DEFAULT_WORLD)
    world_join(DEFAULT_USERNAME)
    ui_add_game()
  end
  
  -- If timestep has passed, step simulation
  t_accum = t_accum + love.timer.getDelta()
  if t_accum > defs.TIMESTEP then
    t_accum = t_accum - defs.TIMESTEP

    -- Draw particles
    for i,p in pairs(world.new_particles) do
      local particle_parts = split_spaces(p)
      if particle_parts[1] == "hit" then
        local dmg = tonumber(particle_parts[2])
        local x = tonumber(particle_parts[3])
        local y = tonumber(particle_parts[4])
        local h = tonumber(particle_parts[5])
        create_hit_particle(dmg,x,y,h)
      elseif particle_parts[1] == "ability" then
        local aname = particle_parts[2]
        local x = tonumber(particle_parts[3])
        local y = tonumber(particle_parts[4])
        local h = tonumber(particle_parts[5])
        create_ability_particle(aname,x,y,h)
      end
    end

    save_positions()

    world_update()

    if world.entities[curr_entity] == nil then
      curr_entity = "void"
    end
  end
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
    elseif part.sprite ~= nil then
      local l = UI_ABILITY_LEN / 2
      local img = get_image(part.sprite)
      local pos = world_to_screen(part.x,part.y)
      local xscale = l / img.w
      local yscale = l / img.h

      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(img.img,pos.x-l/2,pos.y-l/2,0,xscale,yscale)

      love.graphics.setColor(0,1,0,1)
      love.graphics.rectangle("line",pos.x-l/2,pos.y-l/2,l,l)

      if part.should_destroy(part) then
        particles[i] = nil
      end
    end

    n = n + 1
  end
end

----> Draw
function game_draw()
  if world ~= nil and world.entities[curr_entity] ~= nil then
    if defs.SMOOTH_RENDER then
      k = t_accum / defs.TIMESTEP
      if k > 1 then 
        if defs.DRIFT > 0 then
          k = 1 + defs.DRIFT - defs.DRIFT * math.exp((1 - k) / defs.DRIFT)
        else
          k = 1
        end
      end
    else
      k = 0
    end
    world_draw()
    game_draw_particles()
  else
    love.graphics.printf("Loading",0,0,800)
  end
end

----> Generic action
function action()
  if world ~= nil and world.entities[curr_entity] ~= nil then
    local player = world.entities[curr_entity]
    local closest = nil
    local dist = nil
    if player.player_loot ~= nil then
      for i,drop in pairs(player.player_loot) do
        local ddrop = utils.euclid(player.x,player.y,drop.x,drop.y)
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
            local side = check_collision(player.x,player.y,defs.PLAYER_L + 2 * INTERACT_DIST,defs.PLAYER_L + 2 * INTERACT_DIST,obj.x,obj.y,obj.w,obj.h)

            if side ~= nil then
            
              local d = 0
              if side == 1 then
                d = player.x - obj.x - defs.PLAYER_L / 2 - obj.w / 2
              elseif side == 2 then
                d = player.y - obj.y - defs.PLAYER_L / 2 - obj.h / 2
              elseif side == 3 then
                d = obj.x - player.x - defs.PLAYER_L / 2 - obj.w / 2
              elseif side == 4 then
                d = obj.y - player.y - defs.PLAYER_L / 2 - obj.h / 2
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
        pickup(curr_entity,i)
      elseif parts[1] == "object" then
        interact(curr_entity,parts[2],parts[3])
      end
    end
  end
end

----> Use ability
function ability_handler(key, pressed)
  if pressed then
    local ability_num = AbilityKey[key]
    use_ability(curr_entity,ability_num)
  end
end

----> Map keys
function register_key_handlers()
  for k,v in pairs(AbilityKey) do
    game_keyhandlers[k] = ability_handler
  end
  game_keyhandlers["space"] = function(key,pressed) if pressed then action() end end
  game_keyhandlers["f"] = function(key,pressed) if pressed then 
    world.entities[curr_entity].shooting = not world.entities[curr_entity].shooting
    end end
  game_keyhandlers["d"] = function(key,pressed) 
    if pressed then 
      world.entities[curr_entity].shoot_target = nil
      world.entities[curr_entity].shooting = false
    end 
  end
  game_keyhandlers["tab"] = function(key,pressed) if pressed then shoot_nearest() end end
  game_keyhandlers["up"] = function(key,pressed) update_movement() end
  game_keyhandlers["left"] = function(key,pressed) update_movement() end
  game_keyhandlers["down"] = function(key,pressed) update_movement() end
  game_keyhandlers["right"] = function(key,pressed) update_movement() end
end

----> Key handler
function game_keyhandler(key,pressed)  
  local handler = game_keyhandlers[key]
  if handler ~= nil then
    handler(key,pressed)
  end
end

function game_mouse_released(button)

end

----> Mouse handler
function game_mousehandler(x,y,button,pressed)
  if pressed then
    if button == 1 then
      move_char()
    elseif button == 2 then
      local pos = screen_to_world(x,y)
      set_shoot_target(pos.x,pos.y)
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
  if uidef == nil or curr_entity == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)
  
  local player = world.entities[curr_entity]
  local player_abilities = player.ability_map

  if player_abilities ~= nil then

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
      local abil_def = abilities[player_abilities[i]]

      if abil_def == nil then goto continue end

      love.graphics.setColor(Color["blue"])
      love.graphics.rectangle('fill',p0.x + dx,p0.y + dy,l,l)

      local ability_img = get_image(player_abilities[i])
      local xscale = imgl / ability_img.w
      local yscale = imgl / ability_img.h
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(ability_img.img,p0.x + dx + m / 2, p0.y + dy+ m/2, 0, xscale, yscale)

      if not entities.can_use_ability(world,player,player_abilities[i]) then
        love.graphics.setColor(1,0,0,0.5)
        love.graphics.rectangle("fill",p0.x + dx + m/2, p0.y + dy + m/2,imgl,imgl)
      end

      if player.abilities[player_abilities[i]].locked then
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

      ::continue::
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
  if uidef == nil or curr_entity == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  local divs = ui_divide_abilities_book()

  local player = world.entities[curr_entity]
  local ability_map = player.ability_map
  local player_abilities = player.abilities

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
  for aname,ability in pairs(player_abilities) do
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
    local selected_ability = abilities[uidef.selected]

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

  if uidef == nil or curr_entity == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  local player = world.entities[curr_entity]

  local charge_ratio = player.charge / defs.CHARGE_TO_UNLOCK

  love.graphics.setColor(0,0,0,0.25)
  love.graphics.rectangle("fill",p0.x,p0.y,uidef.w,uidef.h)
  love.graphics.setColor(0.3,0.6,1)
  love.graphics.rectangle("fill",p0.x,p0.y,charge_ratio * uidef.w,uidef.h)
end

function ui_draw_health_bar()
  local uidef = ui["health_bar"]

  if uidef == nil or curr_entity == nil then return end

  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  local default_font = love.graphics.newFont()
  local large_font = love.graphics.newFont(20)

  local player = world.entities[curr_entity]

  local health_ratio = player.hp / player.max_hp

  love.graphics.setFont(large_font)
  local text = "HP: " .. player.hp .. " / " .. tostring(player.max_hp)
  local th = large_font:getHeight(text)
  local tw = large_font:getWidth("HP: 1000 / 1000")

  love.graphics.setColor(0,0,0,0.25)
  love.graphics.rectangle("fill",p0.x,p0.y,uidef.w,uidef.h)
  love.graphics.setColor(0,1,0)
  love.graphics.rectangle("fill",p0.x,p0.y,health_ratio * uidef.w,uidef.h)

  love.graphics.rectangle("fill",p0.x + uidef.w/2 - tw/2 - 2, p0.y + uidef.h/2 - th/2 - 2, tw + 4, th + 4)

  love.graphics.setColor(0,0,0)
  love.graphics.print(text,p0.x + uidef.w / 2 - tw/2,p0.y + uidef.h / 2 - th/2)
  love.graphics.setFont(default_font)
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
      use_ability(curr_entity,i)
      return true
    end
  end
  
  return false
end

----> Abilties book mouse click
function ui_mousehandler_abilities_book(x,y,button,pressed)
  local uidef = ui["abilities_book"]
  if uidef == nil then return end

  local player = world.entities[curr_entity]
  local p0 = get_anchor_point(uidef.anchor,uidef.x_off,uidef.y_off,uidef.w,uidef.h)

  if x < p0.x or x > (p0.x + uidef.w) or y < p0.y or y > (p0.y + uidef.h) then
    player.player_ability_book_open = false
    uidef.visible = false
    uidef.selected = nil
    uidef.learning = false
    return false
  end

  local bh = UI_ABILITYBOOK_HEADER
  local bm = UI_ABILITYBOOK_MARGIN
  local il = UI_ABILITY_ICON_LEN
  local im = UI_ABILITY_ICON_MARGIN

  local ability_map = player.ability_map
  local player_abilities = player.abilities

  local abilities_indices = {}
  for aname,ability in pairs(player_abilities) do
    table.insert(abilities_indices,aname)
  end

  local divs = ui_divide_abilities_book()

  -- Check close button
  if x > divs.x_close and x < divs.x_close + bh and y > divs.y_close and y < divs.y_close + bh then
    player.player_ability_book_open = false
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

      local selected_ability_def = player_abilities[uidef.selected]
      
      local prev_ability = ability_map[i]
      local prev_ability_def = player_abilities[prev_ability]
      if prev_ability_def == nil then
        -- Less than 10 abilities (edge case)
        ability_map[selected_ability_def.slot] = nil
        selected_ability_def.slot = i
        selected_ability_def.locked = true
        ability_map[i] = uidef.selected
      else
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

--> LOVE
----> Load
function love.load()
  logging.init()
  log_info("|    ARGO V    |")

  love.window.setVSync( 0 )

  state_init()
  debug_init()
  assets_init()
  world_init()
  game_init()
  ui_init()
  
  register_key_handlers()
  
  debug = Debug.HIDDEN
  paused = false
  view = View.INIT
  
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