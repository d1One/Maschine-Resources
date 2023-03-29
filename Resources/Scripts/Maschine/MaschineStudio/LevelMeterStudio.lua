------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LevelMeterStudio = class( 'LevelMeterStudio' )


LevelMeterStudio.ButtonToStereoSource = {}
LevelMeterStudio.ButtonToStereoSource[NI.HW.BUTTON_LEVEL_IN1] = 0
LevelMeterStudio.ButtonToStereoSource[NI.HW.BUTTON_LEVEL_IN2] = 1
LevelMeterStudio.ButtonToStereoSource[NI.HW.BUTTON_LEVEL_IN3] = 2
LevelMeterStudio.ButtonToStereoSource[NI.HW.BUTTON_LEVEL_IN4] = 3

------------------------------------------------------------------------------------------------------------------------

function LevelMeterStudio:__init(Controller)

    self.Controller = Controller

    self.CachedCaptions = {"",""}
    self.CachedFormattedValue = ""

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterStudio:getSourceCaptions()

	return self.CachedCaptions[1], self.CachedCaptions[2]

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterStudio:getSourceValueFormatted()

	return self.CachedFormattedValue

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterStudio.ButtonToSource(Button)

	if Button >= NI.HW.BUTTON_LEVEL_IN1 and Button <= NI.HW.BUTTON_LEVEL_IN4 then
		return NI.DATA.LEVEL_SOURCE_INPUT

	elseif Button == NI.HW.BUTTON_LEVEL_MASTER or Button == NI.HW.BUTTON_LEVEL_CUE then
		return NI.DATA.LEVEL_SOURCE_MASTERCUE

	elseif Button == NI.HW.BUTTON_LEVEL_GROUP then
		return NI.DATA.LEVEL_SOURCE_GROUP

	elseif Button == NI.HW.BUTTON_LEVEL_SOUND then
		return NI.DATA.LEVEL_SOURCE_SOUND
	end

end

------------------------------------------------------------------------------------------------------------------------
-- Default Behaviour: IN buttons select sound input, OUT buttons select output monitoring source

function LevelMeterStudio:onLevelSourceButton(Pressed, Button)

	local Source = LevelMeterStudio.ButtonToSource(Button)
	if not Source then
		return
	end

    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    if Sound and Source == NI.DATA.LEVEL_SOURCE_INPUT then
        NI.DATA.SoundAccess.setStereoInput(App, Sound, LevelMeterStudio.ButtonToStereoSource[Button], false)
    end

    local SourceParameter = App:getWorkspace():getHWLevelMeterSourceParameter()
    if SourceParameter:getValue() ~= Source then
        NI.DATA.ParameterAccess.setSizeTParameter(App, SourceParameter, Source)
    end

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterStudio:onLevelEncoder(Inc)

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Param = nil

    local Source = App:getWorkspace():getHWLevelMeterSourceParameter():getValue()
    local CueVisible = App:getWorkspace():getMixerCueVisibleParameter():getValue()

    self.CachedCaptions[2] = "VOL"

    if not Song then
        return

    elseif Source == NI.DATA.LEVEL_SOURCE_INPUT then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        Param = Sound and Sound:getInputGainParameter()
        self.CachedCaptions[1] = "INPUT"
        self.CachedCaptions[2] = "GAIN"

    elseif Source == NI.DATA.LEVEL_SOURCE_MASTERCUE then
    	Param = CueVisible and Song:getCueLevelParameter() or Song:getLevelParameter()
        self.CachedCaptions[1] = CueVisible and "CUE" or "MASTER"

    elseif Source == NI.DATA.LEVEL_SOURCE_GROUP then
        local Group = NI.DATA.StateHelper.getFocusGroup(App)
        if Group then
            Param = Group:getLevelParameter()
        end
        self.CachedCaptions[1] = "GROUP"

    elseif Source == NI.DATA.LEVEL_SOURCE_SOUND then
        local Sound = NI.DATA.StateHelper.getFocusSound(App)
        if Sound then
            Param = Sound:getLevelParameter()
        end
        self.CachedCaptions[1] = "SOUND"

    end

    if Param then
        self.CachedFormattedValue = Param:getAsString(Param:getValue())
    end
end


------------------------------------------------------------------------------------------------------------------------
-- returns the recorder's input if the sampling pages are up, the sound input otherwise
function LevelMeterStudio:getStereoInputIndex()

    local StateCache = App:getStateCache()
    local Group = NI.DATA.StateHelper.getFocusGroup(App)
    local Sound = NI.DATA.StateHelper.getFocusSound(App)
    local SourceIn = nil

	if Group and Group:getSamplingVisibleParameter():getValue() then

		local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
		local SourceParam = Recorder:getRecordingSourceParameter()

        if Recorder and SourceParam:getValue() == NI.DATA.SOURCE_EXTERNAL_STEREO then
			SourceIn = Recorder:getExtStereoInputsParameter():getValue()

        elseif Recorder and SourceParam:getValue() == NI.DATA.SOURCE_EXTERNAL_MONO then
			SourceIn = math.floor(Recorder:getExtMonoInputsParameter():getValue() / 2)
		end
	else

		SourceIn = Sound and Sound:getInputParameter():getExternalSourceIndex()
	end

	return SourceIn

