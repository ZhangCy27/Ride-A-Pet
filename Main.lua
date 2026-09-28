-- Ride A Pet | Main (logika) - GUI terpisah di RideAPetGUI.lua

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Ganti URL di bawah dengan raw URL RideAPetGUI.lua kamu sendiri
-- (mis. raw.githubusercontent.com/USERNAME/REPO/main/RideAPetGUI.lua)
local GUI_URL = "https://raw.githubusercontent.com/USERNAME/REPO/main/RideAPetGUI.lua"
local UIModule = loadstring(game:HttpGet(GUI_URL))()
local Hub = UIModule.CreateWindow('Ride A <font color="rgb(65,135,255)">Pet</font>', "MAIN UTILITIES")

------------------------------------------------------------------
-- State
------------------------------------------------------------------
local autoEggEnabled = false
local autoPlaceEnabled = false
local autoRebirthEnabled = false
local selectedLuck = "All"
local tweenSpeed = 500 -- studs/s
local autoHatchEnabled = false
local autoHatchLuckEnabled = false
local luckMode = "+1 per Tick"

local MIN_SPEED, MAX_SPEED = 50, 750

local luckOptions = {
	"All", "High"
}

-- Konfigurasi Auto Open Egg (sesuaikan bila nama di game berbeda)
local OPEN_REMOTE_NAMES = { "OpenEgg", "HatchEgg", "EggOpen", "EggHatch", "Hatch" }
local OPEN_KEYWORDS = { "open", "hatch", "buka", "tetas" }
local OPEN_INTERVAL = 1 -- detik

local GameRemotes = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Game")
local EggPlacedRemote = GameRemotes and GameRemotes:FindFirstChild("EggPlaced")
local RebirthRemote = GameRemotes and GameRemotes:FindFirstChild("Rebirth")
local RequestPlotEggsRemote = GameRemotes and GameRemotes:FindFirstChild("RequestPlotEggs")

-- Konfigurasi fitur baru.
-- Nama remote di bawah adalah TEBAKAN - cek nama & argumen aslinya di game
-- (mis. pakai remote spy), lalu sesuaikan di sini. Pencarian tidak peka huruf besar/kecil
-- dan mencari di seluruh ReplicatedStorage.
local REMOTE_NAMES = {
	HatchLuck    = { "HatchLuck", "BuyHatchLuck", "UpgradeHatchLuck", "PurchaseHatchLuck" },
}
local LUCK_MODES = { "+1 per Tick", "Buy Max" }
local LUCK_ARGS = { -- argumen yang dikirim ke remote sesuai mode purchase
	["+1 per Tick"] = { 1 },
	["Buy Max"] = { "Max" },
}
local INTERVALS = { -- detik per tick
	HatchLuck = 0.5,
}

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

local function IsHighLuck(text) -- High = 1B - 50T
	local v = ParseLuck(text)
	return v ~= nil and v >= 1e9 and v <= 5e13
end

local function MatchesLuck(luckText)
	if selectedLuck == "All" then return true end
	if selectedLuck == "High" then return IsHighLuck(luckText) end
	local a, b = ParseLuck(luckText), ParseLuck(selectedLuck)
	return a ~= nil and b ~= nil and a == b
end

------------------------------------------------------------------
-- Daftar egg sesuai filter luck
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

-- True kalau Auto Egg sedang jalan mengambil egg / kembali ke plot
local eggBusy = false

-- Tracking egg BARU. Egg yang sudah ada di backpack diabaikan.
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
	if knownTools[t] then return end -- sudah pernah dilihat (mis. pindah backpack <-> tangan)
	knownTools[t] = true
	if os.clock() < spawnGraceUntil then return end -- tool bawaan setelah respawn
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
	MarkExistingTools() -- egg yang sudah ada saat toggle ON tidak akan dipasang
end

-- Pasang SATU egg baru dari antrian (bukan egg lama di backpack)
local function PlaceNewEgg()
	if eggBusy then return end -- tunggu Auto Egg sampai di plot
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
		-- egg masih ada (stack / gagal): coba maksimal 3 kali
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

-- alive: fungsi yang return false saat fitur dimatikan -> tween langsung dibatalkan
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
-- Auto Hatch Egg (buka telur yang sudah dipasang)
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

	-- 2) Remote buka telur (jika ada)
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
-- Helper remote (fitur index / hatch luck)
------------------------------------------------------------------
local RemoteCache, RemoteLastTry, RemoteWarned = {}, {}, {}

local function FindRemoteByNames(names)
	local wanted = {}
	for _, n in ipairs(names) do wanted[string.lower(n)] = true end
	for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
		if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and wanted[string.lower(d.Name)] then
			return d
		end
	end
	return nil
end

