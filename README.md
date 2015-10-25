# A set of useful extensions to Lua

[![Build Status](https://travis-ci.org/torch/xlua.svg)](https://travis-ci.org/torch/xlua) 

## Dependencies:
Torch7 (www.torch.ch)

## Install:
```
$ torch-rocks install xlua
```

## Use
```
$ torch -lxlua
xLua > a = 5
xLua > b = 'test'
xLua > xlua.who()

Global Libs:
{[1] = string,
 [2] = package,
 [3] = os,
 [4] = io,
 [5] = xlua,
 [6] = sys,
 [7] = math,
 [8] = debug,
 [9] = table,
 [10] = coroutine}

Global Vars:
{[a] = 5,
 [b] = test}

xLua > xlua.clearall()   -- also calls the garbage collector !
xLua > xlua.who()

Global Libs:
{[1] = string,
 [2] = package,
 [3] = os,
 [4] = io,
 [5] = xlua,
 [6] = sys,
 [7] = math,
 [8] = debug,
 [9] = table,
 [10] = coroutine}

Global Vars:
{}

xLua > print(xlua)
{[clear] = function: 0x10020cd10,
 [clearall] = function: 0x10020ca70,
 [_PACKAGE] = ,
 [progress] = function: 0x10020cda0,
 [print] = function: 0x10020c9d0,
 [_NAME] = xlua,
 [who] = function: 0x10020cd50,
 [_M] = table: 0x10020c990,
 [lua_print] = function: 0x100201900}

xLua > test = {a = 14, b = "test"}
xLua > =test
{[a] = 14,
 [b] = test}
xLua > 
```
