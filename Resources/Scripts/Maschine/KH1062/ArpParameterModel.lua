local class = require 'Scripts/Shared/Helpers/classy'
ArpParameterModel = class( 'ArpParameterModel' )

------------------------------------------------------------------------------------------------------------------------

function ArpParameterModel:__init(isFocusGroupDrumKitModeEnabled)

    if type(isFocusGroupDrumKitModeEnabled) ~= "function" then
        error("isFocusGroupDrumKitModeEnabled callback not defined")
    end

    self.Pages = {
        {
            Name = "Main",
            getParameters = function ()
                local Arpeggiator = NI.DATA.getArpeggiator(App)
                local IsKeyboardMode = not isFocusGroupDrumKitModeEnabled()
                return Arpeggiator and {
                    {
                        SectionName = "Main",
                        DisplayName = "Preset",
                        Parameter = NI.DATA.getArpeggiatorPresetParameter(App),
                        getDisplayValue = function (Parameter)
                            return Parameter:getValue()
                        end
                    },
                    { Parameter = IsKeyboardMode and Arpeggiator:getTypeParameter() or nil },
                    {
                        SectionName = "Rhythm",
                        Parameter = NI.DATA.getArpeggiatorRateParameter(App)
                    },
                    {
                        SectionName = "Other",
                        Parameter = NI.DATA.getArpeggiatorRateUnitParameter(App)
                    },
                    { Parameter = IsKeyboardMode and Arpeggiator:getSequenceParameter() or nil },
                    { Parameter = IsKeyboardMode and Arpeggiator:getOctavesParameter() or nil },
                    { Parameter = IsKeyboardMode and Arpeggiator:getDynamicParameter() or nil },
                    { Parameter = Arpeggiator:getGateParameter() }
                } or {}
            end
        },
        {
            Name = "Hold",
            getParameters = function ()
                local Arpeggiator = NI.DATA.getArpeggiator(App)
                return Arpeggiator and {
                    {
                        DisplayName = "On / Off",
                        Parameter = Arpeggiator:getHoldParameter()
                    }
                } or {}
            end
        }
    }
    self.CurrentPageIndex = 1

end

------------------------------------------------------------------------------------------------------------------------

function ArpParameterModel:getFocusParameters()

    return self.Pages[self.CurrentPageIndex].getParameters()

end

------------------------------------------------------------------------------------------------------------------------

function ArpParameterModel:getFocusPageName()

    return self.Pages[self.CurrentPageIndex].Name

end

------------------------------------------------------------------------------------------------------------------------

function ArpParameterModel:getFocusPageNumber()

    return self.CurrentPageIndex

end

------------------------------------------------------------------------------------------------------------------------

function ArpParameterModel:getFocusPageCount()

    return #self.Pages

end
