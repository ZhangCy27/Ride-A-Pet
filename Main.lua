-- Ride A Pet | RedAPet logic (merged)

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local GUI_NAME = "ZhangHubGui"

pcall(function() local o = CoreGui:FindFirstChild(GUI_NAME) if o then o:Destroy() end end)
pcall(function()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	local o = pg and pg:FindFirstChild(GUI_NAME)
	if o then o:Destroy() end
end)

------------------------------------------------------------------
-- State
------------------------------------------------------------------
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoRebirthEnabled = false
local selectedLuck = "All"
local tweenSpeed = 500 -- studs/s

local MIN_SPEED, MAX_SPEED = 50, 750

local luckOptions = {
	"All", "High",
	"5", "30", "50", "100", "200", "500", "750",
	"1K", "3K", "10K", "30K", "90K", "150K", "250K", "500K", "700K",
	"1M", "3M", "7M", "300M",
	"1.5B", "100B", "300B",
	"1T"
}

-- Konfigurasi Auto Open Egg (sesuaikan bila nama di game berbeda)
local OPEN_REMOTE_NAMES = { "OpenEgg", "HatchEgg", "EggOpen", "EggHatch", "Hatch" }
local OPEN_KEYWORDS = { "open", "hatch", "buka", "tetas" }
local OPEN_INTERVAL = 1 -- detik

local GameRemotes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game")
local EggPlacedRemote = GameRemotes and GameRemotes:FindFirstChild("EggPlaced")
local RebirthRemote = GameRemotes and GameRemotes:FindFirstChild("Rebirth")

------------------------------------------------------------------
-- Theme & helpers UI
------------------------------------------------------------------
local Theme = {
	Background = Color3.fromRGB(0, 0, 0),
	Card = Color3.fromRGB(15, 20, 31),
	Accent = Color3.fromRGB(37, 120, 255),
	AccentLight = Color3.fromRGB(82, 151, 255),
	Text = Color3.fromRGB(245, 247, 255),
	TextSecondary = Color3.fromRGB(151, 163, 186),
	TextMuted = Color3.fromRGB(88, 100, 123),
	Border = Color3.fromRGB(28, 44, 58),
	Off = Color3.fromRGB(20, 27, 40),
	OffStroke = Color3.fromRGB(50, 64, 88),
	On = Color3.fromRGB(18, 48, 43),
	OnStroke = Color3.fromRGB(46, 146, 116),
	OnAccent = Color3.fromRGB(76, 220, 163),
}

