--> CONSTANTS
----> Util
color = {
  ["red"] = { 1, 0, 0 },
  ["green"] = { 0, 1, 0 },
  ["blue"] = { 0, 0, 1 },
  ["black"] = { 0, 0, 0 },
  ["white"] = { 1, 1, 1 },
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
local GameUI = {
  "spells",
}
local Spells = {
  MARGIN_X = 10,
  MARGIN_Y = 10,
  ITEM_WIDTH = 60,
  DIVISION = 10,
}
local default_world = {
  boundaries = { x1 = -10000, x2 = 10000, y1 = -10000, y2 = 10000 },
  spawn = {x = 0, y = 0 },
  background = "tiles white green 200 200",
}
local default_username = "jason"
local move_delay_s = 0.1

--> VARIABLES
----> State
local view = nil
local debug = nil
local paused = nil

----> Debug
local recent_ability = nil
local dbg_tick = nil
local log_ledger = nil
local n_logs = nil

----> Menu

----> World
local world = nil
local world_dbg_tick = nil

----> Game
local ability_index_map = nil
local ability_map = nil
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

--> STATE
----> Initialise
function state_init()
  view = nil
  debug = nil
  paused = nil
end

--> DEBUG
----> Initialise
function debug_init()
  recent_ability = nil
  log_ledger = {}
  n_logs = 0
end

----> Draw
function debug_draw()
  local w = love.graphics.getWidth()
  local h = love.graphics.getHeight()
  local f = love.graphics.getFont()
  local lh = f:getHeight()
  
  -- Fade background
  love.graphics.setColor(0,0,0,0.5)
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

  local y = h - 2 * lh
  local n = 10
  local li = n_logs
  local l = 1
  
  while l <= n do
    if li < 1 then
      break
    end
    
    local log = log_ledger[li]
    local logtext = log.logtype .. " - " .. log.datetime .. ": " .. log.message
    
    local ltwidth, wrappedtext = f:getWrap(logtext,w - f:getWidth("\t"))
    local reversed_lines = {}
    for _,line in pairs(wrappedtext) do
      table.insert(reversed_lines,line)
    end
    
    for i,line in pairs(reversed_lines) do
      love.graphics.setColor(1,1,1,1)
      if i == 1 then
        love.graphics.printf(line,0,y,w)
        y = y - lh
        l = l + 1
      else
        love.graphics.printf("\t" .. line,0,y,w)
        y = y - lh
        l = l + 1
      end
    end
    
    li = li - 1
  end
end

----> Log information
function log_info(message)
  table.insert(log_ledger,{
    logtype = "info",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  })
  n_logs = n_logs + 1
end

----> Log warning
function log_warning(message)
  table.insert(log_ledger,{
    logtype = "warn",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  })
  n_logs = n_logs + 1
end

----> Log error
function log_error(message)
  table.insert(log_ledger,{
    logtype = "err",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  })
  n_logs = n_logs + 1
end

----> Capturing debug handler
function debug_keyhandler(key,pressed)
  if pressed then

  end
end

----> Capturing debug mous handler
function debug_mousehandler(x,y,button,pressed)
  
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
  
  local pattern = {}
  for x in bg:gmatch("([^ ]+) ?") do
    table.insert(pattern,x)
  end
  
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
          col = color[col1]
        else
          col = color[col2]
        end
        
        love.graphics.setColor(col)
        love.graphics.rectangle('fill',x,y,tilew,tileh)
      end
    end
  end
end

----> Draw
function world_draw()
  local player_pos = world.players[default_username].pos
  local sc = screen_coords(player_pos.x,player_pos.y)
  local bg = world.deets.background
  
  if bg ~= nil then
    draw_background(bg,sc)
  end
end

----> Update player
function update_player(player)
  local pos = player.pos
  local target = player.target
  
  player.pos = {
    x = pos.x + (target.x - pos.x) / 10,
    y = pos.y + (target.y - pos.y) / 10,
  }
  game_dbg_pos = player.pos
end

----> Update
function world_update()
  if world ~= nil then
    world.tick = world.tick + 1
    world_dbg_tick = world.tick
    
    local players = world.players
    for name,player in pairs(players) do
      update_player(player)
    end
  end
end

----> Load world
function world_load(world_deets)
  log_info("Loading a new world.")
  
  local new_world = {
    tick = 0,
    deets = world_deets,
    players = {},
    mobs = {}
  }
  
  world = new_world
end

----> Join world
function world_join(username)
  log_info(username .. " joined!")
  
  local spawn = world.deets.spawn
  
  world.players[username] = {
    pos = { x = spawn.x, y = spawn.y },
    target = { x = spawn.x, y = spawn.y },
  }
end

----> Set move target
function set_target(username,x,y)
  if world ~= nil and world.players[username] ~= nil then
    world.players[username].target = {
      x = x,
      y = y,
    }
  end
end

----> Convert screen to world
function world_pos(x,y)
  if world == nil or world.players[default_username] == nil then
    return nil
  end
  
  local player_pos = world.players[default_username].pos
  local sc = screen_coords(player_pos.x,player_pos.y)
  
  return {
    x = x + sc.x1,
    y = y + sc.y1,
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
  ability_map = {}
  clicking = false
  last_move_s = love.timer.getTime()
  game_dbg_pos = nil
end

----> Move
function move_char()
  local mx, my = love.mouse.getPosition()  
  local new_pos = world_pos(mx,my)
      
  set_target(default_username,new_pos.x,new_pos.y)
end

----> Update
function game_update()
  local t = love.timer.getTime()
  if world == nil then
    world_load(default_world)
    world_join(default_username)
  end
  
  if clicking and t - last_move_s > move_delay_s then
    move_char()
    last_move_s = t
  end
  
  world_update()
end

----> Draw
function game_draw()
  if world ~= nil and world.players[default_username] ~= nil then
    world_draw()
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
    local ability_name = ability_map[ability_num]
    local ability_index = ability_index_map[ability_name]
    recent_ability = ability_name
  end
end

----> Map keys
function register_key_handlers()
  for k,v in pairs(AbilityKey) do
    game_keyhandlers[k] = ability_handler
  end
  game_keyhandlers["space"] = action_handler
end

----> Map abilities
function map_abilities()
  ability_map[1] = "stun"
  ability_map[2] = "negate"
  ability_map[3] = "reflect"
  ability_map[4] = "root"
  ability_map[5] = "push"
  ability_map[6] = "beam"
  ability_map[7] = "rage"
  ability_map[8] = "pull"
  ability_map[9] = "invis"
  ability_map[10] = "cantrip"
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
  if pressed then
    if button == 1 then
      move_char()
      last_move_s = love.timer.getTime()
      
      clicking = true
    end
  else
    if button == 1 then
      clicking = false
    end
  end
end

--> LOVE
----> Load
function love.load()
  state_init()
  debug_init()
  world_init()
  game_init()
  
  register_key_handlers()
  map_abilities()
  
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
    if debug == Debug.HIDDEN then
      debug = Debug.SHOWN
    else
      debug = Debug.HIDDEN
    end
  end
  
  -- Toggle capturing Debug
  if key == "f4" and pressed and debug ~= Debug.HIDDEN then
    if debug == Debug.SHOWN then
      debug = Debug.CAPTURING
    else
      debug = Debug.SHOWN
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