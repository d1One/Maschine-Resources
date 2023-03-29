------------------------------------------------------------------------------------------------------------------------

require "Scripts/Shared/Pages/PageMaschine"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/MuteSoloHelper"
require "Scripts/Maschine/MaschineStudio/Screens/ScreenWithGridStudio"


------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MutePageStudio = class( 'MutePageStudio', PageMaschine )


------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:__init(Controller)

    PageMaschine.__init(self, "MutePageStudio", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_MUTE }

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:setupScreen()

    self.Screen = ScreenWithGridStudio(self, {"MUTE", "", "<<", ">>"}, {"ALL ON", "NONE", "", "AUDIO"})

    self.Screen:enableLevelMeters(true)

    self.Screen.ScreenButton[1]:style("MUTE", "HeadPin");

    -- Group buttons in left screen
    self.Screen:insertGroupButtons(false)
end


------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after Groups updates
    self.Screen:updateGroupBank(self)

    local AudioModeOn = self:getAudioModeOn()
    local BaseGroupIndex = self.Screen.GroupBank * 8

    -- update on-screen Group grid
    self.Screen:updateGroupButtonsWithFunctor(
        function(Index)
            local NewIndex = Index + BaseGroupIndex
            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local Groups = Song and Song:getGroups() or nil

            return MuteSoloHelper.getMuteButtonStateGroups(Groups, NewIndex)
        end
    )

    -- update on-screen pad grid
    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local Sounds = Group and Group:getSounds() or nil

            return MuteSoloHelper.getMuteButtonStateSounds(Sounds, Index, AudioModeOn)
        end
    )

    self.Screen.ScreenButton[8]:setSelected(AudioModeOn)

	-- audio mode needs to toggle the all on and none buttons
	self.Screen.ScreenButton[5]:setVisible(not AudioModeOn)
	self.Screen.ScreenButton[6]:setVisible(not AudioModeOn)


    -- call base class
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:updateGroupLEDs()

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
        self.Screen.GroupBank * 8,
        MuteSoloHelper.getGroupMuteByIndexLEDStates,
        MaschineHelper.getGroupColorByIndex,
        MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:updatePadLEDs()

    -- update sound leds with focus state
    LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
        function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, self:getAudioModeOn()) end,
        MaschineHelper.getSoundColorByIndex,
        MaschineHelper.getFlashStateSoundsNoteOn)

end


------------------------------------------------------------------------------------------------------------------------
-- event handling
------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:onPadEvent(PadIndex, Trigger)

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

function MutePageStudio:onGroupButton(GroupIndex, Pressed)

    if not Pressed then
        return
    end

    -- mute / unmute Group by Group index
    local MuteGroupFunction =
        function(Groups, Group)
            local MuteParameter = Group:getMuteParameter()
            NI.DATA.ParameterAccess.setBoolParameter(App, MuteParameter, not MuteParameter:getValue())
        end

    -- call mute Group
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Groups = Song and Song:getGroups() or nil
    local AdjustedIndex = GroupIndex + (self.Screen.GroupBank * 8)
    MaschineHelper.callFunctionWithObjectVectorAndItemByIndex(Groups, AdjustedIndex, MuteGroupFunction)

end

------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:onShow(Show)

	PageMaschine.onShow(self, Show)

	if Show then
		self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
	end

end

------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:onScreenButton(ButtonIdx, Pressed)

    if (ButtonIdx == 3 or ButtonIdx == 4) then

        if Pressed and self.Screen.ScreenButton[ButtonIdx]:isEnabled() then
            self.Screen:incrementGroupBank(ButtonIdx == 3 and -1 or 1)
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

function MutePageStudio:getAudioModeOn()

    return self.Controller.SwitchPressed[NI.HW.BUTTON_SCREEN_8] == true

end

------------------------------------------------------------------------------------------------------------------------

function MutePageStudio:getAccessiblePageInfo()

    return "Mute"

end

------------------------------------------------------------------------------------------------------------------------
