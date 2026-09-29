-- Ride A Pet | Main (logic) - GUI separated into RideAPetGUI.lua

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Replace the URL below with your own RideAPetGUI.lua raw URL
-- (e.g. raw.githubusercontent.com/USERNAME/REPO/main/RideAPetGUI.lua)
local GUI_URL = "https://raw.githubusercontent.com/ZhangCy27/Ride-A-Pet/refs/heads/main/GUI/RideAPetGUI.lua"
local UIModule = loadstring(game:HttpGet(GUI_URL))()
local Hub = UIModule.CreateWindow('Ride A <font color="rgb(65,135,255)">Pet</font>', "MAIN UTILITIES")

------------------------------------------------------------------
-- State
------------------------------------------------------------------
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoRebirthEnabled = false
local selectedLuckThreshold = 0 -- 0 = All, slider value = minimum luck accepted
local tweenSpeed = 500 -- studs/s
local autoHatchEnabled = false

local MIN_SPEED, MAX_SPEED = 50, 750
local MIN_LUCK, MAX_LUCK = 5, 5e13 -- 5 .. 50T

-- Auto Open Egg configuration (adjust if the in-game names differ)
local OPEN_REMOTE_NAMES = { "OpenEgg", "HatchEgg", "EggOpen", "EggHatch", "Hatch" }
local OPEN_KEYWORDS = { "open", "hatch", "buka", "tetas" }
local OPEN_INTERVAL = 1 -- seconds

local GameRemotes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game")
local EggPlacedRemote = GameRemotes and GameRemotes:FindFirstChild("EggPlaced")
local RebirthRemote = GameRemotes and GameRemotes:FindFirstChild("Rebirth")
local RequestPlotEggsRemote = GameRemotes and GameRemotes:FindFirstChild("RequestPlotEggs")

------------------------------------------------------------------
-- Luck helpers
------------------------------------------------------------------
local function GetEggLuckValue(eggModel)
	if not eggModel then return "" end
	for _, d in ipairs(eggModel:GetDescendants()) do
		if d:IsA("TextLabel") and (d.Name == "Luck" or (d.Parent and d.Parent.Name == "EggLuck")) then
			return (tostring(d.Text):gsub("%s+", ""))
		end
	end
	return ""
end

local function ParseLuck(text)
	text = (tostring(text):upper():gsub("%s+", ""))
	local number = tonumber(text:match("[%d%.]+"))
	if not number then return nil end
	if text:find("T", 1, true) then return number * 1e12
	elseif text:find("B", 1, true) then return number * 1e9
	elseif text:find("M", 1, true) then return number * 1e6
	elseif text:find("K", 1, true) then return number * 1e3 end
	return number
end

local function MatchesLuck(luckText)
	local v = ParseLuck(luckText)
	if not v then return false end
	return v >= selectedLuckThreshold
end

------------------------------------------------------------------
-- List of eggs matching the luck filter
------------------------------------------------------------------
local function GetMatchingEggs()
	local folder = Workspace:FindFirstChild("RenderedEggs")
	if not folder then return {} end
	local eggs = {}
	for _, child in ipairs(folder:GetChildren()) do
		if (child:IsA("Model") or child:IsA("BasePart")) and MatchesLuck(GetEggLuckValue(child)) then
			table.insert(eggs, child)
		end
	end
	return eggs
end

------------------------------------------------------------------
-- Gameplay helpers
------------------------------------------------------------------
local function GetChar()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

-- True while Auto Egg is running (grabbing an egg / returning to plot)
local eggBusy = false

-- Tracks NEW eggs only. Eggs already in the backpack are ignored.
local placeQueue = {}
local knownTools = setmetatable({}, { __mode = "k" })
local hookedContainers = setmetatable({}, { __mode = "k" })
local spawnGraceUntil = 0

local function IsEggTool(t)
	return t:IsA("Tool") and string.find(string.lower(t.Name), "egg", 1, true) ~= nil
end

