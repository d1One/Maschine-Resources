------------------------------------------------------------------------------------------------------------------------
require "Scripts/Maschine/MaschineStudio/Pages/GridPageStudio"
------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
GridPageMK3 = class( 'GridPageMK3', GridPageStudio )

------------------------------------------------------------------------------------------------------------------------

function GridPageMK3:__init(Controller)

    GridPageBase.__init(self, "GridPageMK3", Controller)

    -- Update page LED in MaschineControllerMK3 to avoid flickering
    self.PageLEDs = {}

    -- setup screen
    self:setupScreen()

end

------------------------------------------------------------------------------------------------------------------------

function GridPageMK3:getAccessiblePageInfo()

    return "Grid"

end

------------------------------------------------------------------------------------------------------------------------

function GridPageMK3:getAccessibleTextByButtonIndex(ButtonIdx)

    if ButtonIdx >= 5 then
        for PadIdx = 1, 16 do
            local _, _, _, IsPadFocused, GridValue = self:getPadButtonState(PadIdx)
            if IsPadFocused then
                return GridValue
            end
        end

        return ""
    end

    return PageMaschine.getAccessibleTextByButtonIndex(self, ButtonIdx)

end

------------------------------------------------------------------------------------------------------------------------

function GridPageMK3:getAccessibleTextByPadIndex(PadIdx)

    local _, _, _, _, GridValue = self:getPadButtonState(PadIdx)
    return GridValue

end

------------------------------------------------------------------------------------------------------------------------
