------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/ControlPageStudio"
require "Scripts/Shared/Helpers/MacroHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MacroPageStudio = class( 'MacroPageStudio', ControlPageStudio )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MacroPageStudio:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "MacroPageStudio", Controller)

    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_MACRO }

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function MacroPageStudio:onScreenEncoder(KnobIdx, EncoderInc)

    -- NOTE: Before Lua scripts receive events, encoder & wheel events are pushed to realtime thread on c++ side,
    -- so no need to call base class to handle these events.
    -- PageMaschine.onScreenEncoder(self, KnobIdx, EncoderInc)

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageStudio:onScreenButton(ButtonIdx, Pressed)

    if ButtonIdx >= 1 and ButtonIdx <= 4 then

        return ControlPageStudio.onScreenButton(self, ButtonIdx, Pressed)

    elseif ButtonIdx == 5 then -- PageGroup Left

        if Pressed then
            MacroHelper.leaveMacroPageGroup()
        end

        return

    end

    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageStudio:onShiftButton(Pressed)

    Page.onShiftButton(self, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageStudio:onWheel(Inc)

    return false

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageStudio:onWheelButton(Pressed)

    -- avoid parent implementation

end

------------------------------------------------------------------------------------------------------------------------

function MacroPageStudio:onPrevNextButton(Pressed, Right)

    -- avoid parent implementation

end

------------------------------------------------------------------------------------------------------------------------
