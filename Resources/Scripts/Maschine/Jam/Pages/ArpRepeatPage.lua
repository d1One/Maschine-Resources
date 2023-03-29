------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Jam/Pages/PadModePageBase"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ArpRepeatPage = class( 'ArpRepeatPage', PadModePageBase )

ArpRepeatPage.MAX_ARP_PRESETS = 8

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:__init(Controller)

    PadModePageBase.__init(self, "ArpRepeatPage", Controller)

     -- LEDs related to this page
    self.PageLEDs = { NI.HW.LED_ARP_REPEAT }

    -- OSO type
    self.GetOSOTypeFn = function() return NI.HW.OSO_ARP_REPEAT end

    self.Is16VelocityModeEnabled = function() return not PadModeHelper.getKeyboardMode() end

    self:resetPageState()

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:onShow(Show)

    if Show then
        self.Duplicate:setEnabled(false)
        self:updatePresetSelectMode()
    else
        self:resetPageState()
    end

    PadModePageBase.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:resetPageState()

    NHLController:setSceneButtonMode(NI.HW.SCENE_BUTTON_MODE_DEFAULT)

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:isPresetSelectMode()

    return PadModeHelper.getKeyboardMode() and self.Controller:isButtonPressed(NI.HW.BUTTON_ARP_REPEAT)

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:updatePresetSelectMode()

    NHLController:setSceneButtonMode(self:isPresetSelectMode()
        and NI.HW.SCENE_BUTTON_MODE_ARP_PRESET_SELECT or NI.HW.SCENE_BUTTON_MODE_DEFAULT)

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:updatePageLEDs(LEDState)

    PageJam.updatePageLEDs(self, LEDState)
    self.Controller:updateArpRepeatLED()

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:updateSceneButtonLEDs()

    if self:isPresetSelectMode() then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        local Color = Sound and Sound:getColorParameter():getValue()
        local PresetParam = NI.DATA.getArpeggiatorPresetParameterJam(App)
        local PresetNum = PresetParam and PresetParam:getValue()

        LEDHelper.updateLEDsWithFunctor(self.Controller.SCENE_LEDS, 0,
        function(Index)
            local Enabled = Index <= ArpRepeatPage.MAX_ARP_PRESETS
            local Selected = Enabled and PresetNum == Index
            return Selected, Enabled
        end,
        function(_) return Color end)
        return
    end

    -- base impl
    PadModePageBase.updateSceneButtonLEDs(self)

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:onSceneButton(Index, Pressed)

    if self:isPresetSelectMode() then

        if Pressed then
            -- set arp preset
            local PresetParam = NI.DATA.getArpeggiatorPresetParameterJam(App)
            if PresetParam then
                NI.DATA.ParameterAccess.setSizeTParameter(App, PresetParam, Index)
                App:getJamParameterOverlay():requestEditMode(false)
                self.Controller.ParameterHandler:showOSO(NI.HW.OSO_ARP_REPEAT)
                App:getTransactionManager():finishTransactionSequence()
            end

            self.Controller.CloseOnPageButtonRelease[NI.HW.PAGE_ARP_REPEAT] = false -- avoid Controller handling the release
        end

        return

    end

    -- base impl
    PadModePageBase.onSceneButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:onPageButton(Button, PageID, Pressed)

    if PageID == NI.HW.PAGE_ARP_REPEAT then
        self:updatePresetSelectMode()
    end

    PadModePageBase.onPageButton(self, Button, PageID, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:onWheelEvent(Inc)

    if App:getJamParameterOverlay():isInEditMode() then
        -- Arp settings are based on hardcoded presets, so when an arp parameter is changed, we leave the preset
        -- by setting the preset parameter to 0, i.e. the "user" preset.
        local PresetParam = NI.DATA.getArpeggiatorPresetParameterJam(App)
        if PresetParam then
            NI.DATA.ParameterAccess.setSizeTParameterNoUndo(App, PresetParam, 0)
        end
    end

end

------------------------------------------------------------------------------------------------------------------------

function ArpRepeatPage:canSectionLoopChange()

    return PageJam.canSectionLoopChange(self) and not self:isPresetSelectMode()

end

------------------------------------------------------------------------------------------------------------------------

