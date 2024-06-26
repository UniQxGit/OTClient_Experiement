### The Task

![](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExY294dmhnNW5hZmI5ZGtvMWxweTZ3OTh2bnBuNHViZDJjMTkxdjloMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/rbxqOzjW1lIyFfOVs1/giphy.gif) 

### Create New Module Folder Structure

![](https://i.imgur.com/n6JxEOl.png)

### Set up otmod file
```
Module
  name: game_minigameWindow
  description: View available spells
  author: Lee, John
  website: https://github.com/edubart/otclient
  sandboxed: true
  scripts: [ minigamewindow ]
  @onLoad: init()
  @onUnload: terminate()
```

Make a note of the `name` value `game_minigameWindow`, we'll need that to set up our callbacks in a moment. We've assigned the script as `minigamewindow.lua` and our `onLoad` function to `init`, and `onUnload` function to terminate. 

We need to set up `modules>game_interface>interface.otmod` to include our `game_minigamewindow`, otherwise, our window will not be initialized to set up properly. 
![](https://i.imgur.com/toWvHn0.png)

### Set up otui file
```css
MainWindow
  id: miniGameWindow
  !text: tr('Mini Game')
  size: 550 400
  @onEscape: toggle()

  TextList
    id: minigame
    anchors.top: parent.top
    anchors.centerIn: parent
    anchors.bottom: next.top
    margin-bottom: 10
    padding: 1
    width: 500
    focusable: false

  Button
    id: buttonCancel
    !text: tr('Close')
    width: 64
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    @onClick: toggle()

  Button
    id: buttonMiniGame
    !text: tr('Jump!')
    width: 64
    anchors.right: minigame.right
    anchors.top: minigame.top
    margin-right: 20
    margin-top: 0
    @onClick: resetButton()
```

We have 4 elements here: 

our `MainWindow`, which houses all of our other UI Elements. 

`MiniWinContainer` which is our inner ui for our button minigame. We've set the id field to `minigame` to be referenced later, the anchor `anchors.centerIn: parent` to center our UI element, and set the width to 500. 

`Button` for our cancel button that will close our minigame. We've set the `onClick` callback to the `toggle` function that we will define later in our `lua` script. 

`Button` for our "Jump" minigame. We've set the `!text` value to "Jump" tomatch our target goal. We set the `anchors.right` to the `minigame` window's `right` anchor, so that at a value of 0, it will stick to the right side of the screen, and set the `onClick` to `resetButton` which we will use to reset our right margin to 0, and randomize our y position within the `minigame` window.  

### Set up Initialization Lua Scripts
```lua
miniGameWindow       = nil

miniGameButton        = nil
minigame              = nil

isCounting            = false
buttonX               = 0
maxX                  = 0

function init()
    miniGameWindow = g_ui.displayUI('minigamewindow', modules.game_interface.getRightPanel())
    miniGameWindow:hide()

    miniGameButton        = miniGameWindow:getChildById('buttonMiniGame')
    minigame             = miniGameWindow:getChildById('minigame')
end


```

### Hide window if user logs out. 

We need to make sure that when the user logs out, that we close out our UI. Otherwise, our window will remain on screen and overlap with the login screens. To do this, we'll use the global callback `offline`, and create a `resetWindow()` function to hide all of our buttons. 

```lua
function offline()
  resetWindow()
end


function resetWindow()
  miniGameWindow:hide()
  miniGameWindow:setOn(false)
  StopCounting()
end
```

### Create a button to show our window
Ok, we've initialized our windows, but we currently still don't have a way to show the window in the first place. Before we continue with our `minigamewindow.lua` script, let's decide how we want to show our window. 

Near the top of the window, there are various toggle buttons, and I think this would be a good place to add in our little minigame. 
![](https://i.imgur.com/z5PX9Bs.png)

I found this icon that looks like a game joystick under `images>optionstab` called `game.png`, that I felt would be a good icon to use as the toggle for our minigame. However, the other icons are 16x16, and ours is 32x32, so we'll need to resize this. 
![](https://i.imgur.com/yiWdPRa.png)

I used mspaint to resize my image down to 16x16 and saved it as a new image under our topbuttons folder `images>topbuttons`. 
![](https://i.imgur.com/sW1rfDx.png)

Notice our new image `minigame.png`
![](https://i.imgur.com/zma5Oms.png)

Now that looks perfect!!
![](https://i.imgur.com/MnRz6cL.png)

### Set up the toggle button

Let's use the `modules.client_topmenu.addRightGameToggleButton()` function to add our toggle to to top menu. 
```lua
miniGameWindow       = nil

function init()
--[...]
  miniGameWindow = modules.client_topmenu.addRightGameToggleButton('miniGameButton', tr('Minigame Window'), '/images/topbuttons/minigame', toggle)
  miniGameWindow:setOn(false)
--[...]
end

function toggle()
  if miniGameWindow:isOn() then
    miniGameWindow:setOn(false)
    miniGameWindow:hide()
  else
    miniGameWindow:setOn(true)
    miniGameWindow:show()
    miniGameWindow:raise()
    miniGameWindow:focus()
  end
end
```

Our First parameter `miniGameButton` will create an identifier to be referenced later. Our second parameter `Minigame Window` will be a tooltip that shows when the user hover's over the button. The thrid parameter `/images/topbuttons/minigame` is the image we want to use for our toggle. And finally, we pass in `toggle` as our callback function to be called each time the button is clicked. 

You'll noticed in our `toggle` function we use `miniGameWindow:isOn()` to check the state of the toggle button, and use that to determine the hide and show states of our other ui elements. 

### The Minigame Code

```lua
isCounting            = false
buttonX               = 0
maxX                  = 0
movementSpeed         = 10
timerDelay            = 100
function init()
--[...]
-- Initialize our Max Value to determine the bounds of the minigame box. 
  maxX = (minigame:getWidth()) - (miniGameButton:getWidth())
--[...]
end

-- Once our Button moves past our max range, we want to reset the position to a random Y position at the right side of the minigame window. 
function resetButton()
  buttonX = 0
  miniGameButton:setMarginRight(buttonX)
  local posY = (minigame:getHeight() - (miniGameButton:getHeight())) * math.random();
  miniGameButton:setMarginTop(posY)
end

--We will increment the button by a value of t to scroll from right to left, and call resetButton() once the button exceeds our bounds. 
function moveButton()
  buttonX = buttonX + movementSpeed
  miniGameButton:setMarginRight(buttonX)

  if buttonX > maxX then
    resetButton()
  end
end

-- We recursively loop the updateTimer event at an update rate of "timerDelay" as long as "isCounting" is true. 
local function updateTimer()
  if isCounting then
      moveButton()
      scheduleEvent(updateTimer, timerDelay)
  end
end

-- Begin the timer. 
function StartCounting()
  print("Started Counting");
  isCounting = true
  updateTimer()
end

-- Stop the timer. 
function StopCounting()
  print("Stopped Counting");
  isCounting = false
end

-- Add Stop and Start to the window visibility toggle event. 
function toggle()
  if spelllistButton:isOn() then
--[...]
    StopCounting()
  else
    StartCounting()
--[...]
  end
end

-- Be sure to stop the timer if the window has been force closed by game logout. 
function resetWindow()
--[...]
  StopCounting()
end

```

There's a lot happening here, but as a gist, we've ccreated a recurseive timer inside `updateTimer` that uses the global `scheduleEvent` function that calls functions on a delay. 

We use an `isCounting` boolean to keep calling the `updateTimer` function as long as `isCounting` is true, and we wrap those inside `StartCounting` and `StopCounting` to be called in the `toggle` function (When the window is shown and hidden), and the `resetWindow` function (When the window is force closed through logout).

The core of our logic is contained within `moveButton`, where we use `miniGameButton:setMarginRight` to manipulate and set the right margin value we defined inside our `otui` file. As this value increases, it will gradually start moving from right to left, until it reaches our max limit, that we defined as `(minigame:getWidth()) - (miniGameButton:getWidth())`, which is our inner frame width, subtracted by our button width. 

In our resetButton() function, we reset our button's x margin to 0 to move our button back to the right side, then randomize the Y position through the formula: `local posY = (minigame:getHeight() - (miniGameButton:getHeight())) * math.random();`. Then we use `miniGameButton:setMarginTop(posY)` to assign the randomized Y margin. 

Finally, we have our final answer to our problem~~!

### The Final Result

![](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbWM2OHdjYjRjeHpoc2NpZzZpZmx2ZzNvamVmNDVjdTY3N251bHF3dCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/ehqXj1KxX8pdW3CrV1/giphy.gif)

