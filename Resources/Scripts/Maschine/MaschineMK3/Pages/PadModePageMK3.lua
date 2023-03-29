------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/Helper/ObjectColorsHelper"
require "Scripts/Maschine/MaschineMK3/Helper/MK3Helper"
require "Scripts/Shared/Helpers/PadModeHelper"

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModePageMK3 = class( 'PadModePageMK3', PageMaschine )

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:__init(Controller)

    PageMaschine.__init(self, "PadModePageMK3", Controller)

    self.InterruptUpdatePadLEDs = false

    self:setupScreen()
    self:setPinned()

    -- Showing rename as shift functionality is only available to non-desktop MASCHINE
    self.ShowRename = NI.APP.isHeadless()

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:setPinned(PinState)

    self.IsPinned = true -- always pinned

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:setupScreen()

    self.Screen = ScreenWithGridStudio(self, { "PAD MODE", "PADS ON", "<<", ">>" },
        { "OCTAVE-", "OCTAVE+", "<<", ">>" })

    -- Param Bar (Left)
    local ParamBar = NI.GUI.insertBar(self.Screen.ScreenLeft, "ParamBar")
    ParamBar:style(NI.GUI.ALIGN_WIDGET_DOWN, "ParamBar")
    self.Screen:addParameterBar(ParamBar)
    self.Screen:insertGroupButtons(true)
    self.Screen.ScreenButton[1]:setSelected(true)

    -- own GroupBank Management to not change the FocusGroup on switching Banks
    self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:onShow(Show)

    if Show then
        self.Screen.ScreenLeft.InfoBar:setMode("PadScreenMode")
        self.Screen.GroupBank = MaschineHelper.getFocusGroupBank()
    end

    PageMaschine.onShow(self, Show)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:updateScreens(ForceUpdate)

    -- make sure GroupBank is not pointing to some outdated value after groups updates
    self.Screen:updateGroupBank(self)

    local BaseGroupIndex = MaschineHelper.getFocusGroupBank(self) * 8

    self.Screen:updateGroupButtonsWithFunctor(
        function(Index)
            Index = Index + BaseGroupIndex - 1 -- make 0-indexed

            local Song = NI.DATA.StateHelper.getFocusSong(App)
            local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
            local Groups = Song and Song:getGroups() or nil
            local Group = Groups and Groups:at(Index)

            if Group then

                local Focused = Group == FocusGroup
                return true, true, false, Focused, Group:getDisplayName()

            elseif Groups and Index == Groups:size() then

                return true, false, false, false, "+"

            end

            return true, false, false, false, ""
        end)

    -- update on-screen pad colors
    PadModeHelper.updatePadColorsStudio(self.Screen)
    self.Screen:updatePadButtonsWithFunctor(
        function(Index)
            return PadModeHelper.getScreenPadButtonState(Index)
        end)

    self.Screen:enableLevelMeters(true)
    PageMaschine.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:updateParameters(ForceUpdate)

    self.ParameterHandler.NumPages = 2
    self.ParameterHandler.NumParamsPerPage = 4

    local ListValues = {}
    local ListColors = {}
    local Names = {}
    local Parameters = {}
    local Sections = {}
    local Values = {}

    if self.ParameterHandler.PageIndex == 1 then

        Sections = { "Choke", "", "Link", "" }

        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        Parameters[1] = Sound and Sound:getChokeGroupParameter()
        Parameters[2] = Sound and Sound:getChokeModeParameter()
        Parameters[3] = Sound and Sound:getLinkGroupParameter()
        Parameters[4] = Sound and Sound:getLinkModeParameter()

        self.ParameterHandler:setParameters(Parameters)
        self.ParameterHandler:setCustomValues(Values)
        self.ParameterHandler:setCustomNames(Names)
        self.ParameterHandler:setCustomSections(Sections)

        self.Controller.CapacitiveList:assignParametersToCaps(Parameters)

    elseif self.ParameterHandler.PageIndex == 2 then

        Sections = { "Colors", "", "Fixed Velocity" }
        Names = { "GROUP", "SOUND", "VELOCITY" }

        ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusGroup(App), 1, Values, ListValues, ListColors)
        ObjectColorsHelper.setupObjectColorParameter(NI.DATA.StateHelper.getFocusSound(App), 2, Values, ListValues, ListColors)

        local Song = NI.DATA.StateHelper.getFocusSong(App)
        Parameters[3] = Song and Song:getFixedVelocityParameter()

        self.ParameterHandler:setParameters(Parameters)
        self.ParameterHandler:setCustomValues(Values)
        self.ParameterHandler:setCustomNames(Names)
        self.ParameterHandler:setCustomSections(Sections)

        self.Controller.CapacitiveList:assignListsToCaps(ListValues, Values, ListColors)

    end

    PageMaschine.updateParameters(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:updateScreenButtons(ForceUpdate)

    local ShiftPressed = self.Controller:getShiftPressed()
    local IsNotesMode = PadModeHelper.isTouchstripModeNotes()

    self.Screen:update(ForceUpdate)

    if ShiftPressed then

        self.Screen:setArrowText(1, "MOVE")
        self.Screen:setArrowText(2, "MOVE")

    else

        self.Screen:unsetArrowText(2, "SEMITONE-", "SEMITONE+")

    end

    local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)
    local Groups = FocusSong and FocusSong:getGroups() or nil
    local Sounds = FocusGroup and FocusGroup:getSounds() or nil
    local StateCache = App:getStateCache()
    local isFocusSoundEnabled = FocusSound and StateCache:getObjectCache():isSoundEnabled(FocusSound) or false

    local PadsEnabled = App:getWorkspace():getPlayPadsInNotesModeEnabledParameter():getValue()

    if ShiftPressed and self.ShowRename then

        self.Screen.ScreenButton[2]:setText("RENAME")
        self.Screen.ScreenButton[2]:setEnabled(FocusGroup ~= nil)
        self.Screen.ScreenButton[2]:setVisible(true)
        self.Screen.ScreenButton[2]:setSelected(false)

    elseif ShiftPressed then

        self.Screen.ScreenButton[2]:setText("")
        self.Screen.ScreenButton[2]:setEnabled(false)
        self.Screen.ScreenButton[2]:setVisible(false)
        self.Screen.ScreenButton[2]:setSelected(false)

    else

        self.Screen.ScreenButton[2]:setText("PADS ON")
        self.Screen.ScreenButton[2]:setEnabled(IsNotesMode)
        self.Screen.ScreenButton[2]:setVisible(IsNotesMode)
        self.Screen.ScreenButton[2]:setSelected(IsNotesMode and PadsEnabled)

    end

    if ShiftPressed and Groups then

        self.Screen.ScreenButton[3]:setEnabled(ShiftPressed
            and NI.DATA.ObjectVectorAccess.canShiftFocusedGroup(Groups, false))
        self.Screen.ScreenButton[4]:setEnabled(ShiftPressed
            and NI.DATA.ObjectVectorAccess.canShiftFocusedGroup(Groups, true))

    end

    if ShiftPressed and self.ShowRename then

        self.Screen.ScreenButton[5]:setText("RENAME")
        self.Screen.ScreenButton[5]:setEnabled(true)
        self.Screen.ScreenButton[5]:setVisible(true)

    elseif ShiftPressed then

        self.Screen.ScreenButton[5]:setText("")
        self.Screen.ScreenButton[5]:setEnabled(false)
        self.Screen.ScreenButton[5]:setVisible(false)

    else

        self.Screen.ScreenButton[5]:setText("OCTAVE-")
        self.Screen.ScreenButton[5]:setEnabled(true)
        self.Screen.ScreenButton[5]:setVisible(true)

    end

    self.Screen.ScreenButton[6]:setEnabled(not ShiftPressed)
    self.Screen.ScreenButton[6]:setVisible(not ShiftPressed)

    self.Screen.ScreenButton[7]:setEnabled(ShiftPressed
        and Sounds
        and NI.DATA.ObjectVectorAccess.canShiftFocusedSound(Sounds, false)
        or not ShiftPressed)
    self.Screen.ScreenButton[8]:setEnabled(ShiftPressed
        and Sounds
        and NI.DATA.ObjectVectorAccess.canShiftFocusedSound(Sounds, true)
        or not ShiftPressed)

    self.Controller:updateScreenButtonLEDs(self.Screen.ScreenButton)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:onScreenButton(Index, Pressed)

    local ShiftPressed = self.Controller:getShiftPressed()
    local IsNotesMode = PadModeHelper.isTouchstripModeNotes()
    local Transpose = 0
    local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
    local FocusGroup = NI.DATA.StateHelper.getFocusGroup(App)
    local FocusSound = NI.DATA.StateHelper.getFocusSound(App)
    local Groups = FocusSong and FocusSong:getGroups() or nil
    local Sounds = FocusGroup and FocusGroup:getSounds() or nil
    local ShouldHandle = Pressed and self.Screen.ScreenButton[Index]:isEnabled()

    if ShouldHandle and Index == 2 then

        if ShiftPressed and self.ShowRename and FocusGroup then

            MaschineHelper.openRenameDialog(FocusGroup:getDisplayName(), FocusGroup:getNameParameter())

        elseif not ShiftPressed and IsNotesMode then

            MK3Helper.togglePlayPadsInNotesModeParameter()

        end

    elseif ShouldHandle and Index == 3 then

        if ShiftPressed and Groups then

            local FocusSong = NI.DATA.StateHelper.getFocusSong(App)
            NI.DATA.ObjectVectorAccess.shiftFocusedGroup(App, Groups, false)
            MaschineHelper.setFocusGroupBankAndGroup(self, MaschineHelper.getFocusGroupBank())

        else

            MaschineHelper.incrementFocusGroupBank(self, -1, false, true)

        end

    elseif ShouldHandle and Index == 4 then

        if ShiftPressed and Groups then

            NI.DATA.ObjectVectorAccess.shiftFocusedGroup(App, Groups, true)
            MaschineHelper.setFocusGroupBankAndGroup(self, MaschineHelper.getFocusGroupBank())

        else

            MaschineHelper.incrementFocusGroupBank(self, 1, false, true)

        end

    elseif ShouldHandle and Index == 5  then

        if ShiftPressed and self.ShowRename and FocusSound then

            local IsNewNameSet = MaschineHelper.openRenameDialog(FocusSound:getDisplayName(), FocusSound:getNameParameter())
            NI.DATA.ParameterAccess.setBoolParameterNoUndo(App, FocusSound:getIsCustomNameParameter(), IsNewNameSet)

        elseif not ShiftPressed then

            PadModeHelper.transposeRootNoteOrBaseKey(-12, self.Controller)

        end

    elseif ShouldHandle and not ShiftPressed and Index == 6 then

        PadModeHelper.transposeRootNoteOrBaseKey(12, self.Controller)

    elseif ShouldHandle and (Index == 7 or Index == 8) then

        if ShiftPressed and Sounds then

            self.InterruptUpdatePadLEDs = true
            NI.DATA.ObjectVectorAccess.shiftFocusedSound(App, Sounds, Index == 8)

        else

            PadModeHelper.transposeRootNoteOrBaseKey(Index == 8 and 1 or -1, self.Controller)

        end

    end

    PageMaschine.onScreenButton(self, Index, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:onScreenEncoder(Index, Value)

    local Page = self.ParameterHandler.PageIndex

    if Page == 2 then

        local EncoderSmoothed = MaschineHelper.onScreenEncoderSmoother(Index, Value, .1) ~= 0
        local Next = Value > 0

        if Index == 1 and EncoderSmoothed then

            ObjectColorsHelper.selectPrevNextObjectColor(NI.DATA.StateHelper.getFocusGroup(App), Next,
                NI.DATA.GroupAccess.setGroupColor)

        elseif Index == 2 and EncoderSmoothed then

            ObjectColorsHelper.selectPrevNextObjectColor(NI.DATA.StateHelper.getFocusSound(App), Next,
                NI.DATA.SoundAccess.setSoundColor)

        end

    end

    PageMaschine.onScreenEncoder(self, Index, Value)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:onGroupButtonPressed(ButtonIndex, ErasePressed, ShiftPressed, Song, Groups)

    local GroupIndex = ButtonIndex - 1 + (MaschineHelper.getFocusGroupBank(self) * 8)
    local Group = Groups:at(GroupIndex) or nil

    if ShiftPressed and ErasePressed and Group then

        NI.DATA.ObjectVectorAccess.removeGroupResetLast(App, Groups, Group)

    elseif Song and GroupIndex == Groups:size() then

        NI.DATA.SongAccess.createGroup(App, Song, false)

    elseif Group then

        NI.DATA.SongAccess.setFocusGroup(App, Song, Group, false)

    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:updateGroupLEDs()

    LEDHelper.updateLEDsWithFunctor(self.Controller.GROUP_LEDS,
        MaschineHelper.getFocusGroupBank(self) * 8,
        function (Index) return MaschineHelper.getLEDStatesGroupSelectedByIndex(Index, true, false) end,
        function (Index) return MaschineHelper.getGroupColorByIndex(Index, true) end,
        MaschineHelper.getFlashStateGroupsNoteOn)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:updatePadLEDs()

    if self.InterruptUpdatePadLEDs == false then

        PadModeHelper.updatePadLEDs(self.Controller)

    else

        self.InterruptUpdatePadLEDs = false

    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:getAccessiblePageInfo()

    return "Pad Mode Page"

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMK3:getAccessibleTextByButtonIndex(ButtonIdx)

    if not self.Controller:getShiftPressed() then
        if ButtonIdx == 5 then
            return "Octave minus"
        elseif ButtonIdx == 6 then
            return "Octave plus"
        elseif ButtonIdx == 7 then
            return "Semitone minus"
        elseif ButtonIdx == 8 then
            return "Semitone plus"
        end
    end
    return PageMaschine.getAccessibleTextByButtonIndex(self, ButtonIdx)

end

------------------------------------------------------------------------------------------------------------------------