local function GetRemote(key)
	local r = RemoteCache[key]
	if r and r.Parent then return r end
	if os.clock() - (RemoteLastTry[key] or -10) < 5 then return nil end -- jangan scan tiap tick
	RemoteLastTry[key] = os.clock()
	r = FindRemoteByNames(REMOTE_NAMES[key])
	RemoteCache[key] = r
	if not r and not RemoteWarned[key] then
		RemoteWarned[key] = true
		warn("[Ride A Pet] Remote '" .. key .. "' tidak ditemukan. Sesuaikan REMOTE_NAMES." .. key)
	end
	return r
end

local function FireFeature(key, ...)
	local r = GetRemote(key)
	if not r then return false end
	if r:IsA("RemoteEvent") then
		r:FireServer(...)
	else
		r:InvokeServer(...)
	end
	return true
end

------------------------------------------------------------------
-- Hatch Luck (klik tombol UI: +1 / MAX)
------------------------------------------------------------------

local hatchLuckCache = nil
local hatchLuckLastScan = -10
local hatchLuckLogged = false

local function IsCostText(t)
	return tostring(t):match("^%s*%$") ~= nil
end

local function ButtonForLabel(label, root)
	local n = label
	while n and n ~= root.Parent do
		if n:IsA("GuiButton") then return n end
		n = n.Parent
	end
	-- tombol transparan yang menimpa label
	local c = label.AbsolutePosition + label.AbsoluteSize / 2
	local best, bestArea
	for _, b in ipairs(root:GetDescendants()) do
		if b:IsA("GuiButton") and b.Visible then
			local p, s = b.AbsolutePosition, b.AbsoluteSize
			if c.X >= p.X and c.X <= p.X + s.X and c.Y >= p.Y and c.Y <= p.Y + s.Y then
				local area = s.X * s.Y
				if not bestArea or area < bestArea then best, bestArea = b, area end
			end
		end
	end
	return best
end

local function CostLabelsIn(root)
	local labels = {}
	for _, x in ipairs(root:GetDescendants()) do
		if (x:IsA("TextLabel") or x:IsA("TextButton")) and IsCostText(x.Text) then
			table.insert(labels, x)
		end
	end
	return labels
end

local function ScanHatchLuck()
	local bases = { LocalPlayer:FindFirstChild("PlayerGui"), Workspace }
	for _, base in ipairs(bases) do
		if base then
			for _, d in ipairs(base:GetDescendants()) do
				if d:IsA("TextLabel") and d.Text == "Hatch Luck" and not d:IsDescendantOf(Hub.ScreenGui) then
					-- naik sampai ketemu container yang punya >= 2 tombol harga
					local node = d.Parent
					while node and node ~= base do
						local labels = CostLabelsIn(node)
						if #labels >= 2 then
							local entries, seen = {}, {}
							for _, l in ipairs(labels) do
								local btn = ButtonForLabel(l, node)
								if btn and not seen[btn] then
									seen[btn] = true
									table.insert(entries, { btn = btn, cost = ParseLuck(l.Text) or 0, text = l.Text })
								end
							end
							if #entries >= 2 then
								local maxLabel
								for _, x in ipairs(node:GetDescendants()) do
									if x:IsA("TextLabel") and string.upper((x.Text:gsub("%s+", ""))) == "MAX" then
										maxLabel = x
										break
									end
								end
								local plus, max
								if maxLabel then
									local mc = maxLabel.AbsolutePosition + maxLabel.AbsoluteSize / 2
									local bestDist
									for _, e in ipairs(entries) do
										local c = e.btn.AbsolutePosition + e.btn.AbsoluteSize / 2
										local dist = (c - mc).Magnitude
										if not bestDist or dist < bestDist then bestDist, max = dist, e end
									end
									for _, e in ipairs(entries) do
										if e ~= max and (not plus or e.cost < plus.cost) then plus = e end
									end
								else
									table.sort(entries, function(x, y) return x.cost < y.cost end)
									plus, max = entries[1], entries[#entries]
								end
								if plus and max then return { plus = plus, max = max } end
							end
						end
						node = node.Parent
					end
				end
			end
		end
	end
	return nil
end

local function GetHatchLuckButtons()
	local c = hatchLuckCache
	if c and c.plus.btn.Parent and c.max.btn.Parent then return c end
	if os.clock() - hatchLuckLastScan < 3 then return nil end -- jangan scan tiap tick
	hatchLuckLastScan = os.clock()
	hatchLuckCache = ScanHatchLuck()
	if hatchLuckCache and not hatchLuckLogged then
		hatchLuckLogged = true
		print("[Hatch Luck] +1 = " .. hatchLuckCache.plus.text .. " | MAX = " .. hatchLuckCache.max.text)
	end
	return hatchLuckCache
end

local function ClickButton(btn)
	local fired = false
	if type(firesignal) == "function" then
		pcall(function() firesignal(btn.MouseButton1Click); fired = true end)
		pcall(function() firesignal(btn.Activated); fired = true end)
	elseif type(getconnections) == "function" then
		for _, ev in ipairs({ btn.MouseButton1Click, btn.Activated }) do
			pcall(function()
				for _, conn in ipairs(getconnections(ev)) do conn:Fire(); fired = true end
			end)
		end
	end
	return fired
end

-- Argumen RequestPlotEggs per mode. BELUM DIPASTIKAN arahnya - kalau setelah
-- dicoba di game ternyata kebalik (+1 malah Buy Max atau sebaliknya), tukar
-- saja nilai true/false di bawah ini.
local HATCH_LUCK_REQUEST_ARGS = {
	["+1 per Tick"] = false,
	["Buy Max"] = true,
}

local hatchLuckMethodLogged = {}
local function LogHatchLuckMethod(method)
	if hatchLuckMethodLogged[method] then return end
	hatchLuckMethodLogged[method] = true
	print("[Hatch Luck] Berhasil pakai metode: " .. method)
end

local function BuyHatchLuck()
	-- 1) Cara lama: klik tombol UI asli (+1 / MAX)
	local b = GetHatchLuckButtons()
	if b then
		local entry = (luckMode == "Buy Max") and b.max or b.plus
		if ClickButton(entry.btn) then
			LogHatchLuckMethod("tombol UI")
			return
		end
	end

	-- 2) RequestPlotEggs dengan argumen boolean sesuai mode
	if RequestPlotEggsRemote then
		local ok = pcall(function()
			RequestPlotEggsRemote:FireServer(HATCH_LUCK_REQUEST_ARGS[luckMode])
		end)
		if ok then
			LogHatchLuckMethod("RequestPlotEggs(" .. tostring(HATCH_LUCK_REQUEST_ARGS[luckMode]) .. ")")
			return
		end
	end

	-- 3) Fallback lama: cari remote bernama HatchLuck/BuyHatchLuck/dst
	if FireFeature("HatchLuck", table.unpack(LUCK_ARGS[luckMode] or { 1 })) then
		LogHatchLuckMethod("remote HatchLuck (fallback)")
	end
