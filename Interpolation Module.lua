local Styles = require(script.EasingStyles)
local RunService = game:GetService("RunService")
local LerpMethods = {}
local Lerps = {}
local InactiveLerps = {}
LerpMethods.__index = LerpMethods

function LerpMethods.New(Part, Time, EasingStyle, Direction,StartVal, EndPos,Property, Callback)
	local Data = {}
	setmetatable(Data, LerpMethods)
	
	Data.Time = Time
	Data.Progress = 0
	Data.EasingStyle = EasingStyle or "Linear"
	Data.Direction = Direction or "Out"
	Data.Start = StartVal or Part.Position
	Data.EndPos = EndPos
	Data.Property = Property  or "Position"
	Data.Part = Part
	InactiveLerps[Part] = Data
	
	return Data
end

function LerpMethods:Destroy()
	self:Destroy()
end

function LerpMethods:Play()
	Lerps[self.Part] = self
	InactiveLerps[self.Part] = nil
end

function LerpMethods:Pause()
	InactiveLerps[self.Part] = self
	Lerps[self.Part] = nil
end

coroutine.wrap(function()
	while true do
		for Part, Data in pairs(Lerps) do
			if Data.Progress <=1 then
				Data.Progress += ((1/60)/Data.Time)
				Part[Data.Property] = Styles[Data.EasingStyle](Data.Start, Data.EndPos, Data.Progress, Data.Direction)
			else
				Data:Pause()
			end
		end
		RunService.Stepped:Wait()
	end
end)()





return LerpMethods
