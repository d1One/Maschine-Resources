------------------------------------------------------------------------------------------------------------------------

require "Scripts/Maschine/MaschineMikro/PageMikro"
require "Scripts/Shared/Helpers/MaschineHelper"
require "Scripts/Shared/Helpers/PadModeHelper"

local ATTR_IS_PAD_MODE = NI.UTILS.Symbol("isPadMode")

------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
PadModePageMikro = class( 'PadModePageMikro', PageMikro )

------------------------------------------------------------------------------------------------------------------------
-- init
------------------------------------------------------------------------------------------------------------------------

function PadModePageMikro:__init(Controller)

    -- init base class
    PageMikro.__init(self, "PadModePage", Controller)

    -- setup screen
    self:setupScreen()

    -- define page leds
    self.PageLEDs = { NI.HW.LED_PAD_MODE }
    self.CachedFocusParam = {}

    self.ParameterHandler.ExtendParameterNames = true

end

------------------------------------------------------------------------------------------------------------------------
-- setup screen
------------------------------------------------------------------------------------------------------------------------

function PadModePageMikro:setupScreen()

    -- setup screen
    self.Screen = ScreenMikro(self)

    -- Info Display
    ScreenHelper.setWidgetText(self.Screen.Title, {"PAD MODE"})
    self.Screen:styleScreenButtons({"KEYBD", "16 VEL", "FIX VEL"}, "HeadButtonRow", "HeadButton")

    -- Info Bar
    self.Screen.InfoBar:setMode("PadScreenMode")
    self.Screen.InfoBar.Labels[2]:setAttribute(ATTR_IS_PAD_MODE, "true")

    -- setup parameter handler
    self.ParameterHandler:setLabels(self.Screen.ParameterLabel[2], self.Screen.ParameterLabel[4])

    self.ParameterHandler:setParameterIndexChangedFunc(function (Index) PadModePageMikro.onParameterIndexChanged(self, Index) end)

end

------------------------------------------------------------------------------------------------------------------------
-- update
------------------------------------------------------------------------------------------------------------------------

