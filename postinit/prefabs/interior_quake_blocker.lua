
AddPrefabPostInit("interiorworkblank", function(inst)
    inst:AddTag("quake_blocker")
end) 

--写下这个补丁，给房间增加一个禁止落石的tag,这样地下地震的时候室内就不会落下石头了