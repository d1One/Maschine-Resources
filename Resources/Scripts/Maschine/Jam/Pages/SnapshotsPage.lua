------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PageJam"
require "Scripts/Shared/Helpers/LedHelper"
require "Scripts/Shared/Helpers/LedColors"
require "Scripts/Maschine/Helper/LedBlinker"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SnapshotsPage = class( 'SnapshotsPage', PageJam )

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:__init(Controller)

    PageJam.__init(self, "SnapshotsPage", Controller)

    self.GetOSOTypeFn = function() return NI.HW.OSO_SNAPSHOTS end

    self.HandleLockButtonRelease = false

    self.LEDBlinker = LEDBlinker(JamControllerBase.DEFAULT_LED_BLINK_TIME)

    self.SnapshotApplied = false

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:onShow(Show)

    if Show then
        self.Controller.Timer:setTimer(self, 8)
    else
        self:reset()
    end

    PageJam.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:updatePadLEDs()

    local LedStateFunctor = function(Column, Row)

        local Index = Column + ((Row - 1) * 8) - 1
        local IsSnapshot = NI.DATA.ParameterSnapshotsAccess.isSnapshot(App, Index)
        local IsFocusSnapshot = NI.DATA.ParameterSnapshotsAccess.isFocusSnapshot(App, Index)
        local Selected = false
        if IsFocusSnapshot then
            local TimerRunning = self.Controller.Timer:isRunning(self)
            if self:isLockButtonPressed() and not self.SnapshotApplied and not TimerRunning then
                Selected = self.LEDBlinker:getBlinkStateTick() == LEDHelper.LS_BRIGHT
            else
                Selected = true
            end
        end

        return Selected, IsSnapshot

    end

    for Column = 1, 8 do

        LEDHelper.updateLEDsWithFunctor(
            self.Controller.PAD_LEDS[Column], 0,
            function (Row) return LedStateFunctor(Column, Row) end,
            function (_) return LEDColors.WHITE end)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:onPadButton(Column, Row, Pressed)

    if Pressed then

        local Index = Column + ((Row - 1) * 8) - 1 -- 0-based index for snapshots

        if NI.DATA.ParameterSnapshotsAccess.isSnapshot(App, Index) then
            if self:isLockButtonPressed() then
                -- Allow only to interact with focus snapshot
                if NI.DATA.ParameterSnapshotsAccess.isFocusSnapshot(App, Index) then
                    self.SnapshotApplied = true
                    NI.DATA.ParameterSnapshotsAccess.applyParameterSnapshot(App)
                end
                self.HandleLockButtonRelease = true
                self.Controller.CloseOnPageButtonRelease[NI.HW.PAGE_SNAPSHOTS] = false -- avoid Controller handling the release
            elseif self.Controller:isButtonPressed(NI.HW.BUTTON_CLEAR) then
                NI.DATA.ParameterSnapshotsAccess.deleteParameterSnapshot(App, Index)
            else
                -- triggering snapshots is handled on C++ side
                return
            end
        elseif not self.Controller:isButtonPressed(NI.HW.BUTTON_CLEAR) then
            NI.DATA.ParameterSnapshotsAccess.createParameterSnapshot(App, Index)
        end

    end

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:onPageButton(Button, PageID, Pressed)

    if Button == NI.HW.BUTTON_LOCK then

        if Pressed then

            self.Controller.Timer:setTimer(self, 4)

        elseif self.HandleLockButtonRelease then

            self:reset()
            return true

        end

    end

    return false

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:isLockButtonPressed()

    return self.Controller:isButtonPressed(NI.HW.BUTTON_LOCK)

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:reset()

    self.HandleLockButtonRelease = false
    self.Controller.CloseOnPageButtonRelease[NI.HW.PAGE_SNAPSHOTS] = true
    self.SnapshotApplied = false

end


------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:hasDuplicateMode()

    return true

end

------------------------------------------------------------------------------------------------------------------------

function SnapshotsPage:updateDPadLEDs()

    LEDHelper.setLEDState(NI.HW.LED_DPAD_UP, LEDHelper.LS_OFF)
    LEDHelper.setLEDState(NI.HW.LED_DPAD_DOWN, LEDHelper.LS_OFF)

    PageJam.updateDPadLEDs(self)

end


------------------------------------------------------------------------------------------------------------------------
