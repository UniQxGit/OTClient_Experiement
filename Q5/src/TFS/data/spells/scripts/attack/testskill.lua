-- Frames (1 = Area, 2 = Player, 3 = Player + Self Damaging)
local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE)

local arr = {
        {0, 0, 0, 1, 0, 0, 0},
        {0, 0, 1, 1, 1, 0, 0},
        {0, 1, 1, 1, 1, 1, 0},
        {1, 0, 1, 3, 1, 0, 1},
        {0, 1, 1, 1, 1, 1, 0},
        {0, 0, 1, 1, 1, 0, 0},
        {0, 0, 0, 1, 0, 0, 0}
}

local area = createCombatArea(arr)
    combat:setArea(area)

function onGetFormulaValues(player, level, maglevel)
    local min = (level / 5) + (maglevel * 1.6) + 16
    local max = (level / 5) + (maglevel * 3.0) + 28
    return -min, -max
end

combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

local function animation(pos, playerpos)
    if not Tile(Position(pos)):hasProperty(CONST_PROP_BLOCKPROJECTILE) then
        -- This is only applicable for directional spells
        --if Position(pos):isSightClear(playerpos) then
        Position(pos):sendMagicEffect(192)
        --end
    end
end

function onCastSpell(creature, var)

    local animationarea = arr
    local creaturepos = creature:getPosition()
    local playerpos = Position(creaturepos)
    local targeted = false -- is this a targettable spell?
    local delay = 200
 
    if targeted then
        creaturepos = creature:getTarget():getPosition()
    end
 
    local centre = {}
    local damagearea = {}
    local rand = {}
    local max = -1;
    local index = 1;
    for k,v in ipairs(animationarea) do
        for i = 1, #v do
            if v[i] == 3 or v[i] == 2 then
                centre.Row = k
                centre.Column = i
            end
            if v[i] == 1 then
                local darea = {}
                darea.Row = k
                darea.Column = i
                table.insert(damagearea, darea)
                rand[index] = math.random(1,6) * delay;
                if (rand[index] > max) then
                    max = rand[index];
                end
                index = index + 1;
            end
        end
    end

    for t = 1,3 do
        for i = 1,#damagearea do
            local animationDelay = ((t-1) * max) + rand[i];
            if (i == 1) then
                print(animationDelay);
            end
            local modifierx = damagearea[i].Column - centre.Column
            local modifiery = damagearea[i].Row - centre.Row 
            local damagepos = Position(creaturepos)
            damagepos.x = damagepos.x + modifierx 
            damagepos.y = damagepos.y + modifiery
            addEvent(animation, animationDelay, damagepos, playerpos)
        end
    end
    
    return combat:execute(creature, var)
end
    