local function MarkExistingTools()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local character = LocalPlayer.Character
	for _, c in ipairs({ backpack, character }) do
		if c then
			for _, t in ipairs(c:GetChildren()) do
				if t:IsA("Tool") then knownTools[t] = true end
			end
		end
	end
end

local function OnToolAdded(t)
	if not t:IsA("Tool") then return end
	if knownTools[t] then return end -- already seen before (e.g. moved backpack <-> hand)
	knownTools[t] = true
	if os.clock() < spawnGraceUntil then return end -- starter tool right after respawn
	if autoPlaceEnabled and IsEggTool(t) then
		table.insert(placeQueue, t)
	end
end

local function HookContainer(c)
	if not c or hookedContainers[c] then return end
	hookedContainers[c] = true
	c.ChildAdded:Connect(OnToolAdded)
end

local function HookAllContainers()
	HookContainer(LocalPlayer:FindFirstChild("Backpack"))
	HookContainer(LocalPlayer.Character)
end

MarkExistingTools()
HookAllContainers()
LocalPlayer.ChildAdded:Connect(function(c)
	if c.Name == "Backpack" then
		spawnGraceUntil = os.clock() + 3
		HookContainer(c)
	end
end)
LocalPlayer.CharacterAdded:Connect(function(char)
	spawnGraceUntil = os.clock() + 3
	table.clear(placeQueue)
	HookContainer(char)
	task.delay(3.2, MarkExistingTools)
end)

local function ResetPlaceTracking()
	table.clear(placeQueue)
	MarkExistingTools() -- eggs already present when the toggle turns ON won't be placed
end

-- Place ONE new egg from the queue (not an old egg already in the backpack)
local function PlaceNewEgg()
	if eggBusy then return end -- wait until Auto Egg reaches the plot
	while placeQueue[1] and not placeQueue[1].Parent do table.remove(placeQueue, 1) end
	local tool = placeQueue[1]
	if not tool or not EggPlacedRemote then return end

	local character, humanoid, root = GetChar()
	if not (character and humanoid and root) then return end

	if tool.Parent ~= character then
		humanoid:EquipTool(tool)
		task.wait(0.15)
	end
	if not autoPlaceEnabled or eggBusy then return end

	EggPlacedRemote:FireServer({ PlantPosition = root.Position })

	local t0 = os.clock()
	while autoPlaceEnabled and tool.Parent and os.clock() - t0 < 1.5 do task.wait(0.1) end

	if not tool.Parent then
		table.remove(placeQueue, 1)
	else
		-- egg is still there (stacked / failed): retry up to 3 times
		tool:SetAttribute("_placeTry", (tool:GetAttribute("_placeTry") or 0) + 1)
		if tool:GetAttribute("_placeTry") >= 3 then table.remove(placeQueue, 1) end
	end
end

local function GetMyPlotCFrame()
	local plotsFolder = Workspace:FindFirstChild("Plots")
	if not plotsFolder then return nil end

	for _, plot in ipairs(plotsFolder:GetChildren()) do
		local dataFolder = plot:FindFirstChild("Data")
		local ownerVal = dataFolder and dataFolder:FindFirstChild("Owner")
		if ownerVal then
			local ownerName = ""
			if ownerVal:IsA("StringValue") then
				ownerName = ownerVal.Value
			elseif ownerVal:IsA("ObjectValue") and ownerVal.Value then
				ownerName = ownerVal.Value.Name
			end

			if ownerName == LocalPlayer.Name or ownerName == LocalPlayer.DisplayName then
				if plot:IsA("Model") then return plot:GetPivot()
				elseif plot:IsA("BasePart") then return plot.CFrame end
			end
		end
	end
	return nil
end

local currentTween

local function CancelMovement()
	if currentTween then
		pcall(function() currentTween:Cancel() end)
		currentTween = nil
	end
	local _, _, root = GetChar()
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

