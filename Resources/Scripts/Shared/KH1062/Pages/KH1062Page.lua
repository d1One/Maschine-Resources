require "Scripts/Shared/KH1062/SwitchEventTable"
require "Scripts/Shared/Helpers/MiscHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
KH1062Page = class( 'KH1062Page' )

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:__init(Screen, SwitchHandler)

    if Screen == nil or Screen.ScreenStack == nil or Screen.PageName == nil then
        error ("A Screen must be provided, with ScreenStack and PageName properties")
    end

    self.Screen = Screen
    self.ScreenStack = Screen.ScreenStack
    self.Name = Screen.PageName
    self:setupScreen()

    self.SwitchEventTable = SwitchEventTable()

    self.isShiftPressed = function()
        return SwitchHandler:isShiftPressed()
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:setupScreen()
end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:onShow(Show)

    if Show == true then
        self.ScreenStack:setTop(self:getRootBar())
        self:updateScreen(true)
    end

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:isShowing()

    return NI.GUI.getStackTop(self.ScreenStack):getId() == self.Name

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:updateScreen(ForceUpdate)
end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:updateLEDs()
end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:getRootBar()

    return self.Screen.RootBar

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:onDB3ModelChanged(ModelType)
end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:onStateFlagsChanged()
end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:onWheel(Delta)
end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:getSwitchEventTable()

    return self.SwitchEventTable

end

------------------------------------------------------------------------------------------------------------------------

function KH1062Page:disableSwitchHandling()

    self.SwitchEventTable = nil

end

-----------------------------------------------------------------------------------------------------------------------

function KH1062Page:isSwitchHandlingEnabled()

    return self.SwitchEventTable ~= nil

end

-----------------------------------------------------------------------------------------------------------------------

function KH1062Page.defaultMissingCallbacks(Callbacks, ExpectedFunctionNames)

    local PatchedCallbacks = {}

    for _, ExpectedFunctionName in pairs(ExpectedFunctionNames) do
        PatchedCallbacks[ExpectedFunctionName] = Callbacks and Callbacks[ExpectedFunctionName] or function () end
    end

    return PatchedCallbacks

end
