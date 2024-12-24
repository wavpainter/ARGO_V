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
  ["target"] = "target.png"
}
local GameUI = {
  "spells",
}
local Spells = {
  MARGIN_X = 10,
  MARGIN_Y = 10,
  ITEM_WIDTH = 60,
  DIVISION = 10,
}
local DEFAULT_WORLD = {
  boundaries = { x1 = -10000, x2 = 10000, y1 = -10000, y2 = 10000 },
  spawn = {x = 0, y = 0 },
  background = "tiles lightgrey white 100 100",
  objects = { {
    sprite = "bin",
    x = 200,
    y = 200,
    w = 100,
    h = 100
  },
  {
    sprite = "love",
    x = 1000,
    y = 1000,
    w = 100,
    h = 100
  }
 }
}
local DEFAULT_PLAYER = {
  abilities = {
    [1] = "invis",
    [2] = "beam",
    [3] = "cantrip",
    [4] = "root",
    [5] = "negate",
    [6] = "push",
    [7] = "rage",
    [8] = "reflect",
    [9] = "stun",
    [10] = "pull"
  },
  avatar = "jason",
  shoot_speed = 2,
}
local DEFAULT_USERNAME = "jason"
local MOVE_DELAY_S = 0.15
local PLAYER_L = 75
local MOVE_SPEED = 1000
local BULLET_SPEED = 1500
local BULLET_RADIUS = 10

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


function save_world_to(savename)
  if world ~= nil then
    local encoded = json.encode(world.deets)
    local f = love.filesystem.newFile(savename .. ".json")
    f:open("w")
    f:write(encoded)
    f:close()

    log_info("Saved to " .. savename)
  else
    log_warning("Cannot save, no world loaded")
  end
end

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

----> Draw
function world_draw()
  local player = world.players[DEFAULT_USERNAME]
  local sc = screen_coords(player.x,player.y)
  local bg = world.deets.background
  
  if bg ~= nil then
    draw_background(bg,sc)
  end

  local objs = world.objects
  for _,o in pairs(objs) do
    local pos = world_to_screen(o.x,o.y)
    local img = get_image(o.sprite)
    local xscale = o.w / img.w
    local yscale = o.h / img.h
    love.graphics.setColor(1,1,1)
    love.graphics.draw(img.img, pos.x,pos.y,0,xscale,yscale)
  end

  local players = world.players
  for username,p in pairs(players) do
    if username == DEFAULT_USERNAME and p.move_target ~= nil then
      local tpos = world_to_screen(p.move_target.x,p.move_target.y)
      love.graphics.setColor(0,1,0)
      love.graphics.circle("fill",tpos.x,tpos.y,PLAYER_L/8)
    end

    local pos = world_to_screen(p.x,p.y)
    local img = get_image(p.avatar)
    local xscale = PLAYER_L / img.w
    local yscale = PLAYER_L / img.h
    love.graphics.setColor(1,1,1)
    love.graphics.draw(img.img,pos.x - PLAYER_L/2,pos.y - PLAYER_L/2,0,xscale,yscale)

    if username == DEFAULT_USERNAME and p.shoot_target ~= nil then
      local spos = nil
      if p.shoot_target.type == "pos" then
        spos = world_to_screen(p.shoot_target.x,p.shoot_target.y)
      else
        spos = world_to_screen(0,0)
      end
      local img = get_image("target")
      local xscale = PLAYER_L / img.w / 2
      local yscale = PLAYER_L / img.h / 2
      love.graphics.setColor(1,1,1)
      love.graphics.draw(img.img,spos.x - PLAYER_L / 4, spos.y - PLAYER_L/4,0,xscale,yscale)
    end
  end

  local bullets = world.bullets
  for _,bullet in pairs(bullets) do
    local bpos = world_to_screen(bullet.x,bullet.y)
    love.graphics.setColor(1,0,0)
    love.graphics.circle("fill",bpos.x,bpos.y,BULLET_RADIUS)
  end
end

----> Have player shoot at something
function shoot_bullet(player)
  if player.shoot_target ~= nil then
    local new_bullet = {
      source = "player " .. player.username,
      x = player.x,
      y = player.y
    }

    if player.shoot_target.type == "pos" then
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

----> Update player
function update_player(player,tick)
  if player.move_target ~= nil then
    local new_pos = new_pos(player.x,player.y,player.move_target.x,player.move_target.y,MOVE_SPEED)
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

----> Get player abilities
function get_abilities(username)
  if world == nil or world.players[username] == nil then
    return nil
  end

  local player = world.players[username]
  return player.abilities
end

