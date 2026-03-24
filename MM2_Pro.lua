--// SERVICES
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local TweenService  = game:GetService("TweenService")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// REMOTES
local GunKill = RS:WaitForChild("Remotes"):WaitForChild("Gameplay"):WaitForChild("GunKill")

--// TOGGLES & SETTINGS
local Toggles = {
	Aimbot          = false,
	AutoGunTP       = false,
	AutoGunSilent   = false,
	AutoDodge       = false,
	Fly             = false,
	Noclip          = false,
	GodMode         = false,
	Headless        = false,
	AntiAFK         = false,
	AutoHide        = false,
	ESP_Murder      = false,
	ESP_Sheriff     = false,
	ESP_Innocent    = false,
	ESP_Names       = false,
	ESP_Lines       = false,
	AutoKillSheriff = false,
	AutoKillAll     = false,
	AutoCoins       = false,
	Spinner         = false,
}
local Settings = {
	WalkSpeed = 16,
	JumpPower = 50,
	FlySpeed  = 60,
	SpinSpeed = 8,
}

--// ─────────────────────────────────────
--//  ROLE HELPERS
--// ─────────────────────────────────────
local function getRole(plr)
	local char = plr.Character
	if not char then return nil end
	local bp = plr.Backpack
	if bp and bp:FindFirstChild("Knife") then return "Murder" end
	for _, i in pairs(char:GetChildren()) do
		if i:IsA("Tool") and i.Name == "Knife" then return "Murder" end
	end
	if bp and bp:FindFirstChild("Gun") then return "Sheriff" end
	for _, i in pairs(char:GetChildren()) do
		if i:IsA("Tool") and i.Name == "Gun" then return "Sheriff" end
	end
	return "Innocent"
end

local function getLocalRole()  return getRole(player) end
local function isLocalMurder() return getLocalRole() == "Murder" end
local function isLocalInnocent() return getLocalRole() == "Innocent" end

local function getKnife()
	local char = player.Character
	local bp   = player.Backpack
	if bp then
		local k = bp:FindFirstChild("Knife")
		if k then return k end
	end
	if char then
		for _, i in pairs(char:GetChildren()) do
			if i:IsA("Tool") and i.Name == "Knife" then return i end
		end
	end
	return nil
end

local function getKnifeStab()
	local knife = getKnife()
	if not knife then return nil end
	local ev = knife:FindFirstChild("Events")
	if ev then
		local s = ev:FindFirstChild("KnifeStabbed")
		if s then return s end
	end
	for _, v in pairs(knife:GetDescendants()) do
		if v:IsA("RemoteEvent") and
			(v.Name == "KnifeStabbed" or v.Name == "Stab" or v.Name == "Hit") then
			return v
		end
	end
	return nil
end

local function getNearestMurder()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local closest, minD = nil, math.huge
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == player then continue end
		if getRole(plr) ~= "Murder" then continue end
		local c = plr.Character
		local h = c and c:FindFirstChild("HumanoidRootPart")
		if not h then continue end
		local d = (hrp.Position - h.Position).Magnitude
		if d < minD then minD = d closest = plr end
	end
	return closest
end

--// ─────────────────────────────────────
--//  FLY — dirección basada en cámara
--//  compatible Delta / móvil / PC
--// ─────────────────────────────────────
local flyBV, flyBG, flyConn
-- estos se declaran aquí, se crean después del gui
local flyUp   = false
local flyDown = false

