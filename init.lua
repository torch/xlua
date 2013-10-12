----------------------------------------------------------------------
--
-- Copyright (c) 2011 Clement Farabet
--           (c) 2008 David Manura (for the OptionParser)
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
----------------------------------------------------------------------
-- description:
--     xlua - a package that provides a better Lua prompt, and a few
--            methods to deal with the namespace, argument unpacking
--            and so on...
--
-- history: 
--     July  7, 2011, 12:49AM - added OptionParser from D. Manura
--     June 30, 2011, 4:54PM - creation - Clement Farabet
----------------------------------------------------------------------

require 'os'
require 'sys'
require 'io'
require 'math'
require 'torch'

-- remember startup variables (to protect them)
_G._protect_ = {'_protect_','xlua'}
for k,v in pairs(_G) do
   table.insert(_G._protect_, k)
end

local glob = _G
local torch = torch
local pairs = pairs
local ipairs = ipairs
local table = table
local string = string
local pcall = pcall
local loadstring = loadstring
local _protect_ = _protect_

module 'xlua'

-- extra files
glob.require 'xlua.OptionParser'
glob.require 'xlua.Profiler'

----------------------------------------------------------------------
-- better print function
----------------------------------------------------------------------
print = function(obj,...)
          if glob.type(obj) == 'table' then
              local mt = glob.getmetatable(obj)
              if mt and mt.__tostring__ then
                 glob.io.write(mt.__tostring__(obj))
              else
                 local tos = glob.tostring(obj)
                 local obj_w_usage = false
                 if tos and not glob.string.find(tos,'table: ') then
                    if obj.usage and glob.type(obj.usage) == 'string' then
                       glob.io.write(obj.usage)
                       glob.io.write('\n\nFIELDS:\n')
                       obj_w_usage = true
                    else
                       glob.io.write(tos .. ':\n')
                    end
                 end
                 glob.io.write('{')
                 local tab = ''
                 local idx = 1
                 for k,v in pairs(obj) do
                    if idx > 1 then glob.io.write(',\n') end
                    if glob.type(v) == 'userdata' then
                       glob.io.write(tab .. '[' .. k .. ']' .. ' = <userdata>')
                    else
                       local tostr = glob.tostring(v):gsub('\n','\\n')
                       if #tostr>40 then
                          local tostrshort = tostr:sub(1,40) .. glob.sys.COLORS.none
                          glob.io.write(tab .. '[' .. glob.tostring(k) .. ']' .. ' = ' .. tostrshort .. ' ... ')
                       else
                          glob.io.write(tab .. '[' .. glob.tostring(k) .. ']' .. ' = ' .. tostr)
                       end
                    end
                    tab = ' '
                    idx = idx + 1
                 end
                 glob.io.write('}')
                 if obj_w_usage then
                    glob.io.write('')                    
                 end
              end
           else 
              glob.io.write(glob.tostring(obj))
           end
           if glob.select('#',...) > 0 then
              glob.io.write('    ')
              print(...)
           else
              glob.io.write('\n')
           end
        end
glob.xprint = print

----------------------------------------------------------------------
-- log all session, by replicating stdout to a file
----------------------------------------------------------------------
log = function(file)
         glob.os.execute('mkdir -p "' .. glob.sys.dirname(file) .. '"')
         local f = glob.assert(glob.io.open(file,'w'))
         glob.io._write = glob.io.write
         glob._print = glob.print
         glob.print = glob.xprint
         glob.io.write = function(...)
                            glob.io._write(...)
                            local arg = {...}
                            for i = 1,glob.select('#',...) do
                               f:write(arg[i])
                            end
                            f:flush()
                         end
      end

----------------------------------------------------------------------
-- clear all globals
----------------------------------------------------------------------
clearall = function()
   for k,v in pairs(glob) do
      local protected = false
      local lib = false
      for i,p in ipairs(_protect_) do
	 if k == p then protected = true end
      end
      for p in pairs(glob.package.loaded) do
	 if k == p then lib = true end
      end
      if not protected then
	 glob[k] = nil
         if lib then glob.package.loaded[k] = nil end
      end
   end
   glob.collectgarbage()
end

----------------------------------------------------------------------
-- clear one variable
----------------------------------------------------------------------
clear = function(var)
   glob[var] = nil
   glob.collectgarbage()
end

