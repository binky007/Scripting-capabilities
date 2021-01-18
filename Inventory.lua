--//SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game.ReplicatedStorage
local ReplicatedFirst = game.ReplicatedFirst

--//VARIABLES
local Player = Players.LocalPlayer
local Items = ReplicatedStorage.Assets.Items

--//REMOTES
local getData = ReplicatedStorage:WaitForChild("getData")
local Execute = ReplicatedStorage.Remotes.Execute
local requestInventoryFunctions = ReplicatedStorage.Remotes.requestInventoryFunctions

--//MODULES
local Global = require(ReplicatedStorage.Global)
local Shared = require(ReplicatedStorage.Shared)
local module = {}

--//DATA
local PlayerData = getData:InvokeServer()
Inventory = PlayerData.Inventory

--//UI ELEMENTS
local PlayerGui = Player.PlayerGui
local MainGui = PlayerGui:WaitForChild("MainGui").Background
local EquippedFrame = MainGui.Equipped
local DisplayFrame = MainGui.Display
local InventoryFrame = MainGui.Inventory
local StatsFrame = MainGui.Stats
local InventoryList = InventoryFrame.List
local StatsList = StatsFrame.List
local OpenEffect = PlayerGui.MainGui.OpenEffect
local DislayModel, DisplayItem
local StandModel

--// UI STATUSES
local Opened = MainGui.Opened
local OnCooldown = false


--//FUNCTIONS
local function updatePlayerData()
	return getData:InvokeServer(), Inventory
end

local function wipeEffect()
	OnCooldown = true
	OpenEffect.Visible = true
	OpenEffect:TweenSize(UDim2.fromScale(.5,.6), Enum.EasingDirection.Out,Enum.EasingStyle.Sine, .4, true)
	wait(.6)
	OpenEffect:TweenSize(UDim2.fromScale(.5,0), Enum.EasingDirection.Out,Enum.EasingStyle.Sine, .4, true)
	wait(.4)
	OnCooldown = false
	OpenEffect.Visible = false
end

local function openInventory()
	OnCooldown = true
	OpenEffect:TweenPosition(UDim2.fromScale(.5,.5), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, .5, true)
	wait(.5)
	OpenEffect:TweenSize(UDim2.fromScale(.5,.6), Enum.EasingDirection.Out,Enum.EasingStyle.Sine, .5, true)
	wait(.5)
	MainGui.Visible = true
	OpenEffect:TweenSize(UDim2.fromScale(.5, 0), Enum.EasingDirection.Out,Enum.EasingStyle.Sine, .5, true)
	wait(.5)
	OpenEffect.Visible = false
	OnCooldown = false
end

local function closeInventory()
	OnCooldown = true
	OpenEffect.Visible = true
	OpenEffect:TweenSize(UDim2.fromScale(.5,.6), Enum.EasingDirection.In,Enum.EasingStyle.Sine, .5, true)
	wait(.5)
	MainGui.Visible = false
	OpenEffect:TweenSize(UDim2.fromScale(.01,.6), Enum.EasingDirection.Out,Enum.EasingStyle.Sine, .5, true)
	wait(.5)
	OpenEffect:TweenPosition(UDim2.fromScale(.5,1.5), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, .5, true)
	wait(.5)
	OnCooldown = false
	------------------------
end