local function startFly()
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	local hum  = char and char:FindFirstChild("Humanoid")
	if not hrp then return end

	hrp.Velocity = Vector3.new(0, 0, 0)

	flyBV = Instance.new("BodyVelocity")
	flyBV.Velocity  = Vector3.new(0, 0, 0)
	flyBV.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
	flyBV.Parent    = hrp

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	flyBG.D         = 100
	flyBG.CFrame    = hrp.CFrame
	flyBG.Parent    = hrp

	if hum then hum.PlatformStand = true end

	flyConn = RunService.RenderStepped:Connect(function()
		if not Toggles.Fly or not hrp or not hrp.Parent then
			if flyConn then flyConn:Disconnect() end
			return
		end

		-- Dirección completa basada en la cámara (incluye arriba/abajo)
		local camCF  = camera.CFrame
		local moveDir = Vector3.new(0, 0, 0)

		local ok, _ = pcall(function()
			if UIS:IsKeyDown(Enum.KeyCode.W) then
				moveDir = moveDir + camCF.LookVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.S) then
				moveDir = moveDir - camCF.LookVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.A) then
				moveDir = moveDir - camCF.RightVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.D) then
				moveDir = moveDir + camCF.RightVector
			end
			if UIS:IsKeyDown(Enum.KeyCode.Space) or flyUp then
				moveDir = moveDir + Vector3.new(0, 1, 0)
			end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or flyDown then
				moveDir = moveDir - Vector3.new(0, 1, 0)
			end
		end)

		-- Fallback móvil: leer MoveDirection del humanoid
		if not ok or moveDir.Magnitude < 0.1 then
			local hum2 = char and char:FindFirstChild("Humanoid")
			if hum2 and hum2.MoveDirection.Magnitude > 0.1 then
				moveDir = moveDir + hum2.MoveDirection
			end
			if flyUp   then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if flyDown then moveDir = moveDir - Vector3.new(0, 1, 0) end
		end

		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit
		end

		flyBV.Velocity = moveDir * Settings.FlySpeed
		flyBG.CFrame   = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
	end)
end

local function stopFly()
	if flyConn then flyConn:Disconnect() flyConn = nil end
	if flyBV   then flyBV:Destroy()      flyBV   = nil end
	if flyBG   then flyBG:Destroy()      flyBG   = nil end
	local h = player.Character and player.Character:FindFirstChild("Humanoid")
	if h then h.PlatformStand = false end
	flyUp   = false
	flyDown = false
end

--// ─────────────────────────────────────
--//  HEADLESS
--// ─────────────────────────────────────
local function applyHeadless()
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	head.Transparency = 1
	for _, p in pairs(head:GetDescendants()) do
		if p:IsA("BasePart") or p:IsA("Decal") then
			p.Transparency = 1
		end
	end
end

local function removeHeadless()
	local char = player.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	head.Transparency = 0
	for _, p in pairs(head:GetDescendants()) do
		if p:IsA("Decal") then p.Transparency = 0 end
	end
end

--// ─────────────────────────────────────
--//  BACKGROUND LOOPS
--// ─────────────────────────────────────

-- AUTO GUN TP
task.spawn(function()
	while true do
		task.wait(0.3)
		if Toggles.AutoGunTP and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			for _, v in pairs(workspace:GetDescendants()) do
				if v.Name == "GunDrop" and v:IsA("BasePart") then
					hrp.CFrame = v.CFrame
					break
				end
			end
		end
	end
end)

-- AUTO GUN SILENT (TP ida y vuelta en mismo frame)
task.spawn(function()
	while true do
		task.wait(0.3)
		if Toggles.AutoGunSilent and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			local origin = hrp.CFrame
			for _, v in pairs(workspace:GetDescendants()) do
				if v.Name == "GunDrop" and v:IsA("BasePart") then
					hrp.CFrame = v.CFrame
					task.wait()         -- un frame para que el servidor registre
					hrp.CFrame = origin -- volver
					break
				end
			end
		end
	end
end)

-- AUTO KILL SHERIFF — loop permanente por partida
task.spawn(function()
	while true do
		task.wait(0.15)
		if Toggles.AutoKillSheriff and isLocalMurder() then
			local stab = getKnifeStab()
			if stab then
				for _, plr in pairs(Players:GetPlayers()) do
					if plr ~= player and plr.Character and getRole(plr) == "Sheriff" then
						pcall(function() stab:FireServer(plr.Character) end)
					end
				end
			end
		end
	end
end)

