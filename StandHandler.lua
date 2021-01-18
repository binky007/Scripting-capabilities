--|| Services ||--
local ReplicatedStorage = game.ReplicatedStorage
local ServerStorage = game.ServerStorage

--|| Modules ||--
local Shared = require(ReplicatedStorage.Shared)

local module = {}
module.__index = module

--|| REMOTES ||--
local Visuals = ReplicatedStorage.Remotes.Visuals

--| Private Functions


--| Public Functions
function module.new(Player, StandData)
	local Data = {}
	
	local GlobalStandData = Shared.Stands[StandData.Id]
	if not GlobalStandData then warn(script:GetFullName()..": StandData Id ("..StandData.Id..")'s Data was unable to be located.") return end
	local Stand, StandType = nil, GlobalStandData.Type
	
	if StandType == "Humanoid" then
		Stand = ServerStorage.Assets["Preset Models"].HumanoidModel:Clone()
		Stand.Name = "Stand"
		
		local StandAssets = ServerStorage.Assets["Stand Assets"][StandData.Id]:Clone()
		for _, Asset in ipairs(StandAssets:GetChildren()) do
			
			local Folder = Instance.new("Folder")
			Folder.Name = "Original"
			Folder.Parent = Stand[Asset.Name]
			
			Asset:SetPrimaryPartCFrame(Stand[Asset.Name].CFrame)
			Stand[Asset.Name].Transparency = 1
			for _, Child in ipairs(Asset:GetChildren()) do
				
				Child.Massless = true
				Child.Anchored = false
				Child.CanCollide = false

				local WeldConstraint = Instance.new("WeldConstraint")
				WeldConstraint.Part0 = Stand[Asset.Name]
				WeldConstraint.Part1 = Child
				WeldConstraint.Name = Child.Name..":"..Asset.Name.."Constraint"
				WeldConstraint.Parent = Child
				
				Child.Parent = Stand
			end
			Asset:Destroy()
		end
		
		StandAssets:Destroy()
		Stand:SetPrimaryPartCFrame(Player.Character.HumanoidRootPart.CFrame)
		Stand.Parent = Player.Character
		
		local Weld = Instance.new("Weld")
		Weld.Part0 = Player.Character.HumanoidRootPart
		Weld.Part1 = Stand.HumanoidRootPart
		Weld.Parent = Stand.HumanoidRootPart
		
		Stand.PrimaryPart:SetNetworkOwner(Player)
		
		Data.Animations = {}
		for _, Animation in ipairs(ReplicatedStorage.Shared.Stands[StandData.Id]:GetChildren()) do
			if Animation:IsA("Animation") then
				Data.Animations[Animation.Name] = Stand.AnimationController:LoadAnimation(Animation)
			end
		end
	end
	
	Data.Model = Stand
	return setmetatable(Data, module)
end

function module.Summon(Player, Stand, StandName)	
	local EndC1 = CFrame.new(-2,-1.5,-1.5)
	local Duration = 0.5
	
	Visuals:FireAllClients("Humanoid Stand Summon", {
		Weld = Stand.Model.HumanoidRootPart.Weld,
		Duration = Duration,
		Stand = Stand.Model,
		StandName = StandName,
		C1 = EndC1,
	})
	
	wait(Duration)
	
	Stand.Model.HumanoidRootPart.Weld.C1 = EndC1
end

function module.Unsummon(Player, Stand)
	Player.States.StandSummoned.Value = false -- Reset
	if Stand then
		local EndC1 = CFrame.new(0,0,0)
		local Duration = 0.5
		Visuals:FireAllClients("Humanoid Stand Unsummon", {
			Weld = Stand.HumanoidRootPart.Weld,
			Duration = Duration,
			Stand = Stand,
			C1 = EndC1,
		})

		wait(Duration)

		Stand.HumanoidRootPart.Weld.C1 = EndC1
		Stand:Destroy()
	end

	
end

function module:Attack()
	
end

return module
