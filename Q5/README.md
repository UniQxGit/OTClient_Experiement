﻿# Ice Tornado Effect

### The Task
![](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdTUxNGxyZzlvM25vYXFvcXhxeHB5dHFwM2F6eHgza2dsdmt0azYxeCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/af1YbBoEUG7nmgWZDu/giphy.gif)

### Add new spell data to spells.xml

```lua
	<instant group="attack" spellid="1000" name="My Test" words="testing123" level="60" mana="1" premium="0" selftarget="1" cooldown="5000" groupcooldown="4000" needlearn="0" script="attack/testskill.lua">
		<vocation name="Druid" />
		<vocation name="Elder Druid" />
	</instant>
```

We begin by finding the spells.xml file on the TFS server side lua scripts, and append a new spell entry. In my case, i've duplicated the `eternal_winter` spell since (after playing around with the debug tools a bit) I found that the tornado effect seems to be coming from this spell. The `words` and the `script` are the key components here. The `words` are what speak the spell into existence, and `script` is what will define the behavor of the spell. 

### Create a new testskill.lua script as defined in spells.xml
`testskill.lua`

### Create a new combat type 
```lua
-- Frames (1 = Area, 2 = Player, 3 = Player + Self Damaging)
local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE)

-- Define the combat area matrix (A 3x3 Diamond in our case.)
local arr = {
        {0, 0, 0, 1, 0, 0, 0},
        {0, 0, 1, 1, 1, 0, 0},
        {0, 1, 1, 1, 1, 1, 0},
        {1, 0, 1, 3, 1, 0, 1},
        {0, 1, 1, 1, 1, 1, 0},
        {0, 0, 1, 1, 1, 0, 0},
        {0, 0, 0, 1, 0, 0, 0}
}

-- Assign matrix to the combat area object. 
local area = createCombatArea(arr)
    combat:setArea(area)

-- Assign combat damage values. 
function onGetFormulaValues(player, level, maglevel)
    local min = (level / 5) + (maglevel * 1.6) + 16
    local max = (level / 5) + (maglevel * 3.0) + 28
    return -min, -max
end

combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

```

### Set up the animation loop to instantiate the effects into the scene. 

```lua 
local function animation(pos, playerpos)
    if not Tile(Position(pos)):hasProperty(CONST_PROP_BLOCKPROJECTILE) then
        -- This is only applicable for directional spells
        --if Position(pos):isSightClear(playerpos) then
        Position(pos):sendMagicEffect(CONST_ME_ICETORNADO)
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
    
```

You'll notice this line, in the `animation` function:
    `Position(pos):sendMagicEffect(CONST_ME_ICETORNADO)`
That we are using the enum `CONST_ME_ICETORNADO`, which is an enumerator defined in the tfs server side cpp code within `const.h`.

`const.h`
```cpp
//[...]
	CONST_ME_ICEAREA = 42,
	CONST_ME_ICETORNADO = 43,
	CONST_ME_ICEATTACK = 44,
	CONST_ME_STONES = 45,
//[...]
```
However, despite our previously defined 3x3 diamond matrix 
theres an issue with this `CONST_ME_ICETORNADO` enumerator as we'll see in a moment.
![]( https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZ3V0M2lieGlzeGNpeDU1bG1xZnUzOWp2ZTJxOWR4emlpYmt3cGh4dSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/z4ChUMfwLOgD94pWpo/giphy.gif)

..That doesn't look quite right. 

After serveral cycles of debugging and troubleshooting, I came across something odd:
![](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdzVtNWgxdThyN2RrcG1kbWh3ejQ2NXloNWY2c3I2NzdwcGtyZGprcCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/xDfoi9jv5eStzahDZk/giphy.gif)

I was sure that the matrix was correct, so the area wasn't the issue. As I move my character around the scene, I noticed that moving the character around would impact the pattern visible on the grid. 

Upon futher investigation, and with the help of community member [SpiderOT's awesome sprite editor tool](https://otland.net/threads/assets-editor-2-0.286901/), I was able to open up my Tibia.spr & Tibia.dat files to reveal that the tornado effect is actually a 2x2 grid patterned effect. 

This would mean that it requires at least a 2x1 or 1x2 grid in order for the sprite to render properly on screen.

I began by seeing what would happen if I simply shifted the effect over 1 space: 
```lua
            local modifierx = damagearea[i].Column - centre.Column
            local modifiery = damagearea[i].Row - centre.Row 
            local damagepos = Position(creaturepos)
            damagepos.x = damagepos.x + modifierx + 1 -- Shift in the X by 1 unit. 
            damagepos.y = damagepos.y + modifiery
            addEvent(animation, animationDelay, damagepos, playerpos)
```
![](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbWt3cTRyZWRrdHF6M3ppbmdjMXlvMGgxM2w0NGExdDJ5N3RsNm05eiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/nawKXwWRLTr36j73gI/giphy.gif)

As expected, the effect begins at a certain pattern relative to the player's skill effect area and the player's combat area origin. I became curious of how exactly this behavior was determined and began a search through client side code to try and modify the logic or add a separate parameter or conditional to the logic. However, this was taking me quite some time time was running low. 

I'd realized that the simplest thing to do, is to simply modify the pattern to rotate 90 degrees cw, so I went through the tool and duplicated the original tornado effect to create a new entry at 192.
 
![](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExeWR0ZzVvczA1YjM2MGg5N3duYjVzMmc1dGVncjhrYnhvY2ZrcXB2aCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/oJHlSy7tQr0qbEUbtm/giphy.gif)

We'll update the original `CONST_ME_ICETORNADO` to the new entry with a hardcoded 192. 
```lua
local function animation(pos, playerpos)
    if not Tile(Position(pos)):hasProperty(CONST_PROP_BLOCKPROJECTILE) then
        -- This is only applicable for directional spells
        --if Position(pos):isSightClear(playerpos) then
        Position(pos):sendMagicEffect(192)
        --end
    end
end
```
This seems to have fixed the pattern issue!

### Randomization of the tornado
You might notice We send the effect to the client through `sendMagicEffect`, when we could just as easily have used `combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_ICETORNADO)`
 as done in the `eternal_winter.lua` script we copied. However, this would create the entire effect area matrix at once, but as we see in the video, parts of the tornado are created seemingly at random. Additionally, the smaller tornadoes seemed to blink consistently 3 times, so I gathered that I would need to loop through the sequence three times to duplicate this effect. 

```lua
    for t = 1,3 do --Loop through the effect 3 times.
        for i = 1,#damagearea do
            local animationDelay = ((t-1) * max) + rand[i]; -- Add a cumulative delay based on the number of iterations, t.
            local modifierx = damagearea[i].Column - centre.Column
            local modifiery = damagearea[i].Row - centre.Row 
            local damagepos = Position(creaturepos)
            damagepos.x = damagepos.x + modifierx 
            damagepos.y = damagepos.y + modifiery
            addEvent(animation, animationDelay, damagepos, playerpos)
        end
    end
```

### The Final Result!
![](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExeHN5M2Q0aWloODZyOGVpbzBjOHh6NzYyZWU1NjI2YnM0Njk3aXF5diZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/M4TFIBVVpaV6AXS66h/giphy.gif)
