local logging = {}

logging.log_ledger = nil
logging.n_logs = nil

local log_file = nil

function logging.init()
    logging.log_ledger = {}
    logging.n_logs = 0
    love.filesystem.createDirectory("logs")
    local log_filename = "logs/" .. os.date("%Y%m%d%H%M%S") .. ".txt"
    log_file = love.filesystem.newFile(log_filename)
    log_file:open("w")
end

----> Log to text
function logging.log_text(log)
  return log.logtype .. " - " .. log.datetime .. ": " .. log.message
end

----> Log information
function logging.log_info(message)
  if message == nil then
    message = "????"
  end
  local new_log = {
    logtype = "info",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  }
  
  table.insert(logging.log_ledger,new_log)
  logging.n_logs = logging.n_logs + 1
  log_file:write(logging.log_text(new_log) .. "\r\n")
  log_file:flush()
end

----> Log warning
function logging.log_warning(message)
  if message == nil then
    message = "????"
  end
  local new_log = {
    logtype = "warn",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  }
  
  table.insert(logging.log_ledger,new_log)
  logging.n_logs = logging.n_logs + 1
  log_file:write(logging.log_text(new_log) .. "\r\n")
  log_file:flush()
end

----> Log error
function logging.log_error(message)
  if message == nil then
    message = "????"
  end
  local new_log = {
    logtype = "err",
    datetime = os.date("%Y-%m-%d %H:%M:%S"),
    message = message
  }
  
  table.insert(logging.log_ledger,new_log)
  logging.n_logs = logging.n_logs + 1
  log_file:write(logging.log_text(new_log) .. "\r\n")
  log_file:flush()
end

return logging