----> Player uses ability
function use_ability(username,ability_num)
  if world ~= nil and world.players[username] ~= nil then
    player = world.players[username]
    
    local ability_name = player.abilities[ability_num]
    local ability_index = ability_index_map[ability_name]
    log_info(username .. " used ability: " .. ability_name)
  end
end

----> Update bullet
function update_bullet(bullet,tick)
  if bullet.target ~= nil then
    if bullet.target.type == "pos" then
      local new_pos = new_pos(bullet.x,bullet.y,bullet.target.x,bullet.target.y,BULLET_SPEED)
      bullet.x = new_pos.x
      bullet.y = new_pos.y
      if new_pos.arrived then
        bullet.target = nil
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
    for _,bullet in pairs(bullets) do
      update_bullet(bullet,world.tick)
    end
  end
end

----> Load world
function world_load(world_deets)
  log_info("Loading a new world.")

  local new_world_objs = {}
  if world_deets.objects ~= nil then
    for _,o in pairs(world_deets.objects) do
      table.insert(new_world_objs,{
        sprite = o.sprite,
        x = o.x,
        y = o.y,
        w = o.w,
        h = o.h
      })
    end
  end
  
  local new_world = {
    tick = 0,
    deets = world_deets,
    players = {},
    mobs = {},
    objects = new_world_objs,
    bullets = {}
  }
  
  world = new_world
end

----> Join world
function world_join(username)
  log_info(username .. " joined!")
  
  local spawn = world.deets.spawn
  local new_player = {
    username = username,
    abilities = DEFAULT_PLAYER.abilities,
    avatar = DEFAULT_PLAYER.avatar,
    shoot_speed = DEFAULT_PLAYER.shoot_speed,
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
    player.shoot_target = {
      type = "pos",
      x = x,
      y = y
    }
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
  end
  
  if clicking and t - last_move_s > MOVE_DELAY_S then
    move_char()
    last_move_s = t
  end
  
  world_update()
end

----> Abilities bar mouse click
function game_mousehandler_abilities(x,y,button,pressed)
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

----> Draw the abilities bar
function game_draw_abilities()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  
  local abilities = get_abilities(DEFAULT_USERNAME)

  local ability_key_inv = {}
  for key,ability_num in pairs(AbilityKey) do
    ability_key_inv[ability_num] = key:upper()
  end
  
  local l = 80
  local m = l / 10
  local r = 10

  local x = m
  local y = h - m

  local imgl = l - m
    
  local i = 6
  while i <= 10 do

    love.graphics.setColor(Color["blue"])
    love.graphics.rectangle('fill',x,y - l,l,l)

    local ability_img = get_image(abilities[i])
    local xscale = imgl / ability_img.w
    local yscale = imgl / ability_img.h
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(ability_img.img,x + m / 2, y - l + m/2, 0, xscale, yscale)

    love.graphics.setColor(Color["black"])
    love.graphics.circle("fill",x + r, y - l + r + 2,r)

    love.graphics.setColor(Color["white"])
    love.graphics.print(ability_key_inv[i],x + m/2 + 2,y - l + m/2)

    x = x + m + l
    i = i + 1
  end
  
  x = m
  y = h - l - m - m
  i = 1
  while i <= 5 do
    love.graphics.setColor(Color["blue"])
    love.graphics.rectangle('fill',x,y - l,l,l)

    local ability_img = get_image(abilities[i])
    local xscale = imgl / ability_img.w
    local yscale = imgl / ability_img.h
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(ability_img.img,x + m / 2, y - l + m/2, 0, xscale, yscale)

    love.graphics.setColor(Color["black"])
    love.graphics.circle("fill",x + r, y - l + r + 2,r)

    love.graphics.setColor(Color["white"])
    love.graphics.print(ability_key_inv[i],x + m/2 + 2,y - l + m/2)

    x = x + m + l
    i = i + 1
  end
end

----> Draw
function game_draw()
  if world ~= nil and world.players[DEFAULT_USERNAME] ~= nil then
    world_draw()
    game_draw_abilities()
  else
    love.graphics.printf("Loading",0,0,800)
  end
end

----> Generic action
function action_handler(key,pressed)
  if pressed then
    
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
  game_keyhandlers["space"] = action_handler
  game_keyhandlers["f"] = function(key,pressed) if pressed then toggle_shooting(DEFAULT_USERNAME) end end
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
  
  if game_mousehandler_abilities(x,y,button,pressed) then
    return
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
  
  if debug ~= Debug.HIDDEN then
    debug_draw()
  end
end

----> Update
function love.update()
  if view == View.INIT then
    view = View.MENU
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