----------------------------------------------------------------------
-- prints globals
----------------------------------------------------------------------
who = function()
   local user = {}
   local libs = {}
   for k,v in pairs(glob) do
      local protected = false
      local lib = false
      for i,p in ipairs(_protect_) do
	 if k == p then protected = true end
      end
      for p in pairs(glob.package.loaded) do
	 if k == p and p ~= '_G' then lib = true end
      end
      if lib then
         glob.table.insert(libs, k)
      elseif not protected then
	 user[k] =  glob[k]
      end
   end
   print('')
   print('Global Libs:')
   print(libs)
   print('')
   print('Global Vars:')
   print(user)
   print('')
end

----------------------------------------------------------------------
-- time
----------------------------------------------------------------------
function formatTime(seconds)
   -- decompose:
   local floor = glob.math.floor
   local days = floor(seconds / 3600/24)
   seconds = seconds - days*3600*24
   local hours = floor(seconds / 3600)
   seconds = seconds - hours*3600
   local minutes = floor(seconds / 60)
   seconds = seconds - minutes*60
   local secondsf = floor(seconds)
   seconds = seconds - secondsf
   local millis = floor(seconds*1000)

   -- string
   local f = ''
   local i = 1
   if days > 0 then f = f .. days .. 'D' i=i+1 end
   if hours > 0 and i <= 2 then f = f .. hours .. 'h' i=i+1 end
   if minutes > 0 and i <= 2 then f = f .. minutes .. 'm' i=i+1 end
   if secondsf > 0 and i <= 2 then f = f .. secondsf .. 's' i=i+1 end
   if millis > 0 and i <= 2 then f = f .. millis .. 'ms' i=i+1 end
   if f == '' then f = '0ms' end

   -- return formatted time
   return f
end

----------------------------------------------------------------------
-- progress bar
----------------------------------------------------------------------
do
   local barDone = true
   local previous = -1
   local timer
   local times
   local indices
   function progress(current, goal)
      -- defaults:
      local barLength = 77
      local smoothing = 100 
      local maxfps = 10
      
      -- Compute percentage
      local percent = glob.math.floor(((current) * barLength) / goal)

      -- start new bar
      if (barDone and ((previous == -1) or (percent < previous))) then
         barDone = false
         previous = -1
         timer = torch.Timer()
         times = {timer:time().real}
         indices = {current}
      else
         glob.io.write('\r')
      end

      --if (percent ~= previous and not barDone) then
      if (not barDone) then
         previous = percent
         -- print bar
         glob.io.write(' [')
         for i=1,barLength do
            if (i < percent) then glob.io.write('=')
            elseif (i == percent) then glob.io.write('>')
            else glob.io.write('.') end
         end
         glob.io.write('] ')
         -- time stats
         for i=1,50 do glob.io.write(' ') end
         for i=1,50 do glob.io.write('\b') end
         local elapsed = timer:time().real
         local step = (elapsed-times[1]) / (current-indices[1])
         if current==indices[1] then step = 0 end
         local remaining = glob.math.max(0,(goal - current)*step)
         table.insert(indices, current)
         table.insert(times, elapsed)
         if #indices > smoothing then
            indices = table.splice(indices)
            times = table.splice(times)
         end
         local tm = 'ETA: ' .. formatTime(remaining) .. ' | Step: ' .. formatTime(step)
         glob.io.write(tm)
         -- go back to center of bar, and print progress
         for i=1,47+#tm do glob.io.write('\b') end
         glob.io.write(' ', current, '/', goal, ' ')
         -- reset for next bar
         if (percent == barLength) then
            barDone = true
            glob.io.write('\n')
         end
         -- flush
         glob.io.write('\r')
         glob.io.flush()
      end
   end
end

--------------------------------------------------------------------------------
-- prints an error with nice formatting. If domain is provided, it is used as
-- following: <domain> msg
--------------------------------------------------------------------------------
function error(message, domain, usage) 
   local c = glob.sys.COLORS
   if domain then
      message = '<' .. domain .. '> ' .. message
   end
   local col_msg = c.Red .. glob.tostring(message) .. c.none
   if usage then
      col_msg = col_msg .. '\n' .. usage
   end
   glob.error(col_msg)
end
glob.xerror = error

--------------------------------------------------------------------------------
-- provides standard try/catch functions
--------------------------------------------------------------------------------
function trycatch(try,catch)
   local ok,err = glob.pcall(func)
   if not ok then catch(err) end
end

--------------------------------------------------------------------------------
-- returns true if package is installed, rather than crashing stupidly :-)
--------------------------------------------------------------------------------
function installed(package) 
   local found = false
   local p = glob.package.path .. ';' .. glob.package.cpath
   for path in p:gfind('.-;') do
      path = path:gsub(';',''):gsub('?',package)
      if glob.sys.filep(path) then 
         found = true
         p = path
         break
      end
   end
   return found,p
end

