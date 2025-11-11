--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local fov = 296
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local Cam = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Aimbot ligado por padrão
local aimbotEnabled = true

-- Círculo FOV
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(128, 0, 255)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2
FOVring.Transparency = 1

-- Tabela de ESPs
local ESPs = {}

local function updateDrawings()
	FOVring.Position = Cam.ViewportSize / 2
end

-- GUI: Painel inferior com "Aimbot Status :" e bolinha clicável
local function createStatusGui()
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or Instance.new("ScreenGui", LocalPlayer)
	if not playerGui.Parent then
		playerGui.Name = "LeviathanAimbotGui"
		playerGui.ResetOnSpawn = false
		playerGui.Parent = LocalPlayer
	end

	local existing = playerGui:FindFirstChild("LeviathanAimbotGuiFrame")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LeviathanAimbotGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "StatusFrame"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -30)
	frame.Size = UDim2.new(0, 260, 0, 28)
	frame.BackgroundTransparency = 0.2
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local uic = Instance.new("UICorner", frame)
	uic.CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Name = "StatusLabel"
	label.Text = "Aimbot Status :"
	label.TextSize = 14
	label.Font = Enum.Font.SourceSansSemibold
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0, 180, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local dotBtn = Instance.new("TextButton")
	dotBtn.Name = "StatusDot"
	dotBtn.AnchorPoint = Vector2.new(1, 0.5)
	dotBtn.Position = UDim2.new(1, -8, 0.5, 0)
	dotBtn.Size = UDim2.new(0, 20, 0, 20)
	dotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
	dotBtn.BorderSizePixel = 0
	dotBtn.Text = ""
	dotBtn.Parent = frame
	local dotCorner = Instance.new("UICorner", dotBtn)
	dotCorner.CornerRadius = UDim.new(1, 0)

	local function updateDot()
		if dotBtn and dotBtn.Parent then
			dotBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
		end
	end

	dotBtn.MouseButton1Click:Connect(function()
		aimbotEnabled = not aimbotEnabled
		updateDot()
	end)

	return {
		Update = updateDot,
		Destroy = function()
			if screenGui then screenGui:Destroy() end
		end
	}
end

local statusGuiController = createStatusGui()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.H then
			aimbotEnabled = not aimbotEnabled
			if statusGuiController and statusGuiController.Update then statusGuiController.Update() end
		elseif input.KeyCode == Enum.KeyCode.Delete then
			RunService:UnbindFromRenderStep("FOVUpdate")
			FOVring:Remove()
			for _, esp in pairs(ESPs) do
				if esp.Box then esp.Box:Remove() end
				if esp.Name then esp.Name:Remove() end
				if esp.Health then esp.Health:Remove() end
				if esp.Tracer then esp.Tracer:Remove() end
			end
			if statusGuiController and statusGuiController.Destroy then statusGuiController.Destroy() end
		end
	end
end)

local function lookAt(target)
	local lookVector = (target - Cam.CFrame.Position).unit
	local newCFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVector)
	Cam.CFrame = newCFrame
end

local function hasLineOfSight(part)
	local origin = Cam.CFrame.Position
	local direction = part.Position - origin
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction, params)
	if not result then
		return true
	end
	return result.Instance:IsDescendantOf(part.Parent)
end

-- Cria ESP (quadrado + nome + vida + linha)
local function createESP(player)
	local box = Drawing.new("Square")
	box.Color = Color3.fromRGB(128, 0, 255)
	box.Thickness = 2
	box.Filled = false
	box.Visible = false

	local name = Drawing.new("Text")
	name.Text = player.Name
	name.Size = 14
	name.Color = Color3.fromRGB(170, 0, 255)
	name.Outline = true
	name.OutlineColor = Color3.fromRGB(0, 0, 0)
	name.Center = true
	name.Font = 3
	name.Visible = false

	local health = Drawing.new("Text")
	health.Size = 14
	health.Color = Color3.fromRGB(200, 0, 255)
	health.Outline = true
	health.OutlineColor = Color3.fromRGB(0, 0, 0)
	health.Center = true
	health.Font = 3
	health.Visible = false

	local tracer = Drawing.new("Line")
	tracer.Color = Color3.fromRGB(170, 0, 255)
	tracer.Thickness = 1.5
	tracer.Visible = false

	ESPs[player] = { Box = box, Name = name, Health = health, Tracer = tracer }
end

local function updateESP(player)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		if ESPs[player] then
			ESPs[player].Box.Visible = false
			ESPs[player].Name.Visible = false
			ESPs[player].Health.Visible = false
			if ESPs[player].Tracer then ESPs[player].Tracer.Visible = false end
		end
		return
	end

	local hrp = player.Character.HumanoidRootPart
	local head = player.Character:FindFirstChild("Head")
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

	local pos = Cam:WorldToViewportPoint(hrp.Position)
	local top = Cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
	local bottom = Cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
	local box = ESPs[player].Box
	local name = ESPs[player].Name
	local health = ESPs[player].Health
	local tracer = ESPs[player].Tracer

	if pos.Z > 0 then
		local height = math.abs(top.Y - bottom.Y)
		local width = height * 0.6
		box.Size = Vector2.new(width, height)
		box.Position = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
		box.Visible = true

		if head then
			local headPos = Cam:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
			name.Position = Vector2.new(headPos.X, headPos.Y)
			name.Visible = true
		end

		if humanoid then
			local hp = math.floor(humanoid.Health)
			local maxHp = math.floor(humanoid.MaxHealth)
			health.Text = "[" .. tostring(hp) .. " / " .. tostring(maxHp) .. " HP]"
			local hpPos = Cam:WorldToViewportPoint(head.Position + Vector3.new(0, 1.9, 0))
			health.Position = Vector2.new(hpPos.X, hpPos.Y)
			health.Visible = true
		end

		-- Linha da SUA POSIÇÃO atual até o player (tracer)
		local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if myRoot then
			local myPos3, myOnScreen = Cam:WorldToViewportPoint(myRoot.Position)
			local rootPos3, rootOnScreen = Cam:WorldToViewportPoint(hrp.Position)
			-- Desenha se pelo menos o alvo estiver à frente da câmera
			if rootPos3.Z > 0 then
				tracer.From = Vector2.new(myPos3.X, myPos3.Y)
				tracer.To = Vector2.new(rootPos3.X, rootPos3.Y)
				tracer.Visible = true
			else
				tracer.Visible = false
			end
		else
			-- Se não tiver HumanoidRootPart local, esconde tracer
			tracer.Visible = false
		end
	else
		box.Visible = false
		name.Visible = false
		health.Visible = false
		tracer.Visible = false
	end
end

local function getClosestPlayerInFOV(trg_part)
	local nearest = nil
	local last = math.huge
	local center = Cam.ViewportSize / 2

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local part = player.Character:FindFirstChild(trg_part)
			if part then
				local pos, visible = Cam:WorldToViewportPoint(part.Position)
				local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
				if visible and dist < fov and hasLineOfSight(part) then
					if dist < last then
						last = dist
						nearest = player
					end
				end
			end
		end
	end
	return nearest
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		createESP(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		createESP(player)
	end
end

RunService.RenderStepped:Connect(function()
	updateDrawings()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and ESPs[player] then
			updateESP(player)
		end
	end

	if aimbotEnabled then
		local closest = getClosestPlayerInFOV("Head")
		if closest and closest.Character and closest.Character:FindFirstChild("Head") then
			lookAt(closest.Character.Head.Position)
		end
	end
end)
