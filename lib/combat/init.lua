local prototype = require('prototype')
local pen       = require('pen')
local Vec       = require('vec')
local cm        = require('spire.card')
local Hexgrid   = require('hexgon').HexGrid
local FP        = require('FP')

---@class combat
---@operator call:combat
---@field content rectsize
local combat=prototype{name='combat'}
local libs={'coordinate','draw'}
for i,lib in ipairs(libs) do
    table.update(combat,require('combat.'..lib))
end

function combat:new(config)
    self.hexgrid=Hexgrid(Vec(),config.hex_size or 50)
    self.spire=config.spire
    self.style={
        z_index=-1,
        -- display='grid',
        -- row={3,1}
    }
    -- self.children={
    --     {},
    --     cm(self.spire)
    -- }
end

---start a combat with enemy and each qr coordinate
---@param config table {enemy,qrs,player}
function combat:start(config)
    self.enemy=config.enemy
    self.qrs=config.qrs
    self.player=self.spire.player
    self.pos2enemy={}
end

function combat:__tostring()
    return 'combat'
end
return combat