-- AUTO KILL ALL
task.spawn(function()
	while true do
		task.wait(0.15)
		if Toggles.AutoKillAll and isLocalMurder() then
			local stab = getKnifeStab()
			if stab then
				for _, plr in pairs(Players:GetPlayers()) do
					if plr ~= player and plr.Character then
						pcall(function() stab:FireServer(plr.Character) end)
					end
				end
			end
		end
	end
end)

-- AUTO COINS — va a la más cercana sin delay entre monedas
task.spawn(function()
	while true do
		if not Toggles.AutoCoins then task.wait(0.1) continue end
		local char = player.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then task.wait(0.1) continue end
		local coin, minD = nil, math.huge
		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and (v.Name == "MainCoin" or v.Name == "Coin") then
				local d = (hrp.Position - v.Position).Magnitude
				if d < minD then minD = d coin = v end
			end
		end
		if coin then hrp.CFrame = CFrame.new(coin.Position) end
		task.wait(0.02)
	end
end)

-- AUTO DODGE
task.spawn(function()
	while true do
		task.wait(0.1)
		if Toggles.AutoDodge then
			local char = player.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end
			for _, plr in pairs(Players:GetPlayers()) do
				if plr == player or getRole(plr) ~= "Murder" then continue end
				local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if h and (hrp.Position - h.Position).Magnitude < 15 then
					hrp.CFrame = hrp.CFrame + (hrp.Position - h.Position).Unit * 20
				end
			end
		end
	end
end)

-- AUTO HIDE
task.spawn(function()
	while true do
		task.wait(1)
		if Toggles.AutoHide and isLocalInnocent() then
			local char = player.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local m = getNearestMurder()
				if m and m.Character then
					local mh = m.Character:FindFirstChild("HumanoidRootPart")
					if mh and (hrp.Position - mh.Position).Magnitude < 40 then
						local away = (hrp.Position - mh.Position).Unit * 50
						hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(away.X, 0, away.Z))
					end
				end
			end
		end
	end
end)

-- ANTI AFK
task.spawn(function()
	while true do
		task.wait(60)
		if Toggles.AntiAFK then
			local ok, VU = pcall(function() return game:GetService("VirtualUser") end)
			if ok and VU then
				VU:Button2Down(Vector2.new(0, 0), camera.CFrame)
				task.wait(0.1)
				VU:Button2Up(Vector2.new(0, 0), camera.CFrame)
			end
		end
	end
end)

