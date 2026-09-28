-- RideAPetGUI.lua
-- Modul UI (pill + window) untuk Ride A Pet Hub.
-- Pakai dari script lain seperti ini:
--
--   local UIModule = loadstring(game:HttpGet("RAW_URL_KAMU_DISINI"))()
--   local Hub = UIModule.CreateWindow("Ride A Pet", "MAIN UTILITIES")
--   Hub:CreateToggle("AUTO EGG", "Ambil telur", function(v) ... end)
--   Hub:CreateDropdown("SELECT AREA", {"All","Forest"}, "All", function(opt) ... end)
--   Hub:CreateSlider("KECEPATAN", 50, 750, 500, function(v) ... end)

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

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
-- UIModule.CreateWindow
------------------------------------------------------------------
local UIModule = {}

function UIModule.CreateWindow(title, subtitle)
	local GUI_NAME = "RideAPetHubGui"

	pcall(function() local o = CoreGui:FindFirstChild(GUI_NAME) if o then o:Destroy() end end)
	pcall(function()
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		local o = pg and pg:FindFirstChild(GUI_NAME)
		if o then o:Destroy() end
	end)

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

	local FULL_SIZE = UDim2.fromOffset(340, 360)
	local PILL_SIZE = UDim2.fromOffset(240, 54)
	local TITLE_RICH = title or 'Ride A <font color="rgb(65,135,255)">Pet</font>'
	local SUBTITLE = subtitle or "MAIN UTILITIES"

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
		local COLLAPSED = 48
		local LIST_H = math.min(#options * 30, 150)
		local EXPANDED = COLLAPSED + LIST_H + 10
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
			Size = UDim2.new(1, -20, 0, LIST_H), Position = UDim2.fromOffset(10, COLLAPSED + 4),
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

	local function CreateSlider(titleText, min, max, default, callback, formatter)
		local card = New("Frame", { Size = UDim2.new(1, -6, 0, 62), BackgroundColor3 = Theme.Card }, Scroll)
		Round(card, 12)
		Stroke(card, Theme.Border, 1, 0.5)

		local sdot = New("Frame", {
			Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(16, 15), BackgroundColor3 = Theme.Accent,
		}, card)
		Round(sdot, 99)
		New("TextLabel", {
			Size = UDim2.new(1, -110, 0, 20), Position = UDim2.fromOffset(30, 8),
			BackgroundTransparency = 1, Text = titleText, TextColor3 = Theme.Text,
			Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
		}, card)

		local valueLabel = New("TextLabel", {
			Size = UDim2.fromOffset(70, 20), Position = UDim2.new(1, -80, 0, 8),
			BackgroundTransparency = 1, Text = formatter and formatter(default) or tostring(default), TextColor3 = Theme.AccentLight,
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
		local lastV = default
		local function update(input)
			local raw = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local v = math.floor(min + raw * (max - min) + 0.5) -- snap ke nilai bulat terdekat
			local a = (max > min) and (v - min) / (max - min) or 0
			valueLabel.Text = formatter and formatter(v) or tostring(v)
			fill.Size = UDim2.fromScale(a, 1)
			knob.Position = UDim2.new(a, -6, 0.5, -6)
			if v ~= lastV then
				lastV = v
				callback(v)
			end
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

	local Hub = {}
	Hub.ScreenGui = ScreenGui
	Hub.MainFrame = MainFrame
	Hub.Pill = Pill
	Hub.Scroll = Scroll
	Hub.Theme = Theme
	Hub.Open = OpenWindow
	Hub.Close = CloseWindow

	function Hub:CreateToggle(titleText, subText, callback)
		return CreateToggle(titleText, subText, callback)
	end

	function Hub:CreateDropdown(titleText, options, default, callback)
		return CreateDropdown(titleText, options, default, callback)
	end

	function Hub:CreateSlider(titleText, min, max, default, callback, formatter)
		return CreateSlider(titleText, min, max, default, callback, formatter)
	end

	return Hub
end

return UIModule