--------------------------------------------------------------------------------
-- try to load a package, and doesn't crash if not found !
-- optionally try to install it from luarocks, and then load it.
--
-- @param package      package to load
-- @param luarocks     if true, then try to install missing package with luarocks
-- @param server       specify a luarocks server
--------------------------------------------------------------------------------
function require(package,luarocks,server) 
   local loaded
   local load = function() loaded = glob.require(package) end
   local ok,err = glob.pcall(load)
   if not ok then
      print(err)
      print('warning: <' .. package .. '> could not be loaded (is it installed?)')
      return false
   end
   return loaded
end
glob.xrequire = require

--------------------------------------------------------------------------------
-- standard usage function: used to display automated help for functions
--
-- @param funcname     function name
-- @param description  description of the function
-- @param example      usage example
-- @param ...          [optional] arguments
--------------------------------------------------------------------------------
function usage(funcname, description, example, ...)
   local c = glob.sys.COLORS

   local style = {
      banner = '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++',
      list = c.blue .. '> ' .. c.none,
      title = c.Magenta,
      pre = c.cyan,
      em = c.Black,
      img = c.red,
      link = c.red,
      code = c.green,
      none = c.none
   }

   local str = style.banner .. '\n'

   str = str .. style.title .. funcname .. style.none .. '\n'
   if description then
      str = str .. '\n' .. description .. '\n'
   end

   str = str .. '\n' .. style.list .. 'usage:\n' .. style.pre

   -- named arguments:
   local args = {...}
   if args[1].tabled then
      args = args[1].tabled 
   end
   if args[1].arg then
      str = str .. funcname .. '{\n'
      for i,param in ipairs(args) do
         local key
         if param.req then
            key = '    ' .. param.arg .. ' = ' .. param.type
         else
            key = '    [' .. param.arg .. ' = ' .. param.type .. ']'
         end
         -- align:
         while key:len() < 40 do
            key = key .. ' '
         end
         str = str .. key .. '-- ' .. param.help 
         if param.default or param.default == false then
            str = str .. '  [default = ' .. glob.tostring(param.default) .. ']'
         elseif param.defaulta then
            str = str .. '  [default == ' .. param.defaulta .. ']'
         end
         str = str.. '\n'
      end
      str = str .. '}\n'

   -- unnamed args:
   else
      local idx = 1
      while true do
         local param
         str = str .. funcname .. '(\n'
         while true do
            param = args[idx]
            idx = idx + 1
            if not param or param == '' then break end
            local key
            if param.req then
               key = '    ' .. param.type
            else
               key = '    [' .. param.type .. ']'
            end
            -- align:
            while key:len() < 40 do
               key = key .. ' '
            end
            str = str .. key .. '-- ' .. param.help .. '\n'
         end
         str = str .. ')\n'
         if not param then break end
      end
   end
   str = str .. style.none

   if example then
      str = str .. '\n' .. style.pre .. example .. style.none .. '\n'
   end

   str = str .. style.banner
   return str
end

--------------------------------------------------------------------------------
-- standard argument function: used to handle named arguments, and 
-- display automated help for functions
--------------------------------------------------------------------------------
function unpack(args, funcname, description, ...)
   -- put args in table
   local defs = {...}

   -- generate usage string as a closure:
   -- this way the function only gets called when an error occurs
   local fusage = function() 
                     local example
                     if #defs > 1 then
                        example = funcname .. '{' .. defs[2].arg .. '=' .. defs[2].type .. ', '
                           .. defs[1].arg .. '=' .. defs[1].type .. '}\n'
                        example = example .. funcname .. '(' .. defs[1].type .. ',' .. ' ...)'
                     end
                     return usage(funcname, description, example, {tabled=defs})
                  end
   local usage = {}
   glob.setmetatable(usage, {__tostring=fusage})

   -- get args
   local iargs = {}
   if #args == 0 then
      print(usage)
      error('error')
   elseif #args == 1 and glob.type(args[1]) == 'table' and #args[1] == 0 
                     and not (glob.torch and glob.torch.typename(args[1]) ~= nil) then
      -- named args
      iargs = args[1]
   else
      -- ordered args
      for i = 1,glob.select('#',...) do
         iargs[defs[i].arg] = args[i]
      end
   end

   -- check/set arguments
   local dargs = {}
   for i = 1,#defs do
      local def = defs[i]
      -- is value requested ?
      if def.req and iargs[def.arg] == nil then
         local c = glob.sys.COLORS
         print(c.Red .. 'missing argument: ' .. def.arg .. c.none)
         print(usage)
         error('error')
      end
      -- get value or default
      dargs[def.arg] = iargs[def.arg]
      if dargs[def.arg] == nil then
         dargs[def.arg] = def.default
      end
      if dargs[def.arg] == nil and def.defaulta then
         dargs[def.arg] = dargs[def.defaulta]
      end
      dargs[i] = dargs[def.arg]
   end

   -- return usage too
   dargs.usage = usage

   -- stupid lua bug: we return all args by hand
   if dargs[65] then
      error('<xlua.unpack> oups, cant deal with more than 64 arguments :-)')
   end

   -- return modified args
   return dargs,
   dargs[1], dargs[2], dargs[3], dargs[4], dargs[5], dargs[6], dargs[7], dargs[8], 
   dargs[9], dargs[10], dargs[11], dargs[12], dargs[13], dargs[14], dargs[15], dargs[16],
   dargs[17], dargs[18], dargs[19], dargs[20], dargs[21], dargs[22], dargs[23], dargs[24],
   dargs[25], dargs[26], dargs[27], dargs[28], dargs[29], dargs[30], dargs[31], dargs[32],
   dargs[33], dargs[34], dargs[35], dargs[36], dargs[37], dargs[38], dargs[39], dargs[40],
   dargs[41], dargs[42], dargs[43], dargs[44], dargs[45], dargs[46], dargs[47], dargs[48],
   dargs[49], dargs[50], dargs[51], dargs[52], dargs[53], dargs[54], dargs[55], dargs[56],
   dargs[57], dargs[58], dargs[59], dargs[60], dargs[61], dargs[62], dargs[63], dargs[64]
