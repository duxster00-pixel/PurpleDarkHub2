-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ================= UI BASE (IMGUI STYLE) =================
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "ImGuiHub"

local Blur = Instance.new("BlurEffect", game.Lighting)
Blur.Size = 0

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 340)
Main.Position = UDim2.new(0.5, -260, 0.5, -170)
Main.BackgroundColor3 = Color3.fromRGB(20,20,30)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,10)

TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 16}):Play()

-- OPEN/CLOSE
local Open = true
UIS.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.RightShift then
		Open = not Open
		Main.Visible = Open
		Blur.Size = Open and 16 or 0
	end
end)

-- ================= TAB SYSTEM =================
local Tabs = {}
local Buttons = Instance.new("Frame", Main)
Buttons.Size = UDim2.new(0,120,1,0)
Buttons.BackgroundColor3 = Color3.fromRGB(25,25,40)

local Pages = Instance.new("Frame", Main)
Pages.Position = UDim2.new(0,120,0,0)
Pages.Size = UDim2.new(1,-120,1,0)
Pages.BackgroundTransparency = 1

local function CreateTab(name)
	local btn = Instance.new("TextButton", Buttons)
	btn.Size = UDim2.new(1,0,0,32)
	btn.Text = name
	btn.Font = Enum.Font.Code
	btn.TextSize = 14
	btn.BackgroundColor3 = Color3.fromRGB(35,35,55)
	btn.TextColor3 = Color3.fromRGB(200,200,255)

	local page = Instance.new("Frame", Pages)
	page.Size = UDim2.new(1,0,1,0)
	page.Visible = false
	page.BackgroundTransparency = 1

	btn.MouseButton1Click:Connect(function()
		for _,v in pairs(Pages:GetChildren()) do v.Visible = false end
		page.Visible = true
	end)

	if #Pages:GetChildren() == 1 then page.Visible = true end
	return page
end

-- ================= TABS =================
local ViewTab = CreateTab("View")
local LocalTab = CreateTab("Local")
local ESPTab = CreateTab("ESP")
local AimTab = CreateTab("Aim")

-- ================= VIEW PLAYERS =================
local y = 10
for _,plr in pairs(Players:GetPlayers()) do
	local t = Instance.new("TextLabel", ViewTab)
	t.Position = UDim2.new(0,10,0,y)
	t.Size = UDim2.new(0,200,0,22)
	t.Text = plr.Name
	t.TextColor3 = Color3.new(1,1,1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Code
	y += 22
end

-- ================= LOCALPLAYER =================
local Char, Humanoid
local function RefreshChar()
	Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	Humanoid = Char:WaitForChild("Humanoid")
end
RefreshChar()
LocalPlayer.CharacterAdded:Connect(RefreshChar)

local function LPButton(txt, y, cb)
	local b = Instance.new("TextButton", LocalTab)
	b.Position = UDim2.new(0,10,0,y)
	b.Size = UDim2.new(0,200,0,28)
	b.Text = txt
	b.Font = Enum.Font.Code
	b.TextSize = 13
	b.BackgroundColor3 = Color3.fromRGB(90,0,160)
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b)
	b.MouseButton1Click:Connect(cb)
end

LPButton("Speed 50",10,function() Humanoid.WalkSpeed = 50 end)
LPButton("JumpPower 120",44,function() Humanoid.JumpPower = 120 end)

local Noclip=false
RunService.Stepped:Connect(function()
	if Noclip and Char then
		for _,v in pairs(Char:GetDescendants()) do
			if v:IsA("BasePart") then v.CanCollide=false end
		end
	end
end)
LPButton("Toggle Noclip",78,function() Noclip = not Noclip end)

-- ================= ESP + TRACERS =================
local ESPEnabled=false
local TracersEnabled=false
local Drawings={}

local function ClearESP(plr)
	if Drawings[plr] then
		for _,d in pairs(Drawings[plr]) do d:Remove() end
		Drawings[plr]=nil
	end
end

