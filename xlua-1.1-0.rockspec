package = "xlua"
version = "1.1-0"

source = {
   url = "git://github.com/torch/xlua",
}

description = {
   summary = "Extra Lua functions.",
   detailed = [[
Lua is pretty compact in terms of built-in functionalities:
this package extends the table and string libraries,
and provide other general purpose tools (progress bar, ...).
   ]],
   homepage = "https://github.com/torch/xlua",
   license = "BSD"
}

dependencies = {
   "torch >= 7.0",
   "sys >= 1.0"
}

build = {
   type = "builtin",
   modules = {
      ['xlua.init'] = 'init.lua',
      ['xlua.OptionParser'] = 'OptionParser.lua',
      ['xlua.Profiler'] = 'Profiler.lua'
   }
}