-- NOCLIP
RunService.Stepped:Connect(function()
	if Toggles.Noclip and player.Character then
		for _, p in pairs(player.Character:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
end)

-- GOD MODE
RunService.Stepped:Connect(function()
	if Toggles.GodMode then
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		if hum and hum.Health < hum.MaxHealth then
			hum.Health = hum.MaxHealth
		end
	end
end)

-- HEADLESS
RunService.Stepped:Connect(function()
	if Toggles.Headless then applyHeadless() end
end)

-- SPINNER
local spinAngle = 0
RunService.Heartbeat:Connect(function()
	if not Toggles.Spinner then return end
	local char = player.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	spinAngle = (spinAngle + Settings.SpinSpeed) % 360
	hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
end)

-- ESP
local espHL = {}
local espBB = {}
local espLN = {}

local function removeESP(plr)
	if espHL[plr] then espHL[plr]:Destroy() espHL[plr] = nil end
end

local function applyESP(plr, color)
	local char = plr.Character
	if not char then return end
	local ex = char:FindFirstChildOfClass("Highlight")
	if ex then
		if ex.FillColor == color then return end
		ex:Destroy()
	end
	local h = Instance.new("Highlight")
	h.FillColor = color; h.FillTransparency = 0.5
	h.OutlineColor = color; h.OutlineTransparency = 0
	h.Parent = char
	espHL[plr] = h
end

RunService.Heartbeat:Connect(function()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == player then continue end
		local char = plr.Character
		if not char then removeESP(plr) continue end
		local role = getRole(plr)

		if   role == "Murder"   and Toggles.ESP_Murder   then applyESP(plr, Color3.fromRGB(255, 50, 50))
		elseif role == "Sheriff"  and Toggles.ESP_Sheriff  then applyESP(plr, Color3.fromRGB(50, 100, 255))
		elseif role == "Innocent" and Toggles.ESP_Innocent then applyESP(plr, Color3.fromRGB(50, 255, 100))
		else
			local show = (role == "Murder"   and Toggles.ESP_Murder)
				or (role == "Sheriff"  and Toggles.ESP_Sheriff)
				or (role == "Innocent" and Toggles.ESP_Innocent)
			if not show then removeESP(plr) end
		end

		local head = char:FindFirstChild("Head")
		local hrp  = char:FindFirstChild("HumanoidRootPart")

		if Toggles.ESP_Names and head then
			if not espBB[plr] then
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.new(0, 140, 0, 30)
				bb.StudsOffset = Vector3.new(0, 3, 0)
				bb.AlwaysOnTop = true; bb.Parent = head
				local lb = Instance.new("TextLabel", bb)
				lb.Size = UDim2.new(1, 0, 1, 0)
				lb.BackgroundTransparency = 1
				lb.TextColor3 = Color3.new(1, 1, 1)
				lb.Font = Enum.Font.GothamBold
				lb.TextSize = 14; lb.Text = plr.Name
				lb.TextStrokeTransparency = 0
				espBB[plr] = bb
			end
		else
			if espBB[plr] then espBB[plr]:Destroy() espBB[plr] = nil end
		end

		if Toggles.ESP_Lines and hrp then
			if not espLN[plr] then
				local ln = Drawing.new("Line")
				ln.Visible = true; ln.Thickness = 1
				espLN[plr] = ln
			end
			local sp, on = camera:WorldToViewportPoint(hrp.Position)
			if on then
				espLN[plr].From    = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
				espLN[plr].To      = Vector2.new(sp.X, sp.Y)
				espLN[plr].Visible = true
				espLN[plr].Color   = role == "Murder"  and Color3.fromRGB(255, 50, 50)
					or role == "Sheriff" and Color3.fromRGB(50, 100, 255)
					or Color3.fromRGB(50, 255, 100)
			else
				espLN[plr].Visible = false
			end
		else
			if espLN[plr] then espLN[plr].Visible = false end
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	removeESP(plr)
	if espBB[plr] then espBB[plr]:Destroy() espBB[plr] = nil end
	if espLN[plr] then espLN[plr]:Remove()  espLN[plr] = nil end
end)

-- AIMBOT
local mouseHeld = false
UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.UserInputType == Enum.UserInputType.MouseButton1 then mouseHeld = true end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then mouseHeld = false end
end)

RunService.RenderStepped:Connect(function()
	if not Toggles.Aimbot then return end
	local t = getNearestMurder()
	if not t or not t.Character then return end
	local head = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
	if not head then return end
	camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, head.Position), 0.3)
end)

task.spawn(function()
	while true do
		task.wait(0.05)
		if Toggles.Aimbot and mouseHeld then
			local char = player.Character; if not char then continue end
			local hasGun = player.Backpack:FindFirstChild("Gun") or char:FindFirstChild("Gun")
			if not hasGun then continue end
			local t = getNearestMurder()
			if t and t.Character then
				local head  = t.Character:FindFirstChild("Head") or t.Character:FindFirstChild("HumanoidRootPart")
				local hrp   = t.Character:FindFirstChild("HumanoidRootPart")
				local myHrp = char:FindFirstChild("HumanoidRootPart")
				if head then camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position) end
				if hrp and myHrp and (myHrp.Position - hrp.Position).Magnitude > 8 then
					local offset = (myHrp.Position - hrp.Position).Unit * 4
					myHrp.CFrame = CFrame.new(hrp.Position + offset + Vector3.new(0, 2, 0))
				end
				GunKill:FireServer(t.Character)
				GunKill:FireServer(t.Character)
				GunKill:FireServer(t.Character)
			end
		end
	end
