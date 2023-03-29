------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PadModePageBase"
require "Scripts/Maschine/Jam/Helper/JamHelper"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModePage = class( 'PadModePage', PadModePageBase )

------------------------------------------------------------------------------------------------------------------------

function PadModePage:__init(Controller)

    PadModePageBase.__init(self, "PadModePage", Controller)

     -- LEDs related to this page
    self.PageLEDs = { NI.HW.LED_PAD_MODE }

    -- OSO type
    self.GetOSOTypeFn = function() return PadModeHelper.getKeyboardMode() and NI.HW.OSO_SCALE or NI.HW.OSO_NONE end

    self.Is16VelocityModeEnabled = function() return not PadModeHelper.getKeyboardMode() end

end

------------------------------------------------------------------------------------------------------------------------

function PadModePage:hasDuplicateMode()

    return true

end

------------------------------------------------------------------------------------------------------------------------

