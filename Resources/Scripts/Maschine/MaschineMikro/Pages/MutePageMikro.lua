------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/MuteSoloHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
MutePageMikro = class( 'MutePageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

MutePageMikro.SOUND = 1
MutePageMikro.GROUP = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "MutePage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_MUTE }

    self.PageMode = self.Controller:getGroupPressed() and MutePageMikro.GROUP or MutePageMikro.SOUND

end


------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- screen title
    ScreenHelper.setWidgetText(self.Screen.Title, {"MUTE"})

    -- screen buttons
    self.Screen:styleScreenButtons({"ALL ON", "NONE", "AUDIO"}, "HeadButtonRow", "HeadButton")

    -- parameter bar
    self.Screen.ParameterLabel[2]:setText("BANK")

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:onShow(Show)

    if not Show then
        LEDHelper.setLEDState(NI.HW.LED_GROUP, LEDHelper.LS_OFF)
    end

    Page.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:onGroupButton(Pressed)

	if Pressed then
		self:toggleMode()
	end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after Groups updates
    self.Screen:updateGroupBank(self)

    local IsInSoundMode = self.PageMode == MutePageMikro.SOUND

    -- title
    ScreenHelper.setWidgetText(self.Screen.Title, IsInSoundMode and {"MUTE SOUND"} or {"MUTE GROUP"})

    -- screen buttons
    self.Screen.ScreenButton[3]:setText(IsInSoundMode and "AUDIO" or "")
    self.Screen.ScreenButton[3]:setEnabled(IsInSoundMode)
    self.Screen.ScreenButton[3]:setSelected(IsInSoundMode and self:getAudioModeOn() or false)
	self.Screen.ScreenButton[1]:setVisible(not self:getAudioModeOn())
	self.Screen.ScreenButton[2]:setVisible(not self:getAudioModeOn())

    -- parameter bar
    for Index = 1,4 do
        self.Screen.ParameterLabel[Index]:setVisible(not IsInSoundMode)
    end
    self.Screen.ParameterLabel[2]:setText("BANK: "..tostring(MaschineHelper.getFocusGroupBank() + 1).."/"
                                                        ..tostring(MaschineHelper.getNumFocusSongGroupBanks(false)))

    -- call base
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:updateGroupLEDs()

    if self.PageMode == MutePageMikro.GROUP then
        -- show Groups on pads
        LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
            MaschineHelper.getFocusGroupBank() * 8,
            MuteSoloHelper.getGroupMuteByIndexLEDStates,
            MaschineHelper.getGroupColorByIndex)
    else
        -- call base
        PageMikro.updateGroupLEDs(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:updatePadLEDs()

	local GroupColor = MaschineHelper.getGroupColorByIndex(NI.DATA.StateHelper.getFocusGroupIndex(App) + 1)

    if self.PageMode == MutePageMikro.SOUND then
        -- update sound leds with focus state
        LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
            function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, self:getAudioModeOn()) end,
            MaschineHelper.getSoundColorByIndex,
            MaschineHelper.getFlashStateSoundsNoteOn)

		local LEDState = GroupColor >= 0 and LEDHelper.LS_DIM or LEDHelper.LS_OFF
		LEDHelper.setLEDColor(NI.HW.LED_GROUP, LEDColors[GroupColor][LEDState])
    else
		local LEDState = GroupColor >= 0 and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF
        LEDHelper.turnOffLEDs(self.Controller.PAD_LEDS)
		LEDHelper.setLEDColor(NI.HW.LED_GROUP, LEDColors[GroupColor][LEDState])
    end

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:updateLeftRightLEDs(ForceUpdate)

	local GroupBank = MaschineHelper.getFocusGroupBank() + 1
	local MaxBanks = MaschineHelper.getNumFocusSongGroupBanks(false)

	self.Screen.ParameterLabel[1]:setVisible(self.PageMode == MutePageMikro.GROUP and GroupBank > 1)
	self.Screen.ParameterLabel[3]:setVisible(self.PageMode == MutePageMikro.GROUP and GroupBank < MaxBanks)

	-- call base class
	PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:setMode(Mode)

    self.PageMode = Mode
    self.PageLEDs = Mode == MutePageMikro.GROUP and {NI.HW.LED_MUTE, NI.HW.LED_GROUP} or {NI.HW.LED_MUTE}

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:toggleMode()

    if self.PageMode == MutePageMikro.SOUND then
        -- set to Group mode
        self:setMode(MutePageMikro.GROUP)
    else
        -- set to Sound mode
        self:setMode(MutePageMikro.SOUND)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:onScreenButton(Idx, Pressed)

    if Pressed and ((Idx == 1 or Idx == 2) and not self:getAudioModeOn()) then

        if self.PageMode == MutePageMikro.SOUND then
            MuteSoloHelper.setMuteForAllSounds(Idx == 2)
        else
            MuteSoloHelper.setMuteForAllGroups(Idx == 2)
        end

    end

    -- call base class for update
    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:onPadEvent(PadIndex, Trigger, PadValue)

    if not Trigger then
        return
    end

    if self.PageMode == MutePageMikro.SOUND then

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


    elseif PadIndex > 8 then -- restrict to top 8 pads for Groups

        local GroupIndex = self.Controller.PAD_TO_GROUP[PadIndex] + (MaschineHelper.getFocusGroupBank() * 8)
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        local Groups = Song and Song:getGroups() or nil

        MuteSoloHelper.toggleMuteState(Groups, GroupIndex)
    end

end

------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:onLeftRightButton(Right, Pressed)

	if Pressed and self.PageMode == MutePageMikro.GROUP then
		MaschineHelper.incrementFocusGroupBank(self, Right and 1 or -1, true, false)
	end

end


------------------------------------------------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------------------------------------------------

function MutePageMikro:getAudioModeOn()

    return self.PageMode == MutePageMikro.SOUND
        and self.Controller.SwitchPressed[NI.HW.BUTTON_F3] == true

end


------------------------------------------------------------------------------------------------------------------------
