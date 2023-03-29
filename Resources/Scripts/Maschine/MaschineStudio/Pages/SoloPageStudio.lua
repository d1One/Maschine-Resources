------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/MuteSoloHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SoloPageStudio = class( 'SoloPageStudio', PageMaschine )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SoloPageStudio:__init(Controller)

    -- init base class
    PageMaschine.__init(self, "SoloPageStudio", Controller)

    -- create screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SOLO }

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SoloPageStudio:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"SOLO", "", "<<", ">>"}, {"ALL ON", "NONE", "", "AUDIO"})
    self.Screen.ScreenButton[1]:style("SOLO", "HeadPin")
    self.Screen:enableLevelMeters(true)

    -- Group buttons in left screen
    self.Screen:insertGroupButtons(false)

end


------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function SoloPageStudio:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after Groups updates
    self.Screen:updateGroupBank(self)

    local AudioModeOn = self:getAudioModeOn()
    local BaseGroupIndex = self.Screen.GroupBank * 8

    -- update on-screen Group grid
    self.Screen:updateGroupButtonsWithFunctor(
        function(Index)
            Index = Index + BaseGroupIndex
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Groups = Song and Song:getGroups() or nil

            return MuteSoloHelper.getMuteButtonStateGroups(Groups, Index)
        end
    )

    -- update on-screen pads grid
    self.Screen:updatePadButtonsWithFunctor(
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

function SoloPageStudio:updateGroupLEDs(UpdateGroupBank)

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
            self.Screen.GroupBank * 8,
            MuteSoloHelper.getGroupMuteByIndexLEDStates,
            MaschineHelper.getGroupColorByIndex,
            MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageStudio:updatePadLEDs()

    -- update sound leds with focus state
    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
        function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, self:getAudioModeOn()) end,
        MaschineHelper.getSoundColorByIndex,
        MaschineHelper.getFlashStateSoundsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function SoloPageStudio:onGroupButton(GroupIndex, Pressed)

    if not Pressed then
        return
    end

    if self:getAudioModeOn() then
        return
    end

    MuteSoloHelper.toggleGroupSoloState(GroupIndex + self.Screen.GroupBank  * 8)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageStudio:onPadEvent(PadIndex, Trigger, PadValue)

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

function SoloPageStudio:onShow(Show)

	PageMaschine.onShow(self, Show)

	if Show then
		self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
	end

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageStudio:onScreenButton(ButtonIdx, Pressed)

    if (ButtonIdx == 3 or ButtonIdx == 4) then

        if Pressed and self.Screen.ScreenButton[ButtonIdx]:isEnabled() then
            self.Screen:incrementGroupBank(ButtonIdx == 3 and -1 or 1)
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

function SoloPageStudio:getAudioModeOn()

    return self.Controller.SwitchPressed[NI.HW.BUTTON_SCREEN_8] == true

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageStudio:getAccessiblePageInfo()

    return "Solo"

end

------------------------------------------------------------------------------------------------------------------------