end)

player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid")
	hum.WalkSpeed = Settings.WalkSpeed
	hum.JumpPower = Settings.JumpPower
end)

--// ═══════════════════════════════════════════
--//  GUI — TEMA AZUL BRILLANTE
--// ═══════════════════════════════════════════
local C = {
	bg0   = Color3.fromRGB(8,  10,  18),
	bg1   = Color3.fromRGB(12, 15,  25),
	bg2   = Color3.fromRGB(18, 22,  38),
	bg3   = Color3.fromRGB(24, 30,  50),
	blue  = Color3.fromRGB(30, 130, 255),
	blue2 = Color3.fromRGB(15,  70, 180),
	blue3 = Color3.fromRGB( 5,  25,  70),
	cyan  = Color3.fromRGB(80, 200, 255),
	white = Color3.fromRGB(220, 225, 240),
	gray  = Color3.fromRGB(90,  100, 130),
	dark  = Color3.fromRGB(10,  15,  35),
	darkb = Color3.fromRGB( 5,  20,  50),
}

local function corner(p, r)
	local c = Instance.new("UICorner", p)
	c.CornerRadius = UDim.new(0, r or 8)
	return c
end

local function mkList(p, pad, dir)
	local ll = Instance.new("UIListLayout", p)
	ll.Padding       = UDim.new(0, pad or 5)
	ll.FillDirection = dir or Enum.FillDirection.Vertical
	ll.SortOrder     = Enum.SortOrder.LayoutOrder
	return ll
end

local function mkPad(p, l, r2, t, b)
	local u = Instance.new("UIPadding", p)
	u.PaddingLeft   = UDim.new(0, l  or 8)
	u.PaddingRight  = UDim.new(0, r2 or 8)
	u.PaddingTop    = UDim.new(0, t  or 6)
	u.PaddingBottom = UDim.new(0, b  or 6)
end

-- SCREENGUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name          = "PRO_MM2"
gui.ResetOnSpawn  = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- MAIN FRAME
local main = Instance.new("Frame", gui)
main.Size                = UDim2.new(0, 480, 0, 560)
main.Position            = UDim2.new(0.5, -240, 0.5, -280)
main.BackgroundColor3    = C.bg0
main.BorderSizePixel     = 0
main.ClipsDescendants    = true
corner(main, 10)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color     = C.blue2
mainStroke.Thickness = 1

-- DRAG
local dragging, dragStart, startPos = false, nil, nil
main.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
		dragging  = true
		dragStart = i.Position
		startPos  = main.Position
	end
end)
UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
		or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y
		)
	end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- TOPBAR
local topbar = Instance.new("Frame", main)
topbar.Size             = UDim2.new(1, 0, 0, 42)
topbar.BackgroundColor3 = C.bg1
topbar.BorderSizePixel  = 0

local topLine = Instance.new("Frame", topbar)
topLine.Size             = UDim2.new(1, 0, 0, 2)
topLine.Position         = UDim2.new(0, 0, 1, -2)
topLine.BackgroundColor3 = C.blue
topLine.BorderSizePixel  = 0

local logoBox = Instance.new("Frame", topbar)
logoBox.Size             = UDim2.new(0, 26, 0, 26)
logoBox.Position         = UDim2.new(0, 10, 0.5, -13)
logoBox.BackgroundColor3 = C.blue
corner(logoBox, 5)
local logoTri = Instance.new("TextLabel", logoBox)
logoTri.Size                 = UDim2.new(1, 0, 1, 0)
logoTri.BackgroundTransparency = 1
logoTri.Text                 = "▲"
logoTri.TextColor3           = Color3.new(1, 1, 1)
logoTri.Font                 = Enum.Font.GothamBold
logoTri.TextSize             = 13
logoTri.TextXAlignment       = Enum.TextXAlignment.Center

local titleLbl = Instance.new("TextLabel", topbar)
titleLbl.Size                 = UDim2.new(0,