end

--------------------------------------------------------------------------------
-- standard argument function for classes: used to handle named arguments, and 
-- display automated help for functions
-- auto inits the self with usage
--------------------------------------------------------------------------------
function unpack_class(object, args, funcname, description, ...)
   local dargs = unpack(args, funcname, description, ...)
   for k,v in pairs(dargs) do
      if glob.type(k) ~= 'number' then
         object[k] = v
      end
   end
end

--------------------------------------------------------------------------------
-- module help function
--
-- @param module       module
-- @param name         module name
-- @param description  description of the module
--------------------------------------------------------------------------------
function usage_module(module, name, description)
   local c = glob.sys.COLORS
   local hasglobals = false
   local str = c.magenta
   local str = str .. '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
   str = str .. 'PACKAGE:\n' .. name .. '\n'
   if description then
      str = str .. '\nDESC:\n' .. description .. '\n'
   end
   str = str .. '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
   str = str .. c.none
   -- register help
   local mt = glob.getmetatable(module) or {}
   glob.setmetatable(module,mt)
   mt.__tostring = function() return str end
   return str
end

--------------------------------------------------------------------------------
-- splicing: remove elements from a table
--------------------------------------------------------------------------------
function table.splice(tbl, start, length)
   length = length or 1
   start = start or 1
   local endd = start + length
   local spliced = {}
   local remainder = {}
   for i,elt in ipairs(tbl) do
      if i < start or i >= endd then
         table.insert(spliced, elt)
      else
         table.insert(remainder, elt)
      end
   end
   return spliced, remainder
end

--------------------------------------------------------------------------------
-- prune: remove duplicates from a table
-- if a hash function is provided, it is used to produce a unique hash for each
-- element in the input table.
-- if a merge function is provided, it defines how duplicate entries are merged,
-- otherwise, a random entry is picked.
--------------------------------------------------------------------------------
function table.prune(tbl, hashfunc, merge)
   local hashes = {}
   local hash = hashfunc or function(a) return a end
   if merge then
      for i,v in ipairs(tbl) do
         if not hashes[hash(v)] then 
            hashes[hash(v)] = v
         else
            hashes[hash(v)] = merge(v, hashes[hash(v)])
         end
      end
   else
      for i,v in ipairs(tbl) do
         hashes[hash(v)] = v
      end
   end
   local ntbl = {}
   for _,v in pairs(hashes) do
      table.insert(ntbl, v)
   end
   return ntbl
end

--------------------------------------------------------------------------------
-- split a string using a pattern
--------------------------------------------------------------------------------
function string.split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

--------------------------------------------------------------------------------
-- eval: just a shortcut to parse strings into symbols
-- example: 
-- assert( string.tosymbol('madgraph.Image.File') == madgraph.Image.File )
--------------------------------------------------------------------------------
function string.tosymbol(str)
   local ok,result = pcall(loadstring('return ' .. str))
   if not ok then
      glob.error(result)
   elseif not result then
      glob.error('symbol "' .. str .. '" does not exist')
   else
      return result
   end
end