local function Tween(obj, dur, props)
	if not obj or not obj.Parent then return end
	local t = TweenService:Create(obj, TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function New(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function Round(parent, r) return New("UICorner", { CornerRadius = UDim.new(0, r) }, parent) end
local function Stroke(parent, color, thick, transp)
	return New("UIStroke", { Color = color, Thickness = thick or 1, Transparency = transp or 0 }, parent)
end

------------------------------------------------------------------
-- Window (pill + window)
------------------------------------------------------------------

local FULL_SIZE = UDim2.fromOffset(340, 330)
local PILL_SIZE = UDim2.fromOffset(240, 54)
local TITLE_RICH = 'Ride A <font color="rgb(65,135,255)">Pet</font>'
local SUBTITLE = "MAIN UTILITIES"

local ScreenGui = New("ScreenGui", { Name = GUI_NAME, ResetOnSpawn = false, DisplayOrder = 999 }, nil)
local okParent = pcall(function() ScreenGui.Parent = CoreGui end)
if not okParent or not ScreenGui.Parent then
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Logo "F" (dipakai di pill & header)
local function CreateLogo(parent)
	local logo = New("Frame", {
		Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(12, 9),
		BackgroundColor3 = Color3.fromRGB(10, 16, 30),
	}, parent)
	Round(logo, 10)
	Stroke(logo, Theme.Accent, 1.5, 0)
	New("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "F",
		TextColor3 = Theme.Accent, Font = Enum.Font.GothamBlack, TextSize = 22,
	}, logo)
	return logo
end

local function CreateTitleBlock(parent)
	New("TextLabel", {
		Size = UDim2.new(1, -120, 0, 20), Position = UDim2.fromOffset(58, 9),
		BackgroundTransparency = 1, RichText = true, Text = TITLE_RICH,
		TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	New("TextLabel", {
		Size = UDim2.new(1, -120, 0, 14), Position = UDim2.fromOffset(59, 29),
		BackgroundTransparency = 1, Text = SUBTITLE,
		TextColor3 = Theme.TextMuted, Font = Enum.Font.GothamMedium, TextSize = 8,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end

-- Pill (kondisi minimize) - bisa digeser, tap untuk membuka
local Pill = New("Frame", {
	Name = "Pill", Size = PILL_SIZE, Position = UDim2.new(0.5, 0, 0, 60),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0, Active = true,
}, ScreenGui)
Round(Pill, 16)
Stroke(Pill, Theme.Border, 1.2, 0.1)
CreateLogo(Pill)
CreateTitleBlock(Pill)

-- Window utama
local MainFrame = New("Frame", {
	Name = "MainFrame", Size = FULL_SIZE, Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0, Active = true, ClipsDescendants = true, Visible = false,
}, ScreenGui)
Round(MainFrame, 20)
Stroke(MainFrame, Theme.Border, 1.5, 0.05)

-- garis biru kecil di atas window
local TopBar = New("Frame", {
	Size = UDim2.fromOffset(74, 3), Position = UDim2.new(0.5, -37, 0, 0),
	BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
}, MainFrame)
Round(TopBar, 99)

local Header = New("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Active = true }, MainFrame)
CreateLogo(Header)
CreateTitleBlock(Header)

local MinimizeButton = New("TextButton", {
	Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -46, 0, 10),
	BackgroundColor3 = Theme.Card, Text = "–", TextColor3 = Theme.TextSecondary,
	Font = Enum.Font.GothamMedium, TextSize = 18,
}, Header)
Round(MinimizeButton, 10)

local Scroll = New("ScrollingFrame", {
	Size = UDim2.new(1, -20, 1, -68), Position = UDim2.fromOffset(10, 62),
	BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
}, MainFrame)

local List = New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, Scroll)
List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	Scroll.CanvasSize = UDim2.fromOffset(0, List.AbsoluteContentSize.Y + 15)
end)

New("TextLabel", {
	Size = UDim2.new(1, -6, 0, 16), BackgroundTransparency = 1, Text = "FEATURES",
	TextColor3 = Theme.TextMuted, Font = Enum.Font.GothamMedium, TextSize = 8,
	TextXAlignment = Enum.TextXAlignment.Left,
}, Scroll)

------------------------------------------------------------------
-- Komponen
------------------------------------------------------------------
local function CreateToggle(titleText, subText, callback)
	local btn = New("TextButton", { Size = UDim2.new(1, -6, 0, 52), BackgroundColor3 = Theme.Off, Text = "" }, Scroll)
	Round(btn, 14)
	local stroke = Stroke(btn, Theme.OffStroke, 1, 0.2)

	local dot = New("Frame", {
		Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(16, 22),
		BackgroundColor3 = Color3.fromRGB(100, 111, 130),
	}, btn)
	Round(dot, 99)

	New("TextLabel", {
		Size = UDim2.new(1, -100, 0, 18), Position = UDim2.fromOffset(32, 8),
		BackgroundTransparency = 1, Text = titleText, TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
	}, btn)

	New("TextLabel", {
		Size = UDim2.new(1, -100, 0, 14), Position = UDim2.fromOffset(32, 26),
		BackgroundTransparency = 1, Text = subText, TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Left,
	}, btn)

	local status = New("TextLabel", {
		Size = UDim2.fromOffset(50, 20), Position = UDim2.new(1, -60, 0, 16),
		BackgroundTransparency = 1, Text = "OFF", TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right,
	}, btn)

	local active = false
	btn.MouseButton1Click:Connect(function()
		active = not active
		status.Text = active and "ON" or "OFF"
		status.TextColor3 = active and Theme.OnAccent or Theme.TextMuted
		dot.BackgroundColor3 = active and Theme.OnAccent or Color3.fromRGB(100, 111, 130)
		Tween(btn, 0.2, { BackgroundColor3 = active and Theme.On or Theme.Off })
		Tween(stroke, 0.2, { Color = active and Theme.OnStroke or Theme.OffStroke })
		callback(active)
	end)
	return btn
end

-- Dropdown yang membuka daftar (lebih praktis untuk banyak opsi)
local function CreateDropdown(titleText, options, default, callback)
	local COLLAPSED, EXPANDED = 48, 48 + 160
	local card = New("Frame", {
		Size = UDim2.new(1, -6, 0, COLLAPSED), BackgroundColor3 = Theme.Card, ClipsDescendants = true,
	}, Scroll)
	Round(card, 12)
	Stroke(card, Theme.Border, 1, 0.5)

	New("TextLabel", {
		Size = UDim2.new(0.4, 0, 0, COLLAPSED), Position = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1, Text = titleText, TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local current = New("TextButton", {
		Size = UDim2.new(0.52, 0, 0, 28), Position = UDim2.new(0.45, 0, 0, 10),
		BackgroundColor3 = Theme.Off, Text = default .. "  ▾", TextColor3 = Theme.AccentLight,
		Font = Enum.Font.GothamMedium, TextSize = 10,
	}, card)
	Round(current, 8)
	Stroke(current, Theme.Border, 1)

	local listFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, -20, 0, 150), Position = UDim2.fromOffset(10, COLLAPSED + 4),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
	}, card)
	local layout = New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
	end)

	local open = false
	local function setOpen(v)
		open = v
		Tween(card, 0.2, { Size = UDim2.new(1, -6, 0, open and EXPANDED or COLLAPSED) })
	end

	for _, opt in ipairs(options) do
		local b = New("TextButton", {
			Size = UDim2.new(1, -6, 0, 26), BackgroundColor3 = Theme.Off, Text = opt,
			TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 10,
		}, listFrame)
		Round(b, 8)
		b.MouseButton1Click:Connect(function()
			current.Text = opt .. "  ▾"
			setOpen(false)
			callback(opt)
		end)
	end

	current.MouseButton1Click:Connect(function() setOpen(not open) end)
	return card
end

local function CreateSlider(titleText, min, max, default, callback)
	local card = New("Frame", { Size = UDim2.new(1, -6, 0, 62), BackgroundColor3 = Theme.Card }, Scroll)
	Round(card, 12)
	Stroke(card, Theme.Border, 1, 0.5)

	local sdot = New("Frame", {
		Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(16, 15), BackgroundColor3 = Theme.Accent,
	}, card)
	Round(sdot, 99)
	New("TextLabel", {
		Size = UDim2.new(1, -90, 0, 20), Position = UDim2.fromOffset(30, 8),
		BackgroundTransparency = 1, Text = titleText, TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	}, card)

	local valueLabel = New("TextLabel", {
		Size = UDim2.fromOffset(50, 20), Position = UDim2.new(1, -60, 0, 8),
		BackgroundTransparency = 1, Text = tostring(default), TextColor3 = Theme.AccentLight,
		Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
	}, card)

	local bar = New("Frame", {
		Size = UDim2.new(1, -28, 0, 6), Position = UDim2.fromOffset(14, 38), BackgroundColor3 = Theme.Off,
	}, card)
	Round(bar, 99)

	local a0 = math.clamp((default - min) / (max - min), 0, 1)
	local fill = New("Frame", { Size = UDim2.new(a0, 0, 1, 0), BackgroundColor3 = Theme.Accent }, bar)
	Round(fill, 99)
	local knob = New("Frame", {
		Size = UDim2.fromOffset(12, 12), Position = UDim2.new(a0, -6, 0.5, -6), BackgroundColor3 = Theme.Text,
	}, bar)
	Round(knob, 99)

	local dragging = false
	local function update(input)
		local a = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local v = math.floor(min + a * (max - min))
		valueLabel.Text = tostring(v)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.new(a, -6, 0.5, -6)
		callback(v)
	end

	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(i)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			update(i)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	return card
end

------------------------------------------------------------------
-- Buka/tutup + drag
------------------------------------------------------------------

local windowPos = UDim2.fromScale(0.5, 0.5)
local isOpen, busy = false, false

local function OpenWindow()
	if busy or isOpen then return end
	busy = true
	MainFrame.Size = PILL_SIZE
	MainFrame.Position = Pill.Position
	Pill.Visible = false
	MainFrame.Visible = true
	local t = Tween(MainFrame, 0.35, { Size = FULL_SIZE, Position = windowPos })
	if t then t.Completed:Wait() end
	isOpen, busy = true, false
end

local function CloseWindow()
	if busy or not isOpen then return end
	busy = true
	windowPos = MainFrame.Position
	local t = Tween(MainFrame, 0.3, { Size = PILL_SIZE, Position = Pill.Position })
	if t then t.Completed:Wait() end
	MainFrame.Visible = false
	Pill.Visible = true
	isOpen, busy = false, false
end

local function MakeDraggable(handle, target, onTap)
	local dragging, moved, dragStart, startPos = false, false, nil, nil

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			dragStart, startPos = input.Position, target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved and onTap then onTap() end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			if d.Magnitude > 6 then moved = true end
			if moved then
				target.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end
	end)
