require "Scripts/Maschine/MaschineStudio/Pages/SamplingPageStudio"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SamplingPageMK3 = class( 'SamplingPageMK3', SamplingPageStudio )

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMK3:__init(Controller)

    SamplingPageStudio.__init(self, Controller)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMK3:updatePageLEDs()

	local Bright = NHLController:getPageStack():getTopPage() == NI.HW.PAGE_SAMPLING

    local Color = SamplingHelper.isRecorderWaitingOrRecording() and LEDColors.RED or LEDColors.WHITE
    LEDHelper.setLEDState(NI.HW.LED_SAMPLE, Bright and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM_FLASH, Color)

end

------------------------------------------------------------------------------------------------------------------------

function SamplingPageMK3:getAccessiblePageInfo()

    return "Sampling"

end

------------------------------------------------------------------------------------------------------------------------
