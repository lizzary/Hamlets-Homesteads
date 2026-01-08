GLOBAL.setfenv(1, GLOBAL)

local seg_time = TUNING.SEG_TIME
local day_time = TUNING.DAY_SEGS_DEFAULT * seg_time
local dusk_time = TUNING.DUSK_SEGS_DEFAULT * seg_time
local night_time = TUNING.NIGHT_SEGS_DEFAULT * seg_time
local total_day_time = TUNING.TOTAL_DAY_TIME

local wilson_attack = TUNING.SPEAR_DAMAGE
local wilson_health = TUNING.WILSON_HEALTH

local tuning = {
    -- 住房系统相关配置
    ROOM_FINDENTITIES_RADIUS = 30, -- NOTE: this value is determined by TUNING.ROOM_LARGE_WIDTH and TUNING.ROOM_LARGE_DEPTH

    PL_MANUAL_LIGHT_OFFSET = {
        -- {[K: prefab]: {height, z_off}}
        DEFAULT = {2, .5},
    },

    -- temp use, read only
    -- TODO: may change to mod config or keep as constant
    -- see interiorspawner.lua
    INTERIOR_DESTRUCTION_BEHAVIOR = {
        DEFAULT = "REMOVE",
        PLAYER = "TELEPORT_TO_EXTERIOR",
        CREATURE = "KILL",
        EPIC_CREATURE = "TELEPORT_TO_EXTERIOR",
        ITEMS = "REMOVE", -- except for irreplaceable
        STRUCTURE = "DESTROY",
    },

    -- temp use
    -- TODO: remove in prod
    DECO_RUINS_BEAM_WORK = 6,

    FENCE_FURNITURE_ROTATION = 180,

    SANITY_HOUSE = 0,
    SANITY_PLAYERHOUSE = 100/(seg_time*32),

    ENTITY_WAKE_DIST = 64,
    ENTITY_SLEEP_DIST = 64 * 1.2,

    SANITY_PLAYERHOUSE_GAIN = 100 / (day_time * 32),
}

-- 科技
TECH.HOME = {
    HOME = 2
}

-- 装饰建造模式
BUILDMODE.HOME_DECOR = 10

-- 锁类型
LOCKTYPE.ROYAL = "royal"

TUNING.DARK_CUTOFF = 0.02

-- 房间尺寸配置，其实只保留小号房间就好，但是考虑到后续还会不会增加不同尺寸的房间？
TUNING.ROOM_TINY_WIDTH   = 15
TUNING.ROOM_TINY_DEPTH   = 10
TUNING.ROOM_SMALL_WIDTH  = 18
TUNING.ROOM_SMALL_DEPTH  = 12
TUNING.ROOM_MEDIUM_WIDTH = 24
TUNING.ROOM_MEDIUM_DEPTH = 16
TUNING.ROOM_LARGE_WIDTH  = 26
TUNING.ROOM_LARGE_DEPTH  = 18

for key, value in pairs(tuning) do
    if TUNING[key] then
        print("OVERRIDE: " .. key .. " in TUNING")
    end

    TUNING[key] = value
end
