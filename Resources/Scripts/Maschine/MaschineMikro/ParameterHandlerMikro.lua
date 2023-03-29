------------------------------------------------------------------------------------------------------------------------

local class = require 'Scripts/Shared/Helpers/classy'
ParameterHandlerMikro = class( 'ParameterHandlerMikro' )

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:__init(NameLabel, ValueLabel)

    -- widgets for name / value
    self:setLabels(NameLabel, ValueLabel)

    -- list of parameters, names and values
    self.Parameters = {}
    self.CustomNames = {}
    self.CustomValues = {}

    -- selected parameter index
    self.ParameterIndex = 1

    -- global undo flag (assuming undo properties being the same for one page)
    self.Undoable = true

    -- extend the parameter names with the section name
    self.ExtendParameterNames = false

    -- set this functor to anything you want for custom parameter updates,
    -- otherwise the updateDefault() function implemented in this class will be used.
    self.UpdateFunctor = nil

    -- set default update function
    self:resetUpdateFunctor()

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:setParameterIndexChangedFunc(Func)

	self.ParameterIndexChangedFunc = Func

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:setParameters(Parameters, Undoable, CustomValues, CustomNames)

    self.Parameters = Parameters

    if CustomValues then
        self.CustomValues = CustomValues

    else
        self.CustomValues = {}

    end

    if CustomNames then
        self.CustomNames = CustomNames

    else
        self.CustomNames = {}

    end

    -- undo flag
    self.Undoable = Undoable

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:resetUpdateFunctor()

    self.UpdateFunctor = function(ForceUpdate)
        self:updateDefault(ForceUpdate)
    end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:setLabels(NameLabel, ValueLabel)

    -- widgets for name / value
    self.ParamNameLabel  = NameLabel
    self.ParamValueLabel = ValueLabel

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:update(ForceUpdate)

    if self.UpdateFunctor then
		self.UpdateFunctor(ForceUpdate, self.ParamNameLabel, self.ParamValueLabel)
	end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:updateParameterNameValue()

    local Name = ""
	local Value = ""

	local Parameter = self.Parameters[self.ParameterIndex]
	local ActualParameter = NI.DATA.ParameterCache.getActualParameter(Parameter)
	if Parameter and ActualParameter then

        local ParamPrefix = self.ExtendParameterNames and #(ActualParameter:getSectionName()) > 0
            and ActualParameter:getSectionName().." " or ""

        local DisplayName = Parameter:getDisplayName()
        local ParamName = DisplayName == "" and Parameter:getParameterInterface():getName() or DisplayName

        if self.CustomNames[self.ParameterIndex] then
            ParamName = self.CustomNames[self.ParameterIndex]

        end

		Name = self.ParameterIndex .. "/" ..#self.Parameters .. ": ".. ParamPrefix .. ParamName

        local IsAutoWriting = MaschineHelper.isAutoWriting()

        if self.CustomValues[self.ParameterIndex] then
            Value = self.CustomValues[self.ParameterIndex]
        elseif ActualParameter:isAutomatable() or not IsAutoWriting then
            Value = NI.GUI.ParameterWidgetHelper.getValueString(ActualParameter, IsAutoWriting)
        end

    else

        local ParamCache = App:getStateCache():getParameterCache()
        local NumPages   = ParamCache:getNumPagesOfFocusParameterOwner()
        if NumPages > 0 then
            Name = "NO PARAMETERS"
        end

	end

    if self.ParamNameLabel then
		self.ParamNameLabel:setText(Name)
	end

	if self.ParamValueLabel then
		self.ParamValueLabel:setText(Value)
	end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:updateDefault(ForceUpdate)

    self.ParameterIndex = math.bound(self.ParameterIndex, 1, #self.Parameters)

    self:updateParameterNameValue()

	if self.ParameterIndexChangedFunc then
		self.ParameterIndexChangedFunc(self.ParameterIndex)
	end

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:setParameterIndex(Index)

	self.ParameterIndex = math.bound(Index, 1, #self.Parameters)

	if self.ParameterIndexChangedFunc then
		self.ParameterIndexChangedFunc(self.ParameterIndex)
	end

	self:update(false)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:increaseParameter(Increment)

    if #self.Parameters > 0 then

        self:setParameterIndex(math.bound(self.ParameterIndex + Increment, 1, #self.Parameters))
	end

end

------------------------------------------------------------------------------------------------------------------------
-- onWheel: This is not finalized, and there are workarounds with the enums that will be removed.
------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:onWheel(Value, FineResolution)

    local Param = self.Parameters[self.ParameterIndex]

 	if Param then
        NI.DATA.ParameterAccess.addParameterWheelDelta(App, Param, Value, FineResolution, self.Undoable)
	end

	return Param ~= nil

end

------------------------------------------------------------------------------------------------------------------------
-- Helper for syncing FocusParameter with ParameterIndex
------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:syncFocusParameter()

    NI.DATA.ParameterPageAccess.setFocusParameterIndex(App, self.ParameterIndex - 1)

end

------------------------------------------------------------------------------------------------------------------------

function ParameterHandlerMikro:syncParameterIndex()

    local ParamCache = App:getStateCache():getParameterCache()
    local FocusParam = ParamCache:getFocusParameter()
    self.ParameterIndex = FocusParam and FocusParam:getValue() + 1 or 1

end

------------------------------------------------------------------------------------------------------------------------
