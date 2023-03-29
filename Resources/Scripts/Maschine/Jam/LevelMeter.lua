------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Helpers/LedHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LevelMeter = class( 'LevelMeter' )

LevelMeter.LEVELMETER_LEDS =
{
    {NI.HW.LED_METER1_01, NI.HW.LED_METER1_02, NI.HW.LED_METER1_03, NI.HW.LED_METER1_04,
        NI.HW.LED_METER1_05, NI.HW.LED_METER1_06, NI.HW.LED_METER1_07, NI.HW.LED_METER1_08},
    {NI.HW.LED_METER2_01, NI.HW.LED_METER2_02, NI.HW.LED_METER2_03, NI.HW.LED_METER2_04,
        NI.HW.LED_METER2_05, NI.HW.LED_METER2_06, NI.HW.LED_METER2_07, NI.HW.LED_METER2_08}
}

LevelMeter.NUM_LEDS = 8

------------------------------------------------------------------------------------------------------------------------

function LevelMeter:__init()

    self.Source = nil

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeter:onTimer()

    local LevelL, LevelR = 0, 0

    if self.Source then
        LevelL, LevelR = self.Source()
        LevelL = NI.UTILS.LevelScale.convertLevelTodBNormalized(LevelL, -60, 0) * LevelMeter.NUM_LEDS
        LevelR = NI.UTILS.LevelScale.convertLevelTodBNormalized(LevelR, -60, 0) * LevelMeter.NUM_LEDS
    end

    for Index = 1, LevelMeter.NUM_LEDS do
        LEDHelper.setLEDState(self.LEVELMETER_LEDS[1][Index], Index < LevelL and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(self.LEVELMETER_LEDS[2][Index], Index < LevelR and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------
