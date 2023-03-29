------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PadModePageBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SelectPage = class( 'SelectPage', PadModePageBase )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SelectPage:__init(Controller)

    PadModePageBase.__init(self, "SelectPage", Controller)

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SELECT }

    self.Is16VelocityModeEnabled = function() return true end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPage:hasDuplicateMode()

    -- Do not allow duplication of Sounds when in Step page
    return not NHLController:getPageStack():isPageInStack(NI.HW.PAGE_STEP)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPage:onCustomProcess(ForceUpdate)

    -- Special case for select page on Step page when it's in single-sound mode
    if NHLController:getPageStack():isPageInStack(NI.HW.PAGE_STEP) then
        local StepPage = self.Controller.PageManager:getPage(NI.HW.PAGE_STEP)
        if StepPage and StepPage:isStepPageSingleSound() then
             return StepPage:updateSoundOffset()
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function SelectPage:updatePadLEDs()

    -- Special case for select page on Step page when it's in single-sound mode
    if NHLController:getPageStack():isPageInStack(NI.HW.PAGE_STEP) then
        local StepPage = self.Controller.PageManager:getPage(NI.HW.PAGE_STEP)
        if StepPage and StepPage:isStepPageSingleSound() then
             return StepPage:updatePadLEDs()
        end
    end

    JamHelper.updatePadLEDsSounds(self.Controller)
    PageJam.updatePadLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPage:onPadButton(Column, Row, Pressed)

    local SoundIndex = JamHelper.getSoundIndexByColumRow(Column, Row)

    if Pressed and SoundIndex then

        if self.Duplicate:isEnabled() then
            self.Duplicate:onSoundDuplicate(SoundIndex)
        else
            JamHelper.focusSoundByIndex(SoundIndex, self.Controller)

            if self.Controller:isClearActive() then
                MaschineHelper.removeSound(SoundIndex)
            end
        end

    end

    PageJam.onPadButton(self, Column, Row, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SelectPage:onGroupCreate(GroupIndex, Pressed, Song)

    -- do not create new Groups when on Select Page

end

------------------------------------------------------------------------------------------------------------------------

function SelectPage:updateGroupLEDs()

     PadModePageBase.updateGroupLEDs(self, false)

end

------------------------------------------------------------------------------------------------------------------------
