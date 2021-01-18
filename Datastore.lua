--|| Services ||--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--|| Directories ||--
local Modules = ReplicatedStorage.Modules
local Remotes = ReplicatedStorage.Remotes


--|| Modules ||--
local NetworkStream = require(Modules.NetworkStream)
local Properties = require(script.Properties)

local StartingData = require(script.StartingData)
local ItemData = require(Modules.ItemData)

--|| Remotes ||--
local GetData = Remotes.GetData
local Replicater = Remotes.Replicate

--|| Variables ||--
local DataStore = DataStoreService:GetDataStore(Properties.DataStoreName .. Properties.Version)

local PlayerData = {}

--|| Private Functions ||--

function Retry(Player, DataFunction, ...)
	local Succ, Err, Attempts, Data = false, nil, 0, nil
	local Args = {...}
	
	while Attempts < Properties.MaxTries and not Succ do
		Succ, Err = pcall(function()
			Data = DataFunction(Player, unpack(Args))
		end)
		
		if Succ then
			print("[DataStore]: Successful Retry For ".. Player.Name)
		else
			print("[DataStore]: Unsuccessful Retry For ".. Player.Name)
			wait(Properties.RetryTimer)
		end
	end
	return Data
end

function Save(Player, Data)
	--DataStore:SetAsync(Player.UserId, Data)
	DataStore:UpdateAsync(Player.UserId, function(OldValue)
		local oldData = OldValue or {DataId = 0}
		if Data.DataId == oldData.DataId then
			Data.DataId += 1
			return Data
		else
			return nil
		end
	end)
end

function Get(Player)
	local Data = DataStore:GetAsync(Player.UserId)
	return Data
end

function DictionaryLoop(Dictionary)
	local Counter = 0
	for _,_ in pairs(Dictionary) do
		Counter =  Counter + 1
	end
	return Counter
end
function GetPlayerData(Player)
	while PlayerData[Player] == nil or PlayerData[Player].Data == nil do
		warn("Waiting for ".. Player.Name.. "'s Data to load")
		wait()
	end
	return PlayerData[Player].Data
end

function Replicate(Player)
	local Data = GetPlayerData(Player)
	Replicater:FireClient(Player, Data)
end

--|| Module ||--

local Module = {}

function Module:GetPlayerData(Player)
	return GetPlayerData(Player)
end


function Module:SetData(Player,Branch,TableValue,NewValue,Request) -- (Player : string, Branch: table| string, TableValue = string | nil, NewValue = string | number)
	local IndexedData = GetPlayerData(Player)
	
	local IndexedBranch = IndexedData[Branch]
	
	if type(IndexedBranch) == "table" then
		local Iterator = (ipairs(IndexedBranch) == 0 and pairs) or ipairs
		IndexedBranch = IndexedBranch[TableValue] or warn(("No valid category for %s"):format(TableValue))
		
		local IndexedItemData = ItemData[NewValue] or warn(("Unable to find %s in ItemData"):format(NewValue))
		local StackData =  IndexedItemData.StackData
		
		if IndexedBranch[NewValue] == nil then
			IndexedBranch[NewValue] = {
				Name =  string.gsub(NewValue, "%s", ""),
				Amount = 1,   
			}
			print(("created new index in Table : %s" ):format(NewValue))
		else
			for Index,OldValue in pairs(IndexedBranch) do
				if StackData.Stackable then
					if (OldValue.Name == ItemData.Name) and (OldValue.Amount < StackData.MaxStack) then
						OldValue.Amount = OldValue.Amount + 1
						print(("added amount to table : %s " ):format(tostring(OldValue.Amount)))
					end
				end
			end
		end
	else
		IndexedBranch = NewValue
		print(("changed old value : %s to new value : %s"):format(IndexedBranch,NewValue))
	end
	
end
--function Module:SetData(Player, Branch, Value, NewValue)
--	local Data = GetPlayerData(Player)
	
--	local BranchValue = Data[Branch][Value]
	
--	if (BranchValue == NewValue) then return end
	
--	if BranchValue == nil then
--		Data[Value] = NewValue
--	else
--		BranchValue = NewValue
--	end
	
--	Replicate(Player)
--end

function Module:Replicate(Player)
	Replicate(Player)
end

function Module:NewPlayer(Player)
	if PlayerData[Player] then return end
	PlayerData[Player] = {}
	
	if Properties.Testing then
		PlayerData[Player].Data = StartingData
	else
		local Data = Retry(Player, Get)
		
		if Data then
			PlayerData[Player].Data = Data
		else
			PlayerData[Player].Data = StartingData
			warn(Player.Name.. " had no data so set it to starting data")
		end
		
	end
	Replicate(Player)
end

Players.PlayerAdded:Connect(function(Player)
	Module:NewPlayer(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
	Retry(Player, Save, GetPlayerData(Player))
	PlayerData[Player]= nil
end)

local List = Players:GetPlayers()
for i = 1, #List do
	local Player = List[i]
	if not PlayerData[Player] then
		coroutine.resume(coroutine.create(function()
			Retry(Player, Get)
		end))
	end
end

game:BindToClose(function()
	if RunService:IsStudio() and not Properties.StudioSave or Properties.Testing then return end
	local List = Players:GetPlayers()
	for i =1, #List do
		local Player = List[i]
		Retry(Player, Save, GetPlayerData(Player))
	end
end)

return Module