end

------------------------------------------------------------------------------------------------------------------------

function LevelMeterStudio:onTimer()

    local StateCache = App:getStateCache()
    local Song = NI.DATA.StateHelper.getFocusSong(App)
    local Group = NI.DATA.StateHelper.getFocusGroup(App)

    local CueVisible = App:getWorkspace():getMixerCueVisibleParameter():getValue()

    local LevelL = 0
    local LevelR = 0
    local SourceIn = self:getStereoInputIndex()

    local Source = App:getWorkspace():getHWLevelMeterSourceParameter():getValue()
    local SourceIsInput = Source == NI.DATA.LEVEL_SOURCE_INPUT

    if Song and Group then

        LEDHelper.setLEDState(NI.HW.LED_LEVEL_COLOR, Source == NI.DATA.LEVEL_SOURCE_INPUT and LEDHelper.LS_OFF or LEDHelper.LS_BRIGHT)

        if SourceIsInput then

            if SourceIn and SourceIn ~= NPOS then
                LevelL = NI.UTILS.LevelScale.convertLevelTodBNormalized(App:getInputLevel(SourceIn * 2), -60, 0)
                LevelR = NI.UTILS.LevelScale.convertLevelTodBNormalized(App:getInputLevel(SourceIn * 2 + 1), -60, 0)
            end

        elseif Source == NI.DATA.LEVEL_SOURCE_MASTERCUE then

            LevelL = NI.UTILS.LevelScale.convertLevelTodBNormalized(CueVisible and Song:getCueLevel(0) or Song:getLevel(0), -60, 0)
            LevelR = NI.UTILS.LevelScale.convertLevelTodBNormalized(CueVisible and Song:getCueLevel(1) or Song:getLevel(1), -60, 0)

        elseif Source == NI.DATA.LEVEL_SOURCE_GROUP then

            if Group then
                LevelL = NI.UTILS.LevelScale.convertLevelTodBNormalized(Group:getLevel(0), -60, 0)
                LevelR = NI.UTILS.LevelScale.convertLevelTodBNormalized(Group:getLevel(1), -60, 0)
            end

        elseif Source == NI.DATA.LEVEL_SOURCE_SOUND then

        	local Sound = NI.DATA.StateHelper.getFocusSound(App)
            if Sound then
                LevelL = NI.UTILS.LevelScale.convertLevelTodBNormalized(Sound:getLevel(0), -60, 0)
                LevelR = NI.UTILS.LevelScale.convertLevelTodBNormalized(Sound:getLevel(1), -60, 0)
            end

        end

        -- Update Button States

        -- outputs
        LEDHelper.setLEDState(NI.HW.LED_LEVEL_MASTER, Source == NI.DATA.LEVEL_SOURCE_MASTERCUE and not CueVisible and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_LEVEL_GROUP, Source == NI.DATA.LEVEL_SOURCE_GROUP and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_LEVEL_SOUND, Source == NI.DATA.LEVEL_SOURCE_SOUND and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_LEVEL_CUE, Source == NI.DATA.LEVEL_SOURCE_MASTERCUE and CueVisible and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)

        -- Display Recorder Input if Sampling Page is Visible
        if Group and Group:getSamplingVisibleParameter():getValue() then

            local Recorder = NI.DATA.StateHelper.getFocusRecorder(App)
            local SourceParam = Recorder:getRecordingSourceParameter()

            if Recorder and SourceParam:getValue() == NI.DATA.SOURCE_EXTERNAL_MONO then

                if SourceIsInput then
                    if Recorder:getExtMonoInputsParameter():getValue() % 2 == 0 then
                        LevelR = LevelL -- if Left, show Left on both
                    else
                        LevelL = LevelR -- if Right, show Right on both
                    end
                end
            end
        end

        local SourceInLED = SourceIsInput and LEDHelper.LS_BRIGHT or LEDHelper.LS_DIM
        LEDHelper.setLEDState(NI.HW.LED_LEVEL_IN1, SourceIn == 0 and SourceInLED or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_LEVEL_IN2, SourceIn == 1 and SourceInLED or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_LEVEL_IN3, SourceIn == 2 and SourceInLED or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(NI.HW.LED_LEVEL_IN4, SourceIn == 3 and SourceInLED or LEDHelper.LS_OFF)

    end

	LevelL = LevelL * 16
	LevelR = LevelR * 16

    for Index = 1, 16 do
        LEDHelper.setLEDState(self.Controller.LEVELMETER_LEFT_LEDS[Index], Index < LevelL and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
        LEDHelper.setLEDState(self.Controller.LEVELMETER_RIGHT_LEDS[Index], Index < LevelR and LEDHelper.LS_BRIGHT or LEDHelper.LS_OFF)
    end

end

------------------------------------------------------------------------------------------------------------------------