end

MakeDraggable(Pill, Pill, function() task.spawn(OpenWindow) end)
MakeDraggable(Header, MainFrame, nil)
MinimizeButton.MouseButton1Click:Connect(function() task.spawn(CloseWindow) end)

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

local function IsHighLuck(text) -- High = 1M - 1T
	local v = ParseLuck(text)
	return v ~= nil and v >= 1e6 and v <= 1e12
end

local function MatchesLuck(luckText)
	if selectedLuck == "All" then return true end
	if selectedLuck == "High" then return IsHighLuck(luckText) end
	local a, b = ParseLuck(luckText), ParseLuck(selectedLuck)
	return a ~= nil and b ~= nil and a == b
end

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
local function EquipEggTool()
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return false end

	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") and string.find(string.lower(item.Name), "egg") then
			return true
		end
	end

	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and string.find(string.lower(tool.Name), "egg") then
				humanoid:EquipTool(tool)
				task.wait(0.1)
				return true
			end
		end
	end
	return false
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

local function TweenToCFrame(targetCFrame)
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end

	local distance = (targetCFrame.Position - rootPart.Position).Magnitude
	local duration = math.clamp(distance / tweenSpeed, 0.1, 10)

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	local tween = TweenService:Create(
		rootPart,
		TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ CFrame = targetCFrame }
	)
	tween:Play()
	tween.Completed:Wait()
	return true
