package = "xlua"
version = "1.0-0"

source = {
   url = "git://github.com/clementfarabet/lua---sys"
}

description = {
   summary = "Extra Lua functions.",
   detailed = [[
Lua is pretty compact in terms of built-in functionalities:
this package extends the table and string libraries, 
and provide other general purpose tools (progress bar, ...).
   ]],
   homepage = "https://github.com/clementfarabet/lua---xlua",
   license = "BSD"
}

dependencies = {
   "torch >= 7.0",
}

build = {
   type = "cmake",
   variables = {
      LUAROCKS_PREFIX = "$(PREFIX)"
   }
}
