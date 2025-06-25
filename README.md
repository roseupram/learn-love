style: element class id > merge to a table 
so element do not need style, just need class
No, still need style, for animation, rotation 
# learn-love
## TODO
1. card show select play
2. color: RGB and RGBA
2. practice some animation principle, stretch, anticipation

## note
- use `Array:push`, DO NOT use `Array.push`
- `__index`: when the key not found in table, search the key in __index
- to debug in vscode, use `tomblind.local-lua-debugger-vscode`
- vertex_position: shader only render vertex in [-1,1], -1 is near, 1 is far  
 but normally in models z+ is front, just putting model will make modle back to us, rotating by PI will fix it
- mat in glsl is column-major
- lua 5.1
- lÖve 11.5
> Conditionals (such as the ones in control structures) consider `false` and `nil` as false and `anything else` as true. Beware that, unlike some other scripting languages, Lua considers both zero and the empty string as true in conditional tests.

## ref
- [hexgrid](https://www.redblobgames.com/grids/hexagons/#pixel-to-hex)
- [gjk](https://dyn4j.org/2010/04/gjk-gilbert-johnson-keerthi/)
- [grid](https://ruanyifeng.com/blog/2019/03/grid-layout-tutorial.html)