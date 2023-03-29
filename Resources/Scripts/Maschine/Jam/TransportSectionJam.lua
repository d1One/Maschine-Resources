require "Scripts/Shared/Helpers/ArrangerHelper"
require "Scripts/Shared/Helpers/MaschineHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
TransportSectionJam = class( 'TransportSectionJam' )

------------------------------------------------------------------------------------------------------------------------

function TransportSectionJam:__init(Controller)

    self.Controller = Controller

end

------------------------------------------------------------------------------------------------------------------------

function TransportSectionJam:onTimer()

end

------------------------------------------------------------------------------------------------------------------------

function TransportSectionJam:onPlay(Pressed)

    if Pressed then

        local ShiftPressed = self.Controller:isShiftPressed()

        if ShiftPressed then
            NI.DATA.TransportAccess.restartTransport(App)
       else
            NI.DATA.TransportAccess.togglePlay(App)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSectionJam:onRecord(Pressed)

    local Song = NI.DATA.StateHelper.getFocusSong(App)

    if not Pressed or not Song then
        return
    end

    local SongPressed = self.Controller:isButtonPressed(NI.HW.BUTTON_SONG)
    local ShiftPressed = self.Controller:isShiftPressed()

    if SongPressed then
        ArrangerHelper.enterIdeaSpaceView()
        self.Controller.CanToggleSceneButtonView = false
    else
        if ShiftPressed or not MaschineHelper.isRecording() then
            NI.DATA.TransportAccess.startEventRecording(App, ShiftPressed, false)
        else
            NI.DATA.TransportAccess.stopEventRecording(App)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function TransportSectionJam:onPrevNext(DoNext, Pressed)

    if Pressed and self.Controller:isShiftPressed() then

        if DoNext then
            NI.DATA.TransportAccess.toggleLoop(App)
        else
            MaschineHelper.toggleMetronome()
        end

    end

end

------------------------------------------------------------------------------------------------------------------------
-- update LEDs
------------------------------------------------------------------------------------------------------------------------

function TransportSectionJam:updateLEDs()

    ---- PLAY LED
    LEDHelper.setLEDOnOff(NI.HW.LED_PLAY, MaschineHelper.isPlaying())

    ---- RECORD LED
    LEDHelper.setLEDOnOff(NI.HW.LED_RECORD, MaschineHelper.isRecording())

    if self.Controller:isShiftPressed() then
        ---- ARROW LEFT
        LEDHelper.setLEDOnOff(NI.HW.LED_ARROW_LEFT, self.Controller.SwitchPressed[NI.HW.BUTTON_ARROW_LEFT])
        ---- ARROW RIGHT
        LEDHelper.setLEDOnOff(NI.HW.LED_ARROW_RIGHT, self.Controller.SwitchPressed[NI.HW.BUTTON_ARROW_RIGHT])
    end

end

------------------------------------------------------------------------------------------------------------------------
