local defs = require("defs")

local utils = {}

function utils.get_pixel_range(range)
    return range * defs.MOVE_SPEED
  end

return utils