function PadModePageMikro:updateScreens(ForceUpdate)

    -- sync pad mode with that in sw

    local VelocityMode = PadModeHelper.getPadVelocityMode()
    local KeyboardModeOn = PadModeHelper.getKeyboardMode()

    self.Screen.ScreenButton[1]:setSelected(KeyboardModeOn)
    self.Screen.ScreenButton[2]:setSelected(not KeyboardModeOn and VelocityMode == NI.HW.PAD_VELOCITY_16_LEVELS)
    self.Screen.ScreenButton[3]:setSelected(not KeyboardModeOn and VelocityMode == NI.HW.PAD_VELOCITY_FIXED)

    self.Screen.ScreenButton[2]:setText(KeyboardModeOn and "OCT-" or "16 VEL")
    self.Screen.ScreenButton[3]:setText(KeyboardModeOn and "OCT+" or "FIX VEL")

    if KeyboardModeOn then
        self.Screen.ScreenButton[2]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(-12))
        self.Screen.ScreenButton[3]:setEnabled(self.SelectMode or PadModeHelper.canTransposeRootNote(12))
    else
        self.Screen.ScreenButton[2]:setEnabled(true)
        self.Screen.ScreenButton[3]:setEnabled(true)
    end

    -- Update InfoBar
    self.Screen.InfoBar:update(true)

    -- call base class
    PageMikro.updateScreens(self, ForceUpdate)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMikro:onParameterIndexChanged(Index)

    self.CachedFocusParam[PadModeHelper.getKeyboardMode()] = self.ParameterHandler.Parameters[Index]

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMikro:updateParameters(ForceUpdate)

    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local ScaleEngine = NI.DATA.getScaleEngine(App)

    -- Set the parameters
    local Parameters = {}
    local CustomNames = {}
    local CustomValues = {}

    if Sound then
        if PadModeHelper.getKeyboardMode() then
            local Group = NI.DATA.StateHelper.getFocusGroup(App)
            local RootNoteParam = Group and Group:getRootNoteParameter() or nil
            if ScaleEngine then
                Parameters[1] = RootNoteParam
                CustomNames[1] = "ROOT NOTE"
                if RootNoteParam then
                    local RootNote = RootNoteParam:getValue()
                    CustomValues[1] = ScaleEngine:getRootNoteName(RootNote)
                end

                if not ScaleEngine:getChordModeIsChordSet() then
                    Parameters[#Parameters + 1] = ScaleEngine:getScaleBankParameter()
                    CustomNames[#Parameters] = "SCALE BANK"
                    Parameters[#Parameters + 1] = ScaleEngine:getScaleParameter()
                    CustomNames[#Parameters] = "SCALE TYPE"
                end

                Parameters[#Parameters + 1] = ScaleEngine:getChordModeParameter()
                CustomNames[#Parameters] = "MODE"

                if ScaleEngine:getChordModeParameter():getValue() ~= 0 then
                    Parameters[#Parameters + 1] = ScaleEngine:getCurrentChordTypeParameter()
                    CustomNames[#Parameters] = "CHORD TYPE"
                end
            end
        else
            Parameters[1] = Sound:getBaseKeyParameter()
            Parameters[2] = Sound:getChokeGroupParameter()
            Parameters[3] = Sound:getChokeModeParameter()
            Parameters[4] = Sound:getLinkGroupParameter()
            Parameters[5] = Sound:getLinkModeParameter()
        end
    end

    if Song then
        Parameters[#Parameters + 1] = Song:getFixedVelocityParameter()
        CustomNames[#Parameters] = "FIXED VELOCITY"
    end


    -- set parameters & recall Index if possible (otherwise reset)

    self.ParameterHandler:setParameters(Parameters, true, CustomValues, CustomNames)
    local ParamIndex = 1

    local SavedParam = self.CachedFocusParam[PadModeHelper.getKeyboardMode()]

	for Index, Param in pairs (Parameters) do
		if SavedParam and Param:isParameterEqual(SavedParam) then
			ParamIndex = Index
			break
		end
	end

	self.ParameterHandler:setParameterIndex(ParamIndex)

    -- call base
    PageMikro.updateParameters(self, ForceUpdate)

    for i=1,5 do
        if self.ParameterHandler.ParameterIndex == i and PadModeHelper.multiSelectionCheckers[i](App) then
            self.Screen.ParameterLabel[4]:setText("*")
        end
    end

    -- MAS2-8249 hack - todo: remove when font are replaced
    local IsChordTypeMin7b5 = ParamIndex == 5 and PadModeHelper.getKeyboardMode and PadModeHelper.isChordTypeMin7b5()
    local SmallFont = IsChordTypeMin7b5 or (ParamIndex == 1 and PadModeHelper.getKeyboardMode())
    self.ParameterHandler.ParamValueLabel:setAttribute(ATTR_IS_PAD_MODE, SmallFont and "true" or "false")
    if IsChordTypeMin7b5 then
        self.ParameterHandler.ParamValueLabel:setText("MIN 7b5")
    end

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMikro:onScreenButton(Idx, Pressed)

    if Pressed then

        if Idx == 1 then
            -- toggle step editor/piano roll mode
            PadModeHelper.toggleKeyboardMode()

        elseif Idx == 2 and not PadModeHelper.getKeyboardMode() then
            -- toggle 16-Velocity mode
            PadModeHelper.togglePadVelocityMode(NI.HW.PAD_VELOCITY_16_LEVELS)

        elseif (Idx == 2 or Idx == 3) then
            if NHLController:getPadMode() == NI.HW.PAD_MODE_KEYBOARD then
                -- transpose base key
                local Transpose = Idx==2 and -12 or 12
                PadModeHelper.transposeRootNoteOrBaseKey(Transpose, self.Controller)

            elseif Idx == 3 then
                -- toggle fixed velocity
                PadModeHelper.togglePadVelocityMode(NI.HW.PAD_VELOCITY_FIXED)
            end
        end

    end

    -- call base class for update
    PageMikro.onScreenButton(self, Idx, Pressed)

end

------------------------------------------------------------------------------------------------------------------------

function PadModePageMikro:onWheel(Value)

    local ParamHandler = self.ParameterHandler
    local Param = ParamHandler and ParamHandler.Parameters[ParamHandler.ParameterIndex] or nil

    if Param and Param:getName() == "Base Key" then
        if NI.DATA.StateHelper.getIsBaseKeyMultiSelection(App) then
            PadModeHelper.setBaseKeyOffsetTempMode(self.Controller, Value)
        end
    end

    -- call base
    return PageMikro.onWheel(self, Value)
end



------------------------------------------------------------------------------------------------------------------------
