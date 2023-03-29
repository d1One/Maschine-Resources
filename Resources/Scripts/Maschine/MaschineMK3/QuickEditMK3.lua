------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Maschine/QuickEdit"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
QuickEditMK3 = class( 'QuickEditMK3', QuickEdit )

------------------------------------------------------------------------------------------------------------------------

function QuickEditMK3:__init(Controller)

    QuickEdit.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function QuickEditMK3:getLevelText()

    if self.Level == NI.DATA.LEVEL_TAB_SONG then
        return self:getMode() == NI.HW.JOGWHEEL_MODE_TEMPO and "" or "MASTER"

    elseif self.Level == NI.DATA.LEVEL_TAB_GROUP then
        return "GROUP"

    elseif self.Level == NI.DATA.LEVEL_TAB_SOUND then
        return "SOUND"
    end

    return ""

end

------------------------------------------------------------------------------------------------------------------------
-- Override for Master Swing showing 100.0%; remove the decimal part and show simply 100%

function QuickEditMK3:getValueFormatted()

    if self:getMode() == NI.HW.JOGWHEEL_MODE_SWING and self.Level == NI.DATA.LEVEL_TAB_SONG then
        local Param = self:getFocusParam()
        if Param then
            local SwingValue = Param:getValue()
            if SwingValue < 100 then
                return Param:getAsString(SwingValue)
            else
                return string.format("%.0f %%", SwingValue)
            end
        end
    end

    return QuickEdit.getValueFormatted(self)

end
------------------------------------------------------------------------------------------------------------------------
