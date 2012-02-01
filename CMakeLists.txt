FIND_PACKAGE(Torch REQUIRED)

SET(src)
SET(luasrc init.lua OptionParser.lua Profiler.lua)

ADD_TORCH_PACKAGE(xlua "${src}" "${luasrc}" "System")

