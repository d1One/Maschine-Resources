------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ToggleButton = class( 'ToggleButton' )

------------------------------------------------------------------------------------------------------------------------

function ToggleButton:__init(GetStateFn, SetStateFn, AccessibilityStateFunc)

    self.GetStateFn = GetStateFn
    self.SetStateFn = SetStateFn
    self.AccessibilityStateFunc = AccessibilityStateFunc

end

------------------------------------------------------------------------------------------------------------------------

function ToggleButton:onToggleButton()

    local NewButtonState = not self.GetStateFn()
    self.SetStateFn(NewButtonState)
    if self.AccessibilityStateFunc then
        self.AccessibilityStateFunc(NewButtonState)
    end

end

------------------------------------------------------------------------------------------------------------------------
