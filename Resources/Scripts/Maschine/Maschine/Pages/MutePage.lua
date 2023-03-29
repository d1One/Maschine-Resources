------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/Maschine/Screens/ScreenWithGrid"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MutePage = class( 'MutePage', PageMaschine )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MutePage:__init(Controller)

    PageMaschine.__init(self, "MutePage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_MUTE }

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function MutePage:setupScreen()

    self.Screen = ScreenWithGrid(self)

    -- screen buttons
    ScreenHelper.setWidgetText(self.Screen.ScreenButton, {"MUTE", "", "PREV", "NEXT", "ALL ON", "NONE", "", "AUDIO"})
    self.Screen.ScreenButton[1]:style("MUTE", "HeadPin");

    -- Group buttons in left screen
    self.Screen:insertGroupButtons(false)

end


------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function MutePage:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after Groups updates
    self.Screen:updateGroupBank(self)

    local AudioModeOn = self:getAudioModeOn()
    local BaseGroupIndex = MaschineHelper.getFocusGroupBank(self) * 8

    -- update on-screen Group grid
    ScreenHelper.updateButtonsWithFunctor(self.Screen.GroupButtons,
        function(Index)
            local NewIndex = Index + BaseGroupIndex
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Groups = Song and Song:getGroups() or nil

            return MuteSoloHelper.getMuteButtonStateGroups(Groups, NewIndex)
        end
    )

    -- update on-screen pad grid
    ScreenHelper.updateButtonsWithFunctor(self.Screen.ButtonPad,
        function(Index)
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local Sounds = Group and Group:getSounds() or nil

            return MuteSoloHelper.getMuteButtonStateSounds(Sounds, Index, AudioModeOn)
        end
    )

    -- screen buttons
    self.Screen.ScreenButton[8]:setSelected(AudioModeOn)

    -- audio mode needs to toggle the all on and none buttons
    self.Screen.ScreenButton[5]:setVisible(not AudioModeOn)
    self.Screen.ScreenButton[6]:setVisible(not AudioModeOn)

    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MutePage:updateGroupLEDs()

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
        MaschineHelper.getFocusGroupBank(self) * 8,
        MuteSoloHelper.getGroupMuteByIndexLEDStates,
        MaschineHelper.getGroupColorByIndex,
        MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function MutePage:updatePadLEDs()

    -- update sound leds with focus state
    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
		function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, self:getAudioModeOn()) end,
        MaschineHelper.getSoundColorByIndex,
        MaschineHelper.getFlashStateSoundsNoteOn)

end


------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function MutePage:onShow(Show)

	PageMaschine.onShow(self, Show)

	if Show then
		self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
	end

end

------------------------------------------------------------------------------------------------------------------------

function MutePage:onPadEvent(PadIndex, Trigger)

    -- ON Event
    if Trigger then

        -- mute / unmute sound by pad index
        local MuteSoundFunction =
            function(Sounds, Sound)
				local MuteParameter = (self:getAudioModeOn() == true) and
					Sound:getMuteAudioParameter() or
					Sound:getMuteParameter()

                NI.DATA.ParameterAccess.setBoolParameter(App, MuteParameter, not MuteParameter:getValue())
            end

        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sounds = Group and Group:getSounds() or nil

        MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(Sounds, PadIndex, MuteSoundFunction)

    end

end


------------------------------------------------------------------------------------------------------------------------

function MutePage:onGroupButton(GroupIndex, Pressed)

	if not Pressed then
		return
	end

    -- call mute Group
    local AdjustedIndex = GroupIndex + (MaschineHelper.getFocusGroupBank(self) * 8)
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    local Group = Groups and Groups:at(AdjustedIndex - 1) or nil

    if Group then
		-- mute / unmute Group by Group index
		local MuteParameter = Group:getMuteParameter()
        NI.DATA.ParameterAccess.setBoolParameter(App, MuteParameter, not MuteParameter:getValue())
    end

end


------------------------------------------------------------------------------------------------------------------------

function MutePage:onScreenButton(ButtonIdx, Pressed)

    if (ButtonIdx == 3 or ButtonIdx == 4) then

        if Pressed and self.Screen.ScreenButton[ButtonIdx]:isEnabled() then
            MaschineHelper.incrementFocusGroupBank(self, ButtonIdx == 3 and -1 or 1, false, false)
        end

    elseif ((ButtonIdx == 5 or ButtonIdx == 6) and not self:getAudioModeOn()) then

        if Pressed then
            MuteSoloHelper.setMuteForAllSounds(ButtonIdx == 6)
        end

	end

    -- call base class for update
    PageMaschine.onScreenButton(self, ButtonIdx, Pressed)

end


------------------------------------------------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------------------------------------------------

function MutePage:getAudioModeOn()

	return self.Controller.SwitchPressed[NI.HW.BUTTON_SCREEN_8] == true

end


------------------------------------------------------------------------------------------------------------------------

