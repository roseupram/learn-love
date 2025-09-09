style: element class id > merge to a table 
so element do not need style, just need class
No, still need style, for animation, rotation 
# learn-love

## How to run
- install [love2d](https://love2d.org/) if you have no love2d
- download [game.love](https://github.com/roseupram/learn-love/releases) and click to run

## note
- offset -> rotation -> scaling 
- use `Array:push`, DO NOT use `Array.push`
- `__index`: when the key not found in table, search the key in __index
- to debug in vscode, use `tomblind.local-lua-debugger-vscode`
- to format glsl shader, use `clang-format`
- vertex_position: love shader only render vertex in [-1,1], -1 is near, 1 is far  
left is x+, up is y+, inward is z+, so that's a **left-hand coordinate**,  
 but in glTF, models are placed in right-hand coordinate, 
- int and float: `1/100=0; 1.0/100=0.01`
- RxRy ~= RyRx, inverse(RxRy)=Ry' Rx', change some view
- mat in glsl is column-major
- LuaJIT(5.1)
- lÖve 11.5
> Conditionals (such as the ones in control structures) consider `false` and `nil` as false and `anything else` as true. Beware that, unlike some other scripting languages, Lua considers both zero and the empty string as true in conditional tests.

## ref
- [love2d](https://love2d.org/)
- [hexgrid](https://www.redblobgames.com/grids/hexagons/#pixel-to-hex): hex coordinate
- [gjk](https://dyn4j.org/2010/04/gjk-gilbert-johnson-keerthi/): polygon point intersection
- [grid](https://ruanyifeng.com/blog/2019/03/grid-layout-tutorial.html): css 
- [glTF](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html): format specification
- [scratchapixel](https://www.scratchapixel.com/): teach computer graphcis