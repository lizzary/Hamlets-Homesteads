if not GLOBAL.net_string then
    GLOBAL.net_string = GLOBAL.net_string or function() end
end
local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)


PL_CONFIG = {
}

modimport("main/constants") --常量，有住房的一些常数
modimport("main/util")

modimport("main/assets") --用于注册预制件与资源文件

modimport("main/strings") --文字

modimport("main/standardcomponents") --物理效果啥的

modimport("main/RPC") --通信
modimport("main/actions") --动作
modimport("main/recipes") --配方
modimport("main/containers") --容器，有架子相关的
modimport("main/postinit") --后置化

AddReplicableComponent("interiorvisitor") --室内系统的核心组件
AddReplicableComponent("visualslot") --视觉相关
