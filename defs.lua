local defs = {}

defs.ENTITY_FOLLOW_THRESH = 250
defs.ENTITY_FOLLOW_DIST = 100
defs.ENTITY_JUMP_DIST = 1500
defs.MOVE_SPEED = 800
defs.TargetType = {
    PLAYER = "player",
    ENTITY = "entity"
}
defs.AbilityClass = {
    DEFENCE = "defence",
    OFFENSE = "offense",
    SHORT = "short",
    BURST = "burst",
    OPTIMISE = "optimise"
}
defs.PLAYER_HP = 1000
defs.PLAYER_L = 75
defs.TPS = 24
defs.TIMESTEP = 1 / defs.TPS
defs.CHARGE_TO_UNLOCK = 8
defs.MAX_UNLOCKED = 3

return defs