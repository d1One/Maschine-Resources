------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Maschine/Helper/MuteSoloHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
SoloPageMikro = class( 'SoloPageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- CONSTS
------------------------------------------------------------------------------------------------------------------------

SoloPageMikro.SOUND = 1
SoloPageMikro.GROUP = 2

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "SoloPage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_SOLO }

	self.PageMode = self.Controller:getGroupPressed() and SoloPageMikro.GROUP or SoloPageMikro.SOUND

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- screen title
    ScreenHelper.setWidgetText(self.Screen.Title, {"SOLO"})

    -- screen buttons
    self.Screen:styleScreenButtons({"ALL ON", "NONE", "AUDIO"}, "HeadButtonRow", "HeadButton")

    -- parameter bar
    self.Screen.ParameterLabel[2]:setText("BANK")

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:onShow(Show)

    if not Show then
        LEDHelper.setLEDState(NI.HW.LED_GROUP, LEDHelper.LS_OFF)
    end

    Page.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:onGroupButton(Pressed)

	if Pressed then
		self:toggleMode()
	end

    self:updateScreens()

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after Groups updates
    self.Screen:updateGroupBank(self)

    local IsInSoundMode = self.PageMode == SoloPageMikro.SOUND

    -- title
    ScreenHelper.setWidgetText(self.Screen.Title, IsInSoundMode and {"SOLO SOUND"} or {"SOLO GROUP"})

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

function SoloPageMikro:updatePadLEDs()

	local GroupColor = MaschineHelper.getGroupColorByIndex(NI.DATA.StateHelper.getFocusGroupIndex(App) + 1)

    if self.PageMode == SoloPageMikro.SOUND then
        -- update sound leds with focus state
        LEDHelper.updateLEDsWithFunctor(self.Controller.PAD_LEDS, 0,
            function(Index) return MuteSoloHelper.getSoundMuteByIndexLEDStates(Index, self:getAudioModeOn()) end,
            MaschineHelper.getSoundColorByIndex,
            MaschineHelper.getFlashStateSoundsNoteOn)

		local GroupLEDState = GroupColor >= 0 and LEDHelper.LS_DIM or LEDHelper.LS_OFF
        LEDHelper.setLEDColor(NI.HW.LED_GROUP, LEDColors[GroupColor][LEDHelper.LS_DIM])
    else
		local GroupLEDState = GroupColor >= 0 and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF
        LEDHelper.turnOffLEDs(self.Controller.PAD_LEDS)
		LEDHelper.setLEDColor(NI.HW.LED_GROUP, LEDColors[GroupColor][GroupLEDState])
    end

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:updateLeftRightLEDs(ForceUpdate)

	local GroupBank = MaschineHelper.getFocusGroupBank() + 1
	local MaxBanks = MaschineHelper.getNumFocusSongGroupBanks(false)

	self.Screen.ParameterLabel[1]:setVisible(self.PageMode == SoloPageMikro.GROUP and GroupBank > 1)
	self.Screen.ParameterLabel[3]:setVisible(self.PageMode == SoloPageMikro.GROUP and GroupBank < MaxBanks)

	-- call base class
	PageMikro.updateLeftRightLEDs(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:updateGroupLEDs()

    if self.PageMode == SoloPageMikro.GROUP then
        -- show Groups on pads
        LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
            MaschineHelper.getFocusGroupBank() * 8,
            MuteSoloHelper.getGroupMuteByIndexLEDStates,
            MaschineHelper.getGroupColorByIndex,
            MaschineHelper.getFlashStateGroupsNoteOn)
    else
        -- call base
        PageMikro.updateGroupLEDs(self)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:setMode(Mode)

    self.PageMode = Mode
    self.PageLEDs = Mode == SoloPageMikro.GROUP and {NI.HW.LED_SOLO, NI.HW.LED_GROUP} or {NI.HW.LED_SOLO}

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:toggleMode()

    if self.PageMode == SoloPageMikro.SOUND then
        -- set to Group mode
        self:setMode(SoloPageMikro.GROUP)
    else
        -- set to Sound mode
        self:setMode(SoloPageMikro.SOUND)
    end

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:onScreenButton(Idx, Pressed)

    if Pressed and ((Idx == 1 or Idx == 2) and not self:getAudioModeOn()) then
        if self.PageMode == SoloPageMikro.SOUND then
            MuteSoloHelper.setSoloForAllSounds(Idx == 1)
        else
            MuteSoloHelper.setSoloForAllGroups(Idx == 1)
        end

    end

    -- call base class for update
    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:onPadEvent(PadIndex, Trigger)

    if not Trigger then
        return
    end

    if self.PageMode == SoloPageMikro.SOUND then

        -- toggle Sound solo
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        local Sound = Group and Group:getSounds():at(PadIndex - 1) or nil
        if Sound and self:getAudioModeOn() then

		      local AudioMuteParam = Sound:getMuteAudioParameter()
		      NI.DATA.ParameterAccess.setBoolParameter(App, AudioMuteParam, not AudioMuteParam:getValue())

        else

            MuteSoloHelper.toggleSoundSoloState(PadIndex)

        end

    elseif PadIndex > 8 then -- restrict to top 8 pads for Groups

        -- toggle Group solo
        local GroupIndex = self.Controller.PAD_TO_GROUP[PadIndex] + (MaschineHelper.getFocusGroupBank() * 8)
        MuteSoloHelper.toggleGroupSoloState(GroupIndex)

    end

end

------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:onLeftRightButton(Right, Pressed)

	if Pressed and self.PageMode == SoloPageMikro.GROUP then
		MaschineHelper.incrementFocusGroupBank(self, Right and 1 or -1, true, false)
	end

end


------------------------------------------------------------------------------------------------------------------------
-- Helper
------------------------------------------------------------------------------------------------------------------------

function SoloPageMikro:getAudioModeOn()

    return self.PageMode == SoloPageMikro.SOUND
        and self.Controller.SwitchPressed[NI.HW.BUTTON_F3] == true

end


------------------------------------------------------------------------------------------------------------------------
