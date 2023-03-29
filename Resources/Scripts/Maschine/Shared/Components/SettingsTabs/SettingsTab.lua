------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SettingsTab = class( 'SettingsTab' )

SettingsTab.NO_PARAMETER_BAR = 0
SettingsTab.WITH_PARAMETER_BAR = 1

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:__init(Category, Name, RightScreenParameterBar)

    self.Category = Category
    self.Name = Name
    self.RightScreenParameterBar = RightScreenParameterBar

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:getCategory()

    return self.Category

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:getName()

    return self.Name

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:addContextualBar(ContextualStack)

    self.ContextualLabel = NI.GUI.insertLabel(ContextualStack, "ContextualLabel")
    self.ContextualLabel:style("", "")

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:onShow(Show, ShiftPressed)
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:onControllerTimer()
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:updateScreens(ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:updateParameters(Controller, ParameterHandler)

    ParameterHandler.NumPages = 0
    ParameterHandler:setCustomSections({})
    ParameterHandler:setParameters({}, false)
    Controller.CapacitiveList:assignParametersToCaps({})

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:updateScreenButton(Index, ScreenButton)

    local IsVisible = false
    local IsEnabled = false
    local IsSelected = false
    local IsFocused = false
    local ButtonText = ""
    local Style = "HeadButton"

    ScreenHelper.updateButton(ScreenButton, IsVisible, IsEnabled, IsSelected, IsFocused, ButtonText, Style)

end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:onCapTouched(Cap, Touched, Controller, ParameterHandler)
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:onScreenEncoder(Index, Value, Controller, ParameterHandler)
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:onScreenButton(Index, Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:onWheel(Inc)
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:onWheelButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------

function SettingsTab:onShiftButton(Pressed)
end

------------------------------------------------------------------------------------------------------------------------
