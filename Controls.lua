--//SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game.ReplicatedStorage

--//VARIABLES
local OriginalInputTypes = {
	["MB1"] = "MouseButton1"
}
local Player = Players.LocalPlayer
local States = Player:WaitForChild"States"

--//REMOTES
local getData = ReplicatedStorage:WaitForChild("getData")
local Execute = ReplicatedStorage.Remotes.Execute

--//MODULES
local Shared = require(ReplicatedStorage.Shared)
local module = {}

--//FUNCTIONS
UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
	if GameProcessedEvent then return end
	local PlayerData = getData:InvokeServer()
	local Settings = PlayerData.Settings
	for Index, Key in next, Settings do
		local DetectedInput = (Input.UserInputType.Name == (OriginalInputTypes[Key] or Key)) or (Input.KeyCode.Name == (OriginalInputTypes[Key] or Key))
		if DetectedInput then
			if States.StandSummoned.Value then
				local Stand = PlayerData.Stats.Stand.Id
				local Data = Shared.Stands[Stand].Skills[Index]
				if Data then
					if Data.Holdable then
						Execute:FireServer(Index)
						local Start = os.clock()
						while (UserInputService:IsKeyDown(Input.KeyCode) or Input.UserInputType.Name == OriginalInputTypes[Key] and UserInputService:IsMouseButtonPressed(Input.UserInputType)) do
							RunService.Stepped:Wait()
						end
						if Player.States[Data.Id].Value then
							Execute:FireServer(Index)
						end
					else
						Execute:FireServer(Index)
					end
				end
			else
				--| This is if the staand isn't summoned
				Execute:FireServer(Index)
			end
			break
		end
	end
end)

return module
