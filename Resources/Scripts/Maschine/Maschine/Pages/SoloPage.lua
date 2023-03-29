------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/MuteSoloHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SoloPage = class( 'SoloPage', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SoloPage:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "SoloPage", Controller)

    -- create screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SOLO }

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SoloPage:setupScreen()

    self.Screen = ScreenWithGrid(self)

    -- screen buttons
    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"SOLO", "", "PREV", "NEXT", "ALL ON", "NONE", "", "AUDIO"})
    self.Screen.ScreenButton[1]:style("SOLO", "HeadPin")

    -- Group buttons in left screen
    self.Screen:insertGroupButtons(false)

end


------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function SoloPage:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after Groups updates
    self.Screen:updateGroupBank(self)

    local AudioModeOn = self:getAudioModeOn()
    local BaseGroupIndex = MaschineHelper.getFocusGroupBank(self) * 8

    -- update on-screen Group grid
    ScreenHelper.updateButtonsWithFunctor(self.Screen.GroupButtons,
        function(Index)
            Index = Index + BaseGroupIndex
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Groups = Song and Song:getGroups() or nil

            return MuteSoloHelper.getMuteButtonStateGroups(Groups, Index)
        end
    )

    -- update on-screen pads grid
    ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad,
        function(Index)
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local Sounds = Group and Group:getSounds() or nil

            return MuteSoloHelper.getMuteButtonStateSounds(Sounds, Index, AudioModeOn)
        end
    )

    -- screen button: audio mode button state
    self.Screen.ScreenButton[8]:setSelected(AudioModeOn)

	-- audio mode needs to toggle the all on and none buttons
	self.Screen.ScreenButton[5]:setVisible(not AudioModeOn)
	self.Screen.ScreenButton[6]:setVisible(not AudioModeOn)

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:updateGroupLEDs(UpdateGroupBank)

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
        MaschineHelper.getFocusGroupBank(self) * 8,
        MuteSoloHelper.getGroupMuteByIndexLEDStates,
        MaschineHelper.getGroupColorByIndex,
        MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:updatePadLEDs()

    -- update sound leds with focus state
    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
        function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, self:getAudioModeOn()) end,
        MaschineHelper.getSoundColorByIndex,
        MaschineHelper.getFlashStateSoundsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SoloPage:onShow(Show)

	PageMaschine.onShow(self, Show)

	if Show then
		self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
	end

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:onGroupButton(GroupIndex, Pressed)

    if not Pressed then
        return
    end

    if self:getAudioModeOn() then
        return
    end

    MuteSoloHelper.toggleGroupSoloState(GroupIndex + MaschineHelper.getFocusGroupBank(self)  * 8)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:onPadEvent(PadIndex, Trigger, PadValue)

    if Trigger ~= true then
        return
    end

    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound = Group and Group:getSounds():at(PadIndex - 1) or nil

    if Sound and self:getAudioModeOn() then

        local AudioMuteParam = Sound:getMuteAudioParameter()
        NI.DATA.ParameterAccess.setBoolParameter(App, AudioMuteParam, not AudioMuteParam:getValue())

    else

        MuteSoloHelper.toggleSoundSoloState(PadIndex)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SoloPage:onScreenButton(ButtonIdx, Pressed)

    if (ButtonIdx == 3 or ButtonIdx == 4) then

        if Pressed and self.Screen.ScreenButton[ButtonIdx]:isEnabled() then
            MaschineHelper.incrementFocusGroupBank(self, ButtonIdx == 3 and -1 or 1, false, false)
        end

    elseif ((ButtonIdx == 5 or ButtonIdx == 6) and not self:getAudioModeOn()) then

        if Pressed then
            MuteSoloHelper.setSoloForAllSounds(ButtonIdx == 5)
        end

    end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------------------------------------------------

function SoloPage:getAudioModeOn()

    return self.Controller.SwitchPressed[NI.HW.BUTTON_SCREEN_8] == true

end

------------------------------------------------------------------------------------------------------------------------
