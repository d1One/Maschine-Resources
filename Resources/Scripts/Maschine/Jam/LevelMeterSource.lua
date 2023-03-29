------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
LevelMeterSource = class( 'LevelMeterSource' )

------------------------------------------------------------------------------------------------------------------------

function LevelMeterSource.master()

    return function()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        return Song and Song:getLevel(0), Song:getLevel(1) or 0, 0
    end

end

function LevelMeterSource.group(Group)

    return function()
        return Group:getLevel(0), Group:getLevel(1)
    end

end

function LevelMeterSource.cue()

    return function()
        local Song = NI.DATA.StateHelper.getFocusSong(App)
        return Song and Song:getCueLevel(0), Song:getCueLevel(1) or 0, 0
    end

end

function LevelMeterSource.extInStereo(Index)

    return function()
        return App:getInputLevel(2*Index), App:getInputLevel(2*Index + 1)
    end

end

function LevelMeterSource.extInMono(Index)

    return function()
        return App:getInputLevel(Index), App:getInputLevel(Index)
    end

end

function LevelMeterSource.none()

    return function()
        return 0, 0
    end

end

function LevelMeterSource.fromRecorderInput(Recorder)

    local Source = Recorder:getRecordingSourceParameter():getValue()

    if Source == NI.DATA.SOURCE_INTERNAL and NI.DATA.RecorderAlgorithms.isInputMaster(Recorder) then

        return LevelMeterSource.master()

    elseif Source == NI.DATA.SOURCE_INTERNAL and NI.DATA.RecorderAlgorithms.isInputGroup(Recorder) then

        local Group = NI.DATA.RecorderAlgorithms.getInternalInputGroup(Recorder)
        if Group then
            return LevelMeterSource.group(Group)
        end

    elseif Source == NI.DATA.SOURCE_EXTERNAL_STEREO then

        local Input = Recorder:getExtStereoInputsParameter():getValue()
        return LevelMeterSource.extInStereo(Input)


    elseif Source == NI.DATA.SOURCE_EXTERNAL_MONO then

        local Input = Recorder:getExtMonoInputsParameter():getValue()
        return LevelMeterSource.extInMono(Input)

    end

    return LevelMeterSource.none()

end

------------------------------------------------------------------------------------------------------------------------