RunService.RenderStepped:Connect(function()
	for _,plr in pairs(Players:GetPlayers()) do
		if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			if not Drawings[plr] then
				Drawings[plr]={}
				local line=Drawing.new("Line")
				line.Color=Color3.fromRGB(180,160,255)
				line.Thickness=1.5
				Drawings[plr].Tracer=line
			end
			local hrp=plr.Character.HumanoidRootPart
			local pos,vis=Camera:WorldToViewportPoint(hrp.Position)
			if vis and ESPEnabled and TracersEnabled then
				Drawings[plr].Tracer.Visible=true
				Drawings[plr].Tracer.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
				Drawings[plr].Tracer.To=Vector2.new(pos.X,pos.Y)
			else
				Drawings[plr].Tracer.Visible=false
			end
		else
			ClearESP(plr)
		end
	end
end)

Players.PlayerRemoving:Connect(ClearESP)

local function ESPBtn(txt,y,cb)
	local b=Instance.new("TextButton",ESPTab)
	b.Position=UDim2.new(0,10,0,y)
	b.Size=UDim2.new(0,180,0,26)
	b.Text=txt
	b.Font=Enum.Font.Code
	b.TextSize=13
	b.BackgroundColor3=Color3.fromRGB(45,45,45)
	b.TextColor3=Color3.fromRGB(220,220,220)
	Instance.new("UICorner",b)
	b.MouseButton1Click:Connect(cb)
end

ESPBtn("Toggle ESP",10,function() ESPEnabled=not ESPEnabled end)
ESPBtn("Toggle Tracers",42,function() TracersEnabled=not TracersEnabled end)

-- ================= HEAD HITBOX =================
local HeadEnabled=false
local HeadSize=Vector3.new(6,6,6)
local HeadCache={}

RunService.RenderStepped:Connect(function()
	for _,plr in pairs(Players:GetPlayers()) do
		if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
			local h=plr.Character.Head
			if HeadEnabled then
				if not HeadCache[plr] then
					HeadCache[plr]={h.Size,h.Transparency}
				end
				h.Size=HeadSize
				h.Transparency=0.6
				h.Material=Enum.Material.Neon
			elseif HeadCache[plr] then
				h.Size=HeadCache[plr][1]
				h.Transparency=HeadCache[plr][2]
				HeadCache[plr]=nil
			end
		end
	end
end)

ESPBtn("Toggle Head Hitbox",74,function() HeadEnabled=not HeadEnabled end)

-- ================= AIM =================
local AimEnabled=false
local AimFOV=120

local Circle=Drawing.new("Circle")
Circle.Radius=AimFOV
Circle.Color=Color3.fromRGB(180,160,255)
Circle.Thickness=1.5
Circle.NumSides=64
Circle.Filled=false

local function GetTarget()
	local c=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
	local best,dist=nil,AimFOV
	for _,plr in pairs(Players:GetPlayers()) do
		if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
			local p,vis=Camera:WorldToViewportPoint(plr.Character.Head.Position)
			if vis then
				local d=(Vector2.new(p.X,p.Y)-c).Magnitude
				if d<dist then dist=d best=plr end
			end
		end
	end
	return best
end

RunService.RenderStepped:Connect(function()
	Circle.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
	Circle.Visible=AimEnabled
	if AimEnabled then
		local t=GetTarget()
		if t and t.Character then
			Camera.CFrame=CFrame.new(Camera.CFrame.Position,t.Character.Head.Position)
		end
	end
end)

local aimBtn=Instance.new("TextButton",AimTab)
aimBtn.Position=UDim2.new(0,10,0,10)
aimBtn.Size=UDim2.new(0,180,0,26)
aimBtn.Text="Toggle Aim"
aimBtn.Font=Enum.Font.Code
aimBtn.TextSize=13
aimBtn.BackgroundColor3=Color3.fromRGB(45,45,45)
aimBtn.TextColor3=Color3.fromRGB(220,220,220)
Instance.new("UICorner",aimBtn)
aimBtn.MouseButton1Click:Connect(function() AimEnabled=not AimEnabled end)
