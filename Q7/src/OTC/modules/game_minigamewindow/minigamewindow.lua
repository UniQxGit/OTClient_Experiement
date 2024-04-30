
minigamewindow       = nil
minigameToggleButton = nil

miniGameButton        = nil
minigame              = nil

isCounting            = false
buttonX               = 0
maxX                  = 0
movementSpeed         = 10
timerDelay            = 100

function offline()
  resetWindow()
end

function init()
  connect(g_game, { onGameStart = online,
                    onGameEnd   = offline })

  minigamewindow = g_ui.displayUI('minigamewindow', modules.game_interface.getRightPanel())
  minigamewindow:hide()

  minigameToggleButton = modules.client_topmenu.addRightGameToggleButton('miniGameButton', tr('Minigame Window'), '/images/topbuttons/minigame', toggle)
  minigameToggleButton:setOn(false)

  miniGameButton        = minigamewindow:getChildById('buttonMiniGame')
  minigame             = minigamewindow:getChildById('minigame')

  maxX = (minigame:getWidth()) - (miniGameButton:getWidth())

end

function resetButton()
  buttonX = 0
  miniGameButton:setMarginRight(buttonX)
  local posY = (minigame:getHeight() - (miniGameButton:getHeight())) * math.random();
  miniGameButton:setMarginTop(posY)
end

function moveButton()
  buttonX = buttonX + movementSpeed
  miniGameButton:setMarginRight(buttonX)

  if buttonX > maxX then
    resetButton()
  end
end

local function updateTimer()
  if isCounting then
      moveButton()
      scheduleEvent(updateTimer, timerDelay)
  end
end

function StartCounting()
  print("Started Counting");
  isCounting = true
  updateTimer()
end

function StopCounting()
  print("Stopped Counting");
  isCounting = false
end

function terminate()
  minigamewindow:destroy()
  minigameToggleButton:destroy()
  StopCounting()
end

function toggle()
  if minigameToggleButton:isOn() then
    minigameToggleButton:setOn(false)
    minigamewindow:hide()
    StopCounting()
  else
    StartCounting()
    minigameToggleButton:setOn(true)
    minigamewindow:show()
    minigamewindow:raise()
    minigamewindow:focus()
  end
end

function resetWindow()
  minigamewindow:hide()
  minigameToggleButton:setOn(false)
  StopCounting()
end