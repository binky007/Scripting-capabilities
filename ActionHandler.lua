--|| Services ||--
local Players = game.Players
local ReplicatedStorage = game.ReplicatedStorage
local ServerScriptService = game.ServerScriptService

--|| Remotes ||--
local Execute = ReplicatedStorage.Remotes.Execute
local Visuals = ReplicatedStorage.Remotes.Visuals

--|| Modules ||--
local StandHandler = require(ServerScriptService.Server.StandHandler)
local CooldownHandler = require(ServerScriptService.Server.Cooldown)
local Datastore = require(ServerScriptService.Datastore.Datastore)
local StandHandler = require(ServerScriptService.Server.StandHandler)
local Shared = require(ReplicatedStorage.Shared)
local DamageAPI = require(ServerScriptService.Server.Damage)

--| Private Variables
local DebugProperty = true
local DataLogs = {}
local StandModules = {}

for _, Folder in ipairs(script.Stands:GetChildren()) do
	StandModules[Folder.Name] = {}
	for _, Ability in ipairs(Folder:GetChildren()) do
		StandModules[Folder.Name][Ability.Name] = require(Ability)
	end
end

--| Private Functions
local function IsAlive(Character)
	if Character and Character:FindFirstChild"HumanoidRootPart" and Character:FindFirstChild"Humanoid"
		and Character:IsDescendantOf(game.Workspace) and Character.Humanoid.Health > 0 then
		return true
	end
end

local function Debug(Msg)
	if DebugProperty then
		warn(script:GetFullName()..": "..Msg)
	end	
end

local StandSummoning = {
	["Humanoid Stand Summon"] = function(Player)
		if not Player.States.StandSummoned.Value then
			for ConnectionId, Connection in next, DataLogs[Player].Connections do
				Connection:Disconnect()
			end
			DataLogs[Player].Connections = {}
			local PlayerData = Datastore:Get(Player.UserId)
			local NewStand = StandHandler.new(Player, PlayerData.Stats.Stand)
			Player.States.StandSummoned.Value = true
			
			DataLogs[Player].Stand = NewStand
			
			StandHandler.Summon(Player, NewStand, PlayerData.Stats.Stand.Id)
			
			NewStand.Animations.Idle:Play()
			
			DataLogs[Player].Stand = NewStand
		elseif Player.States.StandSummoned.Value then
			Player.States.StandSummoned.Value = false
			local Stand = Player.Character:FindFirstChild"Stand"
			if Stand then
				StandHandler.Unsummon(Player, Stand)
			end
			
		end
	end,
}

Execute.OnServerEvent:Connect(function(Player, Input)
	if not IsAlive(Player.Character) then Debug(Player.Name.."'s Character is not alive") return end
	local PlayerData = Datastore:Get(Player.UserId)
	if not PlayerData then Debug(Player.Name.."'s PlayerData could not be retrieved.") return end
	
	if Input == "Stand Summon" then
		local StandAbilityData = Shared.Stands[PlayerData.Stats.Stand.Id]	
		if not StandAbilityData then return end
		local OnCooldown = CooldownHandler:OnCooldown(Player, Input, StandAbilityData.Skills[Input].Cooldown)
		if not OnCooldown and not Player.States.Casting.Value then
			Player.States.Casting.Value = true
			
			local StandType = StandAbilityData.Type
			StandSummoning[StandType.." "..Input](Player)
			CooldownHandler:SetCooldown(Player, Input, os.clock())
			Player.States.Casting.Value = false	
			
		end
	else
		local StandId = PlayerData.Stats.Stand.Id
		local StandData = Shared.Stands[StandId]
		local AbilityData = StandId and StandData.Skills[Input]
		
		if AbilityData and not Player.States.Stopped.Value then
			local Holdable = AbilityData.Holdable
			local AbilityIsHeld = (Holdable
				and Player.States.Casting.Value
				and Player.States[AbilityData.Id].Value
			)
			local OnCooldown = CooldownHandler:OnCooldown(Player, Input, AbilityData.Cooldown)
			
			if Holdable and AbilityIsHeld then
				StandModules[StandId][AbilityData.Id](Player, DataLogs[Player].Stand, AbilityData, DamageAPI)
				CooldownHandler:SetCooldown(Player, Input, os.clock())
			elseif not Holdable and not Player.States.Casting.Value and not OnCooldown then				
				Player.States.Casting.Value = true
				if AbilityData and AbilityData.Id then
					StandModules[StandId][AbilityData.Id](Player, DataLogs[Player].Stand, AbilityData, DamageAPI)
				end
				CooldownHandler:SetCooldown(Player, Input, os.clock())
				Player.States.Casting.Value = false
			elseif Holdable and not AbilityIsHeld and not Player.States.Casting.Value and not OnCooldown then				
				Player.States.Casting.Value = true
				StandModules[StandId][AbilityData.Id](Player, DataLogs[Player].Stand, AbilityData, DamageAPI)
				Player.States.Casting.Value = false
			end
		end
	end
end)

Visuals.OnServerEvent:Connect(function(Player, Task)
	local Stand = DataLogs[Player].Stand
	if Task == "Humanoid Stand Movement" then
		if not Stand.Animations.Move.IsPlaying then
			Stand.Animations.Move:Play()
		end
	elseif Task == "Humanoid Stand Movement Stopped" then
		Stand.Animations.Move:Stop()
	end
end)

Players.PlayerAdded:Connect(function(Player)
	DataLogs[Player] = {
		Connections = {},
		Stand = nil,
	}
end)

Players.PlayerRemoving:Connect(function(Player)
	DataLogs[Player] = nil
end)

return StandSummoning