local function clearInventoryList(f)
	for _, frame in ipairs(f:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end
end

local function updateDisplayFrame(Item)
	if Item.ItemType == "Stand" then
		DisplayFrame.Descbox.Description.Text = Shared.ItemData[Item.ItemType].Description
	else
		if Shared.ItemData[Item.ItemName] then
			DisplayFrame.Descbox.Description.Text = Shared.ItemData[Item.ItemName].Description
		else
			DisplayFrame.Descbox.Description.Text = "Corrupt Item - Message 'binkuisu#4483' on discord"
		end
	end
	DisplayFrame.iname.Text = Item.ItemName
	if DislayModel then
		DislayModel.Visible = false
		DislayModel:SetActive(false)
		DislayModel:End()
	end
	DisplayItem = Item
	DislayModel = Global.Module3D:Attach3D(DisplayFrame.ViewportFrame, Items[Item.ItemName]:Clone())
	DislayModel:SetCFrame(CFrame.Angles(0,math.rad(-90),0))
	DislayModel.Visible = true
end

local function updateStatsFrame(f, id)
	local Connection
	f.btn.MouseEnter:Connect(function()
		StatsList["name"].Text = "NAME: "..string.upper(tostring(id.ItemName))
		StatsList["type"].Text = "TYPE: "..string.upper(tostring(id.ItemType))
		if id.ItemType == "Stand" then
			StatsList["exp"].Text = "XP: "..string.upper(tostring(id.XP))
			StatsList["overheaven"].Text = "OVERHEAVEN: "..string.upper(tostring(id.OverHeaven))
			StatsList["level"].Text = "LEVEL: "..string.upper(tostring(id.Level))		
			StatsList["requiem"].Text = "REQUIEM: "..string.upper(tostring(id.Requiem))	
		end
		Connection = f.btn.Activated:Connect(function()
			updateDisplayFrame(id)
		end)
	end)
	
	f.btn.MouseLeave:Connect(function()
		StatsList["name"].Text = "NAME: N/A"
		StatsList["type"].Text = "TYPE: N/A"
		StatsList["exp"].Text = "XP: N/A"
		StatsList["overheaven"].Text = "OVERHEAVEN: N/A"
		StatsList["level"].Text = "LEVEL: N/A"
		StatsList["requiem"].Text = "REQUIEM: N/A"
		Connection:Disconnect()
	end)
end

local function newItemAdded(item, inv)
	local template = ReplicatedFirst.UI.TemplateIcon:Clone()
	template.Name = item.ItemName
	template.quantity.Text = 'x'..inv.Quantity
	template.Parent = InventoryList
	local Model = Global.Module3D:Attach3D(template.itemdisplay, Items[item.ItemName]:Clone())
	Model:SetCFrame(CFrame.Angles(0,math.rad(-90),0))
	Model.Visible = true
	
	updateStatsFrame(template, inv)
end

local function updateInventory(inv)
	coroutine.wrap(function()
		wipeEffect()
	end)()
	wait(.4)
	clearInventoryList(InventoryList)
	for _, item in next, inv do
		newItemAdded(item, item)
	end	
end

local function updateEquippedFrame(Stand)
	if Stand.Id then
		EquippedFrame["sname"].Text = "NAME: " .. Stand.Id
		EquippedFrame["type"].Text = "TYPE: Stand"
		EquippedFrame.ExperienceBar["ExpText"].Text = "XP: " .. Stand.Experience
		EquippedFrame["overheaven"].Text = "OVERHEAVEN: " .. tostring(Stand.OverHeaven)
		EquippedFrame["level"].Text = "LEVEL: " .. Stand.Level
		EquippedFrame["requiem"].Text = "REQUIEM: " .. tostring(Stand.Requiem)
		if StandModel then
			StandModel.Visible = false
			StandModel:SetActive(false)
			StandModel:End()
		end
		local Model = Global.Module3D:Attach3D(EquippedFrame.ViewportFrame, Items[Stand.Id]:Clone())
		Model:SetCFrame(CFrame.Angles(0,math.rad(-90),0))
		Model.Visible = true
		Model:SetActive(true)
		StandModel = Model
	else
		if StandModel then
			StandModel.Visible = false
			StandModel:SetActive(false)
			StandModel:End()
		end
	end
end

local Inventory = PlayerData.Inventory
updateInventory(Inventory)
updateEquippedFrame(Global.TableAddons.InstanceToTable(Player.Stats.Stand, {}))



local function requestAction(Item, Action)
	if table.find(Inventory, DisplayItem) then -- Table to search, value to find
		local suc, NewPlayerdata = requestInventoryFunctions:InvokeServer(DisplayItem, Action)
		print(suc)
		if suc then
			PlayerData = NewPlayerdata
			Inventory = NewPlayerdata.Inventory
			updateInventory(NewPlayerdata.Inventory)
			updateEquippedFrame(NewPlayerdata.Stats.Stand)
		else
			updateInventory(NewPlayerdata.Inventory)
		end
	end
end

DisplayFrame.Selection.Equip.Activated:Connect(function()
	requestAction(DisplayItem, "ItemEquip")
end)

DisplayFrame.Selection.Delete.Activated:Connect(function()
	requestAction(DisplayItem, "ItemDestroy")
end)

EquippedFrame.Selection.Unequip.Activated:Connect(function()
	local suc, NewPlayerdata = requestInventoryFunctions:InvokeServer("", "StandUnequip")
	if suc then
		PlayerData = NewPlayerdata
		Inventory = NewPlayerdata.Inventory
		updateInventory(NewPlayerdata.Inventory)
		updateEquippedFrame(PlayerData.Stats.Stand)
	end
end)

UserInputService.InputBegan:Connect(function(Input, Processed)
	if Processed then return end
	local Settings = PlayerData.UISettings
	for Index, Key in next, Settings do
		
		if Input.KeyCode == Enum.KeyCode[Key] and not OnCooldown then
			if not Opened.Value then
				openInventory()
			else
				closeInventory()
			end
			Opened.Value =  not Opened.Value
		end
	end
end)

return module
