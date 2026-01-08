local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

local IsTheFrontEnd = rawget(_G, "TheFrontEnd") and rawget(_G, "IsInFrontEnd") and IsInFrontEnd()
if IsTheFrontEnd then
    modimport("main/strings")
end


if IsTheFrontEnd then return end


modimport("main/toolutil") 
modimport("main/tuning")