end

------------------------------------------------------------------
-- MENU (UI -> logika)
------------------------------------------------------------------

Hub:CreateSlider("SELECT EGG LUCK", 1, #luckOptions, 1, function(i)
	selectedLuck = luckOptions[i]
end, function(i)
	return luckOptions[i]
end)

Hub:CreateToggle("AUTO EGG", "Ambil telur sesuai filter luck", function(v)
	autoEggEnabled = v
	if not v then CancelMovement() end -- berhenti di tempat, langsung
end)

Hub:CreateToggle("AUTO PLACE EGG", "Pasang egg yang baru didapat (bukan isi backpack)", function(v)
	autoPlaceEnabled = v
	ResetPlaceTracking()
end)

Hub:CreateToggle("AUTO HATCH EGG", "Buka / tetas telur yang sudah dipasang", function(v)
	autoHatchEnabled = v
end)

Hub:CreateToggle("AUTO REBIRTH", "Rebirth otomatis (cooldown 5 detik)", function(v)
	autoRebirthEnabled = v
end)

Hub:CreateToggle("AUTO HATCH LUCK", "Beli Hatch Luck: +1 per tick / Buy Max", function(v)
	autoHatchLuckEnabled = v
end)

Hub:CreateDropdown("PURCHASE MODE", LUCK_MODES, luckMode, function(opt)
	luckMode = opt
end)

Hub:CreateSlider("KECEPATAN TWEEN", MIN_SPEED, MAX_SPEED, tweenSpeed, function(v)
	tweenSpeed = v
end)

------------------------------------------------------------------
-- Loops
------------------------------------------------------------------

-- Tick loop: cek flag tiap 0.05 detik, jadi berhenti langsung saat dimatikan
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

-- Minta server refresh/render egg di plot (dipakai Auto Egg & Auto Place)
StartLoop(2, function() return (autoEggEnabled or autoPlaceEnabled) and RequestPlotEggsRemote ~= nil end, function()
	RequestPlotEggsRemote:FireServer(false)
end)

-- Auto Place Egg (hanya egg baru)
StartLoop(0.3, function() return autoPlaceEnabled end, PlaceNewEgg)

-- Auto Hatch Egg
StartLoop(OPEN_INTERVAL, function() return autoHatchEnabled end, OpenPlacedEggs)

-- Auto Hatch Luck (+1 per tick / buy max)
StartLoop(INTERVALS.HatchLuck, function() return autoHatchLuckEnabled end, BuyHatchLuck)

-- Auto Egg
local function AliveEgg() return autoEggEnabled end

local function RunEggCycle()
	if not Workspace:FindFirstChild("RenderedEggs") then
		warn("[Auto Egg] workspace.RenderedEggs tidak ditemukan!")
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
		warn("[Auto Egg] Plot pemain tidak ditemukan!")
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
