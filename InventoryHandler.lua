--|| SERVICES ||--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

--|| DIRECTORIES ||--
local Assets = ReplicatedStorage.Assets
local Remotes = ReplicatedStorage.Remotes
local PrivateModules = ServerStorage.PrivateModules

--|| MODULES ||--
local Datastore = require(ServerScriptService.Datastore.Datastore)
local StandHandler = require(script.Parent.StandHandler)
local ItemFunctions = require(PrivateModules.ItemFunctions)
local Global = require(ReplicatedStorage.Global)



--|| REMOTES ||--
local requestFunctions = Remotes.requestInventoryFunctions

local function getItemFromName(Item, Inventory)
	local Data
	local i
	for i = 1, #Inventory do
		Data = Inventory[i]
		if Global.Compare(Data, Item) then
			return Data, i
		end
	end
end

requestFunctions.OnServerInvoke = function(Player, Data, Function)
	local Playerdata = Datastore:Get(Player.UserId)
	local ItemInfo, i = getItemFromName(Data, Playerdata.Inventory)
	if Function == "ItemEquip" then
		if ItemInfo then
			if ItemInfo.Quantity >= 1 then
				ItemInfo.Quantity  -= 1
				if ItemInfo.ItemType == "Stand" then
					if Player.States.StandSummoned then
						StandHandler.Unsummon(Player)
					end
					----------------------------------------
					if Playerdata.Stats.Stand then
						local OldStandInfo = Global.Copy(Playerdata.Stats.Stand)
						Playerdata.Inventory[#Playerdata.Inventory + 1] = {
							ItemName = OldStandInfo.Id,
							ItemType = "Stand",
							Quantity = 1,
							XP = OldStandInfo.Experience,
							MaxXP = OldStandInfo.MaxExperience,
							Level = OldStandInfo.Level,
							OverHeaven = OldStandInfo.OverHeaven,
							Requiem = OldStandInfo.Requiem,
						}
						table.remove(Playerdata.Inventory, #Playerdata.Inventory)
						Playerdata.Stats.Stand = {
							Id = ItemInfo.ItemName,
							Level = ItemInfo.Level,
							Experience = ItemInfo.XP,
							MaxExperience = ItemInfo.MaxXP,
							OverHeaven = ItemInfo.OverHeaven,
							Requiem = ItemInfo.Requiem,
						}
					else
						Playerdata.Stats.Stand = {
							Id = ItemInfo.ItemName,
							Level = ItemInfo.Level,
							Experience = ItemInfo.XP,
							MaxExperience = ItemInfo.MaxXP,
							OverHeaven = ItemInfo.OverHeaven,
							Requiem = ItemInfo.Requiem,
						}
					end	
				else
					ItemFunctions[ItemInfo.ItemName](Player, Playerdata)
				end
				----------------------------------------
				if ItemInfo.Quantity <= 0 then
					table.remove(Playerdata.Inventory, i)
				end
				return true, Playerdata
			end
			if ItemInfo.Quantity <= 0 then
				table.remove(Playerdata.Inventory, i)
			end
		end
		return false, Playerdata
	elseif Function == "ItemDestroy" then
		local ItemInfo = getItemFromName(Data, Playerdata.Inventory)
		if ItemInfo.Quantity >= 1 then
			ItemInfo.Quantity -= 1
		end
		if ItemInfo.Quantity <= 0 then
			table.remove(Playerdata.Inventory, i)
		end
		return true, Playerdata
	elseif Function == "StandUnequip" then
		if Playerdata.Stats.Stand.Id then
			local OldStandInfo = Playerdata.Stats.Stand
			Playerdata.Inventory[#Playerdata.Inventory + 1] = {
				ItemName = OldStandInfo.Id,
				ItemType = "Stand",
				Quantity = 1,
				XP = OldStandInfo.Experience,
				MaxXP = OldStandInfo.MaxExperience,
				Level = OldStandInfo.Level,
				OverHeaven = true,
				Requiem = OldStandInfo.Requiem,
			}
			Playerdata.Stats.Stand = {}
			return true, Playerdata
		end
	end
	return false, Playerdata
end










return{}