end

local function ForceTriggerPrompts(model)
	if not model then return end
	for _, d in ipairs(model:GetDescendants()) do
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
-- Auto Open Egg (dipakai oleh Auto Place Egg)
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

	-- 1) Prompt buka/tetas milik plot sendiri
	local plot = GetMyPlot()
	if plot then
		for _, d in ipairs(plot:GetDescendants()) do
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

	-- 2) Remote buka telur (jika ada)
	if GameRemotes then
		for _, name in ipairs(OPEN_REMOTE_NAMES) do
			local r = GameRemotes:FindFirstChild(name)
			if r and r:IsA("RemoteEvent") then
				pcall(function() r:FireServer() end)
			end
		end
	end

	return opened
end

------------------------------------------------------------------
-- MENU (UI -> logika)
------------------------------------------------------------------
CreateDropdown("SELECT EGG LUCK", luckOptions, "All", function(opt)
	selectedLuck = opt
end)

CreateToggle("AUTO EGG", "Ambil telur sesuai filter luck", function(v)
	autoEggEnabled = v
end)

CreateToggle("AUTO PLACE EGG", "Pasang telur + auto open egg", function(v)
	autoPlaceEnabled = v
end)

CreateToggle("AUTO REBIRTH", "Rebirth otomatis (cooldown 5 detik)", function(v)
	autoRebirthEnabled = v
end)

CreateSlider("KECEPATAN TWEEN", MIN_SPEED, MAX_SPEED, tweenSpeed, function(v)
	tweenSpeed = v
end)

------------------------------------------------------------------
-- Loops
------------------------------------------------------------------
-- Auto Rebirth
task.spawn(function()
	while true do
		task.wait(5)
		if autoRebirthEnabled and RebirthRemote then
			pcall(function() RebirthRemote:FireServer() end)
		end
	end
end)

-- Auto Place Egg + Auto Open Egg
task.spawn(function()
	local lastOpen = 0
	while true do
		task.wait(0.3)
		if autoPlaceEnabled then
			local character = LocalPlayer.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if rootPart and EggPlacedRemote then
				EquipEggTool()
				pcall(function()
					EggPlacedRemote:FireServer({ PlantPosition = rootPart.Position })
				end)
			end

			if os.clock() - lastOpen >= OPEN_INTERVAL then
				lastOpen = os.clock()
				pcall(OpenPlacedEggs)
			end
		end
	end
end)

-- Auto Egg
task.spawn(function()
	while true do
		task.wait(0.5)
		if autoEggEnabled then
			if not Workspace:FindFirstChild("RenderedEggs") then
				warn("[Auto Egg] workspace.RenderedEggs tidak ditemukan!")
				task.wait(1)
			else
				local eggs = GetMatchingEggs()
				if #eggs > 0 then
					local egg = eggs[math.random(1, #eggs)]
					local character = LocalPlayer.Character
					local rootPart = character and character:FindFirstChild("HumanoidRootPart")

					if rootPart and egg and egg.Parent then
						local targetCFrame
						if egg:IsA("Model") then targetCFrame = egg:GetPivot()
						elseif egg:IsA("BasePart") then targetCFrame = egg.CFrame end

						if targetCFrame then
							TweenToCFrame(targetCFrame + Vector3.new(0, 1.5, 0))
							task.wait(0.2)

							ForceTriggerPrompts(egg)
							task.wait(0.3)

							local myPlotCF = GetMyPlotCFrame()
							if myPlotCF then
								TweenToCFrame(myPlotCF + Vector3.new(0, 3, 0))
							else
								warn("[Auto Egg] Plot pemain tidak ditemukan!")
							end
							task.wait(0.3)
						end
					end
				else
					task.wait(0.8)
				end
			end
		end
	end
end)