-- alive: function that returns false once the feature is turned off -> tween is cancelled immediately
local function TweenToCFrame(targetCFrame, alive)
	local _, _, root = GetChar()
	if not root then return false end
	if alive and not alive() then return false end

	local distance = (targetCFrame.Position - root.Position).Magnitude
	local duration = math.clamp(distance / tweenSpeed, 0.1, 10)

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	local tween = TweenService:Create(
		root,
		TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ CFrame = targetCFrame }
	)
	currentTween = tween
	tween:Play()
	tween.Completed:Wait()
	if currentTween == tween then currentTween = nil end
	return (not alive) or alive()
end

local function WaitAlive(seconds, alive)
	local t0 = os.clock()
	while os.clock() - t0 < seconds do
		if alive and not alive() then return false end
		task.wait(0.05)
	end
	return (not alive) or alive()
end

local function ForceTriggerPrompts(model, alive)
	if not model then return end
	for _, d in ipairs(model:GetDescendants()) do
		if alive and not alive() then return end
		if d:IsA("ProximityPrompt") then
			pcall(function()
				d.Enabled = true
				d.HoldDuration = 0
				d.RequiresLineOfSight = false
				if type(fireproximityprompt) == "function" then
					fireproximityprompt(d)
					task.wait(0.05)
					fireproximityprompt(d, 0)
				else
					d:InputHoldBegin()
					task.wait(0.05)
					d:InputHoldEnd()
				end
			end)
		end
	end
end

------------------------------------------------------------------
-- Auto Hatch Egg (open eggs that are already placed)
------------------------------------------------------------------
local function GetMyPlot()
	local plotsFolder = Workspace:FindFirstChild("Plots")
	if not plotsFolder then return nil end
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		local dataFolder = plot:FindFirstChild("Data")
		local ownerVal = dataFolder and dataFolder:FindFirstChild("Owner")
		if ownerVal then
			local ownerName = ""
			if ownerVal:IsA("StringValue") then
				ownerName = ownerVal.Value
			elseif ownerVal:IsA("ObjectValue") and ownerVal.Value then
				ownerName = ownerVal.Value.Name
			end
			if ownerName == LocalPlayer.Name or ownerName == LocalPlayer.DisplayName then
				return plot
			end
		end
	end
	return nil
end

local function PromptLooksLikeOpen(prompt)
	local text = string.lower(
		tostring(prompt.ActionText) .. " " .. tostring(prompt.ObjectText) .. " " ..
		prompt.Name .. " " .. (prompt.Parent and prompt.Parent.Name or "")
	)
	for _, kw in ipairs(OPEN_KEYWORDS) do
		if string.find(text, kw, 1, true) then return true end
	end
	return false
end

local function OpenPlacedEggs()
	local opened = 0

	-- 1) Open/hatch prompts on the player's own plot
	local plot = GetMyPlot()
	if plot then
		for _, d in ipairs(plot:GetDescendants()) do
			if not autoHatchEnabled then return opened end
			if d:IsA("ProximityPrompt") and d.Enabled and PromptLooksLikeOpen(d) then
				pcall(function()
					d.HoldDuration = 0
					d.RequiresLineOfSight = false
					d.MaxActivationDistance = 1e4
					if type(fireproximityprompt) == "function" then
						fireproximityprompt(d)
					else
						d:InputHoldBegin()
						task.wait(0.05)
						d:InputHoldEnd()
					end
					opened = opened + 1
				end)
			end
		end
	end

	-- 2) Egg-opening remote (if any)
	if GameRemotes then
		for _, name in ipairs(OPEN_REMOTE_NAMES) do
			if not autoHatchEnabled then return opened end
			local r = GameRemotes:FindFirstChild(name)
			if r and r:IsA("RemoteEvent") then
				pcall(function() r:FireServer() end)
			end
		end
	end

	return opened
end

------------------------------------------------------------------
-- MENU (UI -> logic)
------------------------------------------------------------------

local function FormatLuckNumber(v)
	v = math.floor(v + 0.5)
	if v <= 0 then return "All" end
	local suffixes = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, s in ipairs(suffixes) do
		if v >= s[1] then
			local num = v / s[1]
			local text = (num >= 100 and string.format("%.0f", num))
				or (num >= 10 and string.format("%.1f", num))
				or string.format("%.2f", num)
			text = text:gsub("%.?0+$", "")
			return text .. s[2]
		end
	end
	return tostring(v)
