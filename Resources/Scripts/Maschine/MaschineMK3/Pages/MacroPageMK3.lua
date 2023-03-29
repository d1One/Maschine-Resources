------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMK3/Pages/ControlPageMK3"
require "Scripts/Shared/Helpers/MacroHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MacroPageMK3 = class( 'MacroPageMK3', ControlPageMK3 )

------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "MacroPageStudio", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_MACRO }
    self.IsPinned = true -- always pinned

    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:onScreenEncoder(KnobIdx, EncoderInc)

    -- NOTE: Before Lua scripts receive events, encoder & wheel events are pushed to realtime thread on c++ side,
    -- so no need to call base class to handle these events.
    -- PageMaschine.onScreenEncoder(self, KnobIdx, EncoderInc)

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:onScreenButton(ButtonIdx, Pressed)

    if ButtonIdx >= 1 and ButtonIdx <= 4 then

        return ControlPageMK3.onScreenButton(self, ButtonIdx, Pressed)

    elseif ButtonIdx == 5 then -- PageGroup Left

        if Pressed then
            MacroHelper.leaveMacroPageGroup()
        end

        return

    end

    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:onWheelDirection(Pressed, Button)

    if Pressed and Button == NI.HW.BUTTON_WHEEL_LEFT then
        MacroHelper.leaveMacroPageGroup()
    end

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:onShiftButton(Pressed)

    Page.onShiftButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:onWheel(Inc)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:onWheelButton(Pressed)

    -- avoid parent implementation

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:onPrevNextButton(Pressed, Right)

    -- avoid parent implementation

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageMK3:getAccessiblePageInfo()

    return "Macro"

end

------------------------------------------------------------------------------------------------------------------------