end

Hub:CreateLuckPicker(
	"SELECT EGG LUCK",
	{ { label = "All", value = 0 }, { label = "High", value = 1e9 } },
	MIN_LUCK, MAX_LUCK, 0,
	function(v) selectedLuckThreshold = v end,
	FormatLuckNumber
)

Hub:CreateToggle("AUTO EGG", "Collect eggs matching the luck filter", function(v)
	autoEggEnabled = v
	if not v then CancelMovement() end -- stop in place immediately
end)

Hub:CreateToggle("AUTO PLACE EGG", "Place newly obtained eggs (not backpack contents)", function(v)
	autoPlaceEnabled = v
	ResetPlaceTracking()
end)

Hub:CreateToggle("AUTO HATCH EGG", "Open / hatch eggs that are already placed", function(v)
	autoHatchEnabled = v
end)

Hub:CreateToggle("AUTO REBIRTH", "Automatic rebirth (5 second cooldown)", function(v)
	autoRebirthEnabled = v
end)

Hub:CreateSlider("TWEEN SPEED", MIN_SPEED, MAX_SPEED, tweenSpeed, function(v)
	tweenSpeed = v
end)

------------------------------------------------------------------
-- Loops
------------------------------------------------------------------

-- Tick loop: checks the flag every 0.05s, so it stops immediately when turned off
local function StartLoop(interval, isEnabled, fn)
	task.spawn(function()
		local last = 0
		while true do
			task.wait(0.05)
			if isEnabled() then
				if os.clock() - last >= interval then
					last = os.clock()
					pcall(fn)
				end
			else
				last = 0
			end
		end
	end)
end

-- Auto Rebirth
StartLoop(5, function() return autoRebirthEnabled and RebirthRemote ~= nil end, function()
	RebirthRemote:FireServer()
end)

-- Ask the server to refresh/render the plot's eggs (used by Auto Egg & Auto Place)
StartLoop(2, function() return (autoEggEnabled or autoPlaceEnabled) and RequestPlotEggsRemote ~= nil end, function()
	RequestPlotEggsRemote:FireServer(false)
end)

-- Auto Place Egg (new eggs only)
StartLoop(0.3, function() return autoPlaceEnabled end, PlaceNewEgg)

-- Auto Hatch Egg
StartLoop(OPEN_INTERVAL, function() return autoHatchEnabled end, OpenPlacedEggs)

-- Auto Egg
local function AliveEgg() return autoEggEnabled end

local function RunEggCycle()
	if not Workspace:FindFirstChild("RenderedEggs") then
		warn("[Auto Egg] workspace.RenderedEggs not found!")
		WaitAlive(1, AliveEgg)
		return
	end

	local eggs = GetMatchingEggs()
	if #eggs == 0 then
		WaitAlive(0.8, AliveEgg)
		return
	end

	local egg = eggs[math.random(1, #eggs)]
	local _, _, root = GetChar()
	if not (root and egg and egg.Parent) then return end

	local targetCFrame
	if egg:IsA("Model") then targetCFrame = egg:GetPivot()
	elseif egg:IsA("BasePart") then targetCFrame = egg.CFrame end
	if not targetCFrame then return end

	if not TweenToCFrame(targetCFrame + Vector3.new(0, 1.5, 0), AliveEgg) then return end
	if not WaitAlive(0.2, AliveEgg) then return end

	ForceTriggerPrompts(egg, AliveEgg)
	if not WaitAlive(0.3, AliveEgg) then return end

	local myPlotCF = GetMyPlotCFrame()
	if myPlotCF then
		if not TweenToCFrame(myPlotCF + Vector3.new(0, 3, 0), AliveEgg) then return end
	else
		warn("[Auto Egg] Player plot not found!")
	end
	WaitAlive(0.3, AliveEgg)
end

task.spawn(function()
	while true do
		task.wait(0.1)
		if autoEggEnabled then
			eggBusy = true
			pcall(RunEggCycle)
			eggBusy = false
		end
	end
end)
