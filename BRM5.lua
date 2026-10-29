local repo = 'https://raw.githubusercontent.com/longhazem/Tokaihawk/main/'

-- gen3: push tokaihawk_gen3.lua (self-contained, includes Airflow) +
-- addons/ThemeManager.lua + addons/SaveManager.lua to the SAME repo path
-- LinoriaSrc.lua lived at, then this URL just works — same pattern as before.
local LibrarySourceUrl = 'https://raw.githubusercontent.com/longhazem/Tokaihawk/main/tokaihawk_gen3.lua'
local LibrarySource = LibrarySourceUrl ~= '' and game:HttpGet(LibrarySourceUrl) or readfile('tokaihawk_gen3.lua')


local previousLibrary = getgenv().LinoriaMenuLibrary
if previousLibrary and not previousLibrary.Unloaded then previousLibrary:Unload() end
local Library = assert(loadstring(LibrarySource, 'tokaihawk_gen3.lua'))()
getgenv().LinoriaMenuLibrary = Library
do
    local InputService=game:GetService("UserInputService")
function Library:IsTyping()
    if InputService:GetFocusedTextBox() or self.FocusedTextBox or os.clock() < (self.TypingUntil or 0) then return true end
    local ok, focused = pcall(function()
        return game:GetService("TextChatService").ChatInputBarConfiguration.IsFocused
    end)
    return ok and focused == true
end
table.insert(Library.Signals, InputService.TextBoxFocused:Connect(function(box)
    Library.FocusedTextBox = box
end))
table.insert(Library.Signals, InputService.TextBoxFocusReleased:Connect(function(box)
    if Library.FocusedTextBox == box then Library.FocusedTextBox = nil end
    Library.TypingUntil = os.clock() + .15
end))

    local originalToggle=Library.Toggle
    Library.Toggle=function(...)
        if Library:IsTyping() then return end
        return originalToggle(...)
    end
end
local reloadState = getfenv().STATE
if type(reloadState)=="table" and type(reloadState.onCleanup)=="function" then
    reloadState.onCleanup(function() if not Library.Unloaded then Library:Unload() end end)
end
local Toggles, Options = getgenv().Toggles, getgenv().Options
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

ThemeManager.BuiltInThemes.Clean = { 0, {
    FontColor = 'E8E8E8', MainColor = '1D1D1D', BackgroundColor = '141414',
    AccentColor = 'BEBEBE', OutlineColor = '383838'
} }
ThemeManager.DefaultTheme = 'Clean'

local Fonts: {[string]: any} = {
    UIName = 'Code', Face = Font.fromEnum(Library.Font), Cache = {}, Version = 0,
    Names = { 'Code', 'Arial', 'Gotham', 'Source Sans', 'Roboto Mono', 'Ubuntu', 'Tahoma', 'Minecraftia', 'Verdana', 'Proggy Clean', 'Builder Sans', 'Arimo', 'Roboto', 'Roboto Condensed', 'Gotham Medium', 'Gotham Bold', 'Nunito', 'Oswald', 'Source Sans Semibold' },
    Builtins = { Code = Enum.Font.Code, Arial = Enum.Font.Arial, Gotham = Enum.Font.Gotham,
        ['Source Sans'] = Enum.Font.SourceSans, ['Roboto Mono'] = Enum.Font.RobotoMono, Ubuntu = Enum.Font.Ubuntu,
        ['Builder Sans']=Enum.Font.BuilderSans, Arimo=Enum.Font.Arimo, Roboto=Enum.Font.Roboto,
        ['Roboto Condensed']=Enum.Font.RobotoCondensed, ['Gotham Medium']=Enum.Font.GothamMedium,
        ['Gotham Bold']=Enum.Font.GothamBold, Nunito=Enum.Font.Nunito, Oswald=Enum.Font.Oswald,
        ['Source Sans Semibold']=Enum.Font.SourceSansSemibold },
    Files = { Tahoma = 'Tahoma-Modern.ttf', Minecraftia = 'Minecraftia-Regular.ttf',
        Verdana = 'Verdana-Font.ttf', ['Proggy Clean'] = 'ProggyClean.ttf' },
}
function Fonts.Resolve(name)
    if Fonts.Cache[name] then return Fonts.Cache[name] end
    local enum = Fonts.Builtins[name]
    local face
    if enum then
        face = Font.fromEnum(enum)
    else
        local filename = assert(Fonts.Files[name], 'Unknown font: ' .. tostring(name))
        assert(getcustomasset and writefile and isfile and makefolder and isfolder, 'Custom font loading is unavailable')
        local folder = 'LinoriaFonts'
        if not isfolder(folder) then makefolder(folder) end
        local path = folder .. '/' .. filename
        if not isfile(path) then
            local data = game:HttpGet('https://raw.githubusercontent.com/longhazem/Tokaihawk/main/fonts/' .. filename)
            assert(#data > 1024, 'Font download is incomplete')
            writefile(path, data)
        end
        local manifest = folder .. '/' .. filename .. '.json'
        writefile(manifest, game:GetService('HttpService'):JSONEncode({
            name = name, faces = { { name = 'Regular', weight = 400, style = 'normal', assetId = getcustomasset(path) } },
        }))
        face = Font.new(getcustomasset(manifest))
    end
    local params = Instance.new('GetTextBoundsParams')
    params.Font = face; params.Text = 'Font'; params.Size = 14; params.Width = 200
    local textService: any = game:GetService('TextService')
    local ok, result = pcall(function() return textService:GetTextBoundsAsync(params) end)
    params:Destroy()
    assert(ok, tostring(result))
    Fonts.Cache[name] = face
    return face
end
function Fonts.Apply(instance)
    if instance:IsA('TextLabel') or instance:IsA('TextButton') or instance:IsA('TextBox') then
        instance.FontFace = Fonts.Face
    end
end
function Fonts.SetUI(name)
    local face = Fonts.Resolve(name)
    if Library.Unloaded then return end
    Fonts.UIName = name; Fonts.Face = face; Fonts.Version += 1
    Library.Font = Fonts.Builtins[name] or Enum.Font.Code
    for _, instance in ipairs(Fonts.Root:GetDescendants()) do Fonts.Apply(instance) end
end
local createWithDefaultFont = Library.Create
Library.Create = function(self, class, properties)
    local instance = createWithDefaultFont(self, class, properties)
    Fonts.Apply(instance)
    return instance
end

local Window = Library:CreateWindow({
    Title = 'Tokaihub | BRM5',
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(568, 660),
    TabPadding = 6,
    MenuFadeTime = 0.16
})

Fonts.Root = Window.Holder:FindFirstAncestorWhichIsA('ScreenGui')
Library:GiveSignal(Fonts.Root.DescendantAdded:Connect(function(instance)
    Fonts.Apply(instance)
end))

local Tabs = {
    Main = Window:AddTab('Main'),
    Ragebot = Window:AddTab('Ragebot'),
    Visuals = Window:AddTab('Visuals'),
    Movement = Window:AddTab('Movement'),
    Mods = Window:AddTab('Mods'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local previousCombat = getgenv().LinoriaCombat
if previousCombat and previousCombat.Destroy then previousCombat.Destroy() end
local AimPlayers = game:GetService("Players")
local AimRunService = game:GetService("RunService")
local AimUIS = game:GetService("UserInputService")
local AimLocalPlayer = AimPlayers.LocalPlayer
local AimCamera = workspace.CurrentCamera
local Silent = {
    Enabled=false,Targets={NPCs=true,Players=true},HitPart="Head",Hitscan=false,TeamCheck=false,VisibleCheck=true,
    MaxDistance=1000,HitChance=100,StickyAim=false,FOVEnabled=true,ShowFOV=true,FOV=120,
    FOVColor=Color3.fromRGB(224,224,224),FillFOV=false,FOVFillColor=Color3.fromRGB(224,224,224),
    FOVFillTransparency=.4,GradientFOV=false,
    GradientSpin=false,GradientSpinSpeed=1,
    GradientColorA=Color3.fromRGB(224,224,224),GradientColorB=Color3.fromRGB(120,120,120),
    AutoPrediction=true,BulletDropCompensation=true,
}
local TriggerBotSettings = {
    Enabled=false,Targets={NPCs=true,Players=true},TeamCheck=false,VisibleCheck=true,
    MaxDistance=1000,ReactionTime=50,ShootTime=100,Magnetic=false,
}
local Rage = {
    Enabled=false,Targets={NPCs=true,Zombies=true,Players=true},HitPart="Head",
    Hitscan=true,TeamCheck=true,VisibleCheck=true,FullCircle=true,
    DistanceCheck=true,MaxDistance=1000,FOVEnabled=false,AutoPrediction=true,BulletDropCompensation=true,
}
local Combat: {[string]: any} = {
    Silent=Silent,Trigger=TriggerBotSettings,Rage=Rage,active=true,actors={},samples={},parts={},
    sticky=nil,target=nil,nextScan=0,lastShot=0,targetSince=0,triggerActor=nil,
    connections={},drawings={},hookState="Waiting for game adapter",
}
local SilentKeyPicker,TriggerKeyPicker,RageKeyPicker
local HitPartOptions={"Head","HumanoidRootPart","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm",
    "LeftUpperLeg","RightUpperLeg","Closest Part","Random"}
local function aim_getMouseLocation() return AimUIS:GetMouseLocation() end
function Combat.SetTargets(settings,selected)
    local result={}
    if type(selected)=="table" then
        for _,v in ipairs(selected) do if v=="NPCs" or v=="Players" or v=="Zombies" then result[v]=true end end
    end
    settings.Targets=result
    Combat.target=nil;Combat.sticky=nil;Combat.triggerActor=nil
end
function Combat.Service()
    if Combat.service then return Combat.service end
    if Combat.resolveAt and os.clock()<Combat.resolveAt then return nil end
    Combat.resolveAt=os.clock()+2
    for _,m in ipairs(getloadedmodules()) do
        if m.Name=="ClientService" then
            local ok,value=pcall(require,m)
            if ok and type(value)=="table" and value.Replicator then Combat.service=value;break end
        end
    end
    return Combat.service
end
function Combat.Inventory()
    if Combat.inventoryService then return Combat.inventoryService end
    if os.clock()<(Combat.inventoryRetry or 0) then return nil end
    Combat.inventoryRetry=os.clock()+1
    for _,module in ipairs(getloadedmodules()) do
        if module.Name=="InventoryService" then
            local ok,value=pcall(require,module)
            if ok and type(value)=="table" and type(value._inventories)=="table" then Combat.inventoryService=value;return value end
        end
    end
end
function Combat.Weapon()
    local inventory=Combat.Inventory()
    local entry=inventory and inventory.Equipped
    return entry and entry.Handler
end
function Combat.Weapons()
    local inventory=Combat.Inventory();local weapons={};local seen={}
    for _,group in pairs(inventory and inventory._inventories or {}) do
        for _,entry in pairs(group) do
            local w=entry.Handler
            if w and w._firearm and not seen[w] then seen[w]=true;weapons[#weapons+1]=w end
        end
    end
    return weapons
end
function Combat.IsTeammate(a)
    local owner=a and a.Owner
    if not owner then return false end
    if owner==AimLocalPlayer then return true end
    local service=Combat.Service()
    local clients=service and service.Clients
    local mine=clients and clients[AimLocalPlayer] or (service and service.LocalClient)
    local other=clients and clients[owner]
    if mine and other and mine.Squad~=nil and other.Squad~=nil and mine.Squad~="" and mine.Squad~="Neutral" then
        return mine.Squad==other.Squad
    end
    return AimLocalPlayer.Team~=nil and not AimLocalPlayer.Neutral and not owner.Neutral and owner.Team==AimLocalPlayer.Team
end
function Combat.Kind(actor)
    local c=Combat.Service()
    local registry=c and c.Replicator and c.Replicator.Actors
    if not registry or not actor or not actor.UID or registry[actor.UID]~=actor then return nil end
    if actor.IsLocalPlayer or actor.Owner==AimLocalPlayer or actor==c.Replicator.LocalActor then return nil end
    if actor.Zombie==true then return "Zombies" end
    if actor.Owner==nil then return "NPCs" end
    if typeof(actor.Owner)=="Instance" and actor.Owner:IsA("Player") then return "Players" end
end
function Combat.IsAlive(actor)
    if not actor or actor.Alive==false then return false end
    if actor.Zombie then
        return type(actor.Health)=="table" or (type(actor.Health)=="number" and actor.Health>0)
    end
    return type(actor.Health)=="number" and actor.Health>0
end
function Combat.Allowed(actor,settings)
    local kind=Combat.Kind(actor)
    if not kind or not settings.Targets[kind] then return false end
    if not Combat.IsAlive(actor) then return false end
    if not actor.Character or not actor.Character.Parent then return false end
    if settings.TeamCheck and kind=="Players" and Combat.IsTeammate(actor) then return false end
    return true
end
function Combat.Origin(camera)
    local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
    return me and me.Position or camera.CFrame.Position
end
function Combat.Sync(force)
    if not force and os.clock()<Combat.nextScan then return end
    Combat.nextScan=os.clock()+.05
    local c=Combat.Service();local registry=c and c.Replicator and c.Replicator.Actors or {}
    local list={};local now=os.clock()
    for _,a in pairs(registry) do
        if Combat.Kind(a) and typeof(a.Position)=="Vector3" then
            list[#list+1]=a
            local old=Combat.samples[a]
            local vel=Vector3.zero
            if old and old.model==a.Character and old.root==a.RootPart and now>old.time then
                local measured=(a.Position-old.position)/(now-old.time)
                local dt=now-old.time
                if dt<.35 and measured.Magnitude<300 then
                    vel=old.velocity:Lerp(measured,1-math.exp(-dt*18))
                    if measured.Magnitude<.1 then vel=Vector3.zero end
                end
            end
            local sample=old or {}
            sample.position=a.Position;sample.time=now;sample.velocity=vel
            sample.model=a.Character;sample.root=a.RootPart;Combat.samples[a]=sample
            -- Keep velocity sampling frequent while limiting body-part discovery.
            local cached=Combat.parts[a]
            if not cached or cached.model~=a.Character or cached.root~=a.RootPart or now>=(cached.refreshAt or 0) then
            local parts,seen={},{}
            local function add(p)
                if typeof(p)=="Instance" and p:IsA("BasePart") and a.Character
                    and p:IsDescendantOf(a.Character) and not seen[p] then
                    seen[p]=true;parts[#parts+1]=p
                end
            end
            for _,p in pairs(a.Parts or {}) do add(p) end
            if a.Character then for _,p in ipairs(a.Character:GetChildren()) do add(p) end end
            Combat.parts[a]={model=a.Character,root=a.RootPart,list=parts,refreshAt=now+.5}
            end
        end
    end
    for a in pairs(Combat.samples) do if not a.UID or registry[a.UID]~=a then Combat.samples[a]=nil;Combat.parts[a]=nil end end
    Combat.actors=list
end
function Combat.PartCFrame(actor,part)
    if not Combat.IsAlive(actor) then return part.CFrame end
    local root=actor.RootPart
    if not root or root:IsDescendantOf(workspace) then return part.CFrame end
    -- Parked WorldModel rigs are in local coordinates: apply the actor rotation,
    -- not just its translation. Live rigs already contain their rendered pose.
    local pose=typeof(actor.CFrame)=="CFrame" and actor.CFrame.Rotation or CFrame.identity
    local actorFrame=pose+actor.Position
    return actorFrame*root.CFrame:ToObjectSpace(part.CFrame)
end
function Combat.PartPosition(actor,part)
    return Combat.PartCFrame(actor,part).Position
end
local combatRayParams=RaycastParams.new()
combatRayParams.FilterType=Enum.RaycastFilterType.Exclude
combatRayParams.IgnoreWater=false
-- Match the collision group used by this game's projectile raycasts.
pcall(function() combatRayParams.CollisionGroup="9" end)
function Combat.Visible(actor,point,camera)
    local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
    local excluded={camera}
    if me and me.Character then excluded[#excluded+1]=me.Character end
    combatRayParams.FilterDescendantsInstances=excluded
    local hit=workspace:Raycast(camera.CFrame.Position,point-camera.CFrame.Position,combatRayParams)
    if not hit then return true end
    if actor.Character and hit.Instance:IsDescendantOf(actor.Character) then return true end
    -- Render rigs and collision bodies may be separate. Use the same actor
    -- identity mapping that the game's bullet-impact handler uses.
    local replicator=c and c.Replicator
    local registry=replicator and replicator.Actors
    if not registry or registry[actor.UID]~=actor then return false end
    local uid=hit.Instance:GetAttribute("ActorUID")
    if uid==actor.UID then return true end
    if type(replicator.GetFromBodyPart)=="function" then
        local ok,resolvedUID=pcall(replicator.GetFromBodyPart,replicator,hit.Instance)
        if ok and resolvedUID==actor.UID then return true end
    end
    return false
end
function Combat.PickPart(actor,settings,camera,mouse)
    local parts=actor.Parts or {}
    local option=settings.HitPart
    local function valid(part)
        return typeof(part)=="Instance" and part:IsA("BasePart") and actor.Character
            and part:IsDescendantOf(actor.Character)
    end
    if option=="HumanoidRootPart" then
        return valid(actor.RootPart) and actor.RootPart or actor.Character:FindFirstChild("HumanoidRootPart")
    end
    if option=="Closest Part" or option=="Random" then
        local best,distance,pool=nil,math.huge,{}
        for _,part in ipairs((Combat.parts[actor] or {}).list or {}) do
            if valid(part) then
                if option=="Random" then pool[#pool+1]=part else
                    local sp,on=camera:WorldToViewportPoint(Combat.PartPosition(actor,part))
                    if on then local d=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude;if d<distance then best,distance=part,d end end
                end
            end
        end
        if option=="Random" then return #pool>0 and pool[math.random(#pool)] or nil end
        return best
    end
    local part=parts[option]
    if valid(part) then return part end
    part=actor.Character:FindFirstChild(option)
    if valid(part) then return part end
    part=actor.Character:FindFirstChild("Head")
    if valid(part) then return part end
    if valid(parts.Head) then return parts.Head end
    if valid(actor.RootPart) then return actor.RootPart end
end
function Combat.Predict(actor,part,settings,camera)
    -- Screen selection uses the current position; shot prediction uses muzzle speed.
    return Combat.PartPosition(actor,part)
end
function Combat.FindTarget(settings,camera,mouse,sticky)
    Combat.Sync()
    camera=camera or workspace.CurrentCamera;mouse=mouse or aim_getMouseLocation()
    local origin=Combat.Origin(camera)
    local function candidate(a)
        if not Combat.Allowed(a,settings) then return nil end
        if settings.DistanceCheck~=false and (a.Position-origin).Magnitude>settings.MaxDistance then return nil end
        local function check(part,requireVisible)
            if not part or not part.Parent or not part:IsDescendantOf(a.Character) then return nil end
            local point=Combat.PartPosition(a,part)
            local sp,on=camera:WorldToViewportPoint(point)
            if not settings.FullCircle and not on then return nil end
            local d=settings.FullCircle and (point-origin).Magnitude or (Vector2.new(sp.X,sp.Y)-mouse).Magnitude
            if settings.FOVEnabled and d>settings.FOV then return nil end
            if (settings.VisibleCheck or requireVisible) and not Combat.Visible(a,point,camera) then return nil end
            return {actor=a,part=part,position=point,distance=d}
        end
        local preferred=Combat.PickPart(a,settings,camera,mouse)
        local selected=check(preferred,settings.Hitscan)
        if selected or not settings.Hitscan then return selected end
        local best
        for _,part in ipairs((Combat.parts[a] or {}).list or {}) do
            if part~=preferred and part~=a.RootPart then
                local hit=check(part,true)
                if hit and (not best or hit.distance<best.distance) then best=hit end
            end
        end
        -- Hitscan prefers exposed parts; Visible Check controls whether an occluded fallback is allowed.
        if not best and settings.FullCircle and not settings.VisibleCheck then return check(preferred,false) end
        return best
    end
    if settings.StickyAim and sticky then local current=candidate(sticky);if current then return current end end
    local best
    for _,a in ipairs(Combat.actors) do
        local current=candidate(a)
        if current and (not best or current.distance<best.distance) then best=current end
    end
    return best
end
local triggerAxes = {"X", "Y", "Z"}
function Combat.RayBox(origin,direction,cf,size)
    local p=cf:PointToObjectSpace(origin)
    local d=cf:VectorToObjectSpace(direction)
    local half=size*.5;local lo,hi=0,math.huge
    for _,axis in ipairs(triggerAxes) do
        if math.abs(d[axis])<1e-6 then if math.abs(p[axis])>half[axis] then return nil end
        else
            local a,b=(-half[axis]-p[axis])/d[axis],(half[axis]-p[axis])/d[axis]
            if a>b then a,b=b,a end
            lo=math.max(lo,a);hi=math.min(hi,b);if hi<lo then return nil end
        end
    end
    return lo
end
function Combat.TriggerTarget(settings,camera,mouse)
    if settings.Magnetic then
        local selected=Combat.target
        if Silent.Enabled and Combat.silentActive and selected and Combat.Allowed(selected.actor,settings)
            and (selected.actor.Position-Combat.Origin(camera)).Magnitude<=settings.MaxDistance
            and (not settings.VisibleCheck or Combat.Visible(selected.actor,selected.position,camera)) then return selected.actor end
        return nil
    end
    Combat.Sync()
    local ray=camera:ViewportPointToRay(mouse.X,mouse.Y)
    local closest,nearest=nil,settings.MaxDistance
    -- Test all actor bodies before applying the target filter: an excluded player
    -- in front of an NPC must block the trigger, rather than shooting through it.
    local origin,direction=ray.Origin,ray.Direction
    local directionLengthSquared=direction:Dot(direction)
    if directionLengthSquared<1e-12 then return nil end
    for _,a in ipairs(Combat.actors) do
        local cached=Combat.parts[a]
        local root=a.RootPart
        if cached and root and a.Character and a.Character.Parent and Combat.IsAlive(a) then
            -- Parked rigs share one actor transform; compute it once per actor.
            local actorTransform
            if not root:IsDescendantOf(workspace) then
                local rotation=typeof(a.CFrame)=="CFrame" and a.CFrame.Rotation or CFrame.identity
                actorTransform=(rotation+a.Position)*root.CFrame:Inverse()
            end
            for _,p in ipairs(cached.list) do
                if p.Parent then
                    local cf=p.CFrame
                    if actorTransform then cf=actorTransform*cf end
                    local size=p.Size
                    -- Reject parts outside the finite ray segment using an enclosing sphere.
                    -- The exact oriented-box test still decides every possible intersection.
                    local offset=cf.Position-origin
                    local along=math.clamp(offset:Dot(direction)/directionLengthSquared,0,nearest)
                    local separation=offset-direction*along
                    if separation:Dot(separation)<=size:Dot(size)*.25+1e-5 then
                        local hit=Combat.RayBox(origin,direction,cf,size)
                        if hit and hit<nearest then nearest=hit;closest=a end
                    end
                end
            end
        end
    end
    if not closest or not Combat.Allowed(closest,settings) then return nil end
    if settings.VisibleCheck and not Combat.Visible(closest,ray.Origin+ray.Direction*nearest,camera) then return nil end
    return closest
end
function Combat.KeyActive(picker,_state)
    if Library:IsTyping() or picker==nil then return false end
    return picker.Value=="None" or picker:GetState()==true
end
function Combat.RageActive()
    return Combat.active and Rage.Enabled and Combat.KeyActive(RageKeyPicker)
end
function Combat.TriggerStep(actor,now,fire)
    if actor~=Combat.triggerActor then Combat.triggerActor=actor;Combat.targetSince=now end
    if not actor then return false end
    if (now-Combat.targetSince)*1000<TriggerBotSettings.ReactionTime or (now-Combat.lastShot)*1000<TriggerBotSettings.ShootTime then return false end
    fire();Combat.lastShot=now;return true
end
function Combat.Fire()
    if mouse1click then mouse1click()
    elseif mouse1press and mouse1release then
        Combat.mouseHeld=true;mouse1press()
        task.delay(.02,function() if Combat.mouseHeld then Combat.mouseHeld=false;mouse1release() end end)
    end
end
local keyStates={silent={},trigger={}}
function Combat.Frame(dt)
    if not Combat.active then return end
    AimCamera=workspace.CurrentCamera
    if not AimCamera then return end
    if (Silent.Enabled or Rage.Enabled) and not Combat.installed and (not Combat.retryAt or os.clock()>=Combat.retryAt) then
        Combat.retryAt=os.clock()+2
        Combat.Install()
    end
    local menuOpen=Window.Holder.Visible
    local blocked=menuOpen or Library:IsTyping()
    Combat.silentActive=Combat.KeyActive(SilentKeyPicker,keyStates.silent)
    local triggerActive=Combat.KeyActive(TriggerKeyPicker,keyStates.trigger)
    if Combat.RageActive() then
        Combat.target=nil;Combat.sticky=nil;Combat.triggerActor=nil
        if not blocked and Combat.installed and os.clock()>=(Combat.rageNextShot or 0) then
            Combat.rageNextShot=os.clock()+.1
            local weapon=Combat.Weapon()
            if weapon and weapon._firearm and Combat.FindTarget(Rage,AimCamera) then Combat.Fire() end
        end
        return
    end
    if not blocked and Silent.Enabled and Combat.silentActive then
        Combat.target=Combat.FindTarget(Silent,nil,nil,Combat.sticky)
        Combat.sticky=Combat.target and Combat.target.actor
    else Combat.target=nil;Combat.sticky=nil end
    if not blocked and TriggerBotSettings.Enabled and triggerActive then
        local actor=Combat.TriggerTarget(TriggerBotSettings,AimCamera,aim_getMouseLocation())
        Combat.TriggerStep(actor,os.clock(),Combat.Fire)
    else Combat.triggerActor=nil;Combat.targetSince=0 end
end
function Combat.Destroy()
    if not Combat.active then return end
    Combat.active=false;Rage.Enabled=false;Silent.Enabled=false;TriggerBotSettings.Enabled=false;Combat.target=nil
    if Combat.Unhook then Combat.Unhook() end
    for _,c in ipairs(Combat.connections) do c:Disconnect() end
    for _,d in ipairs(Combat.drawings) do d:Remove() end
    if Combat.gradientGui then Combat.gradientGui:Destroy();Combat.gradientGui=nil end
    if Combat.mouseHeld then Combat.mouseHeld=false;if mouse1release then mouse1release() end end
end
getgenv().LinoriaCombat=Combat


-- Scope redirection to this game's local firearm discharge. The unchanged
-- discharge code uses the returned muzzle frame for both simulation and replication.
function Combat.RedirectMuzzle(cf,target)
    if typeof(cf)~="CFrame" or not target or typeof(target.position)~="Vector3" then return cf end
    if (target.position-cf.Position).Magnitude<.001 then return cf end
    return CFrame.lookAt(cf.Position,target.position)
end
-- Match BulletClassMultithread: constant muzzle speed and gravity 32.2.
function Combat.Intercept(origin,point,velocity,speed,compensateDrop)
    if type(speed)~="number" or speed<=0 then return point,0 end
    local relative=point-origin
    local a=velocity:Dot(velocity)-speed*speed
    local b=2*relative:Dot(velocity)
    local c=relative:Dot(relative)
    local time=relative.Magnitude/speed
    local discriminant=b*b-4*a*c
    if math.abs(a)<1e-6 then
        if math.abs(b)>1e-6 and -c/b>0 then time=-c/b end
    elseif discriminant>=0 then
        local root=math.sqrt(discriminant)
        local t1,t2=(-b-root)/(2*a),(-b+root)/(2*a)
        if t1>0 and t2>0 then time=math.min(t1,t2)
        elseif t1>0 then time=t1 elseif t2>0 then time=t2 end
    end
    time=math.clamp(time,0,5)
    local aim=point
    for _=1,6 do
        aim=point+velocity*time+Vector3.new(0,compensateDrop and 16.1*time*time or 0,0)
        time=math.clamp((aim-origin).Magnitude/speed,0,5)
    end
    return aim,time
end
function Combat.ShotFrame(weapon,cf,target,settings)
    settings=settings or Silent
    if typeof(cf)~="CFrame" or not target then return cf end
    local tune=weapon._firearm and weapon._firearm.Tune
    local bulletService=Combat.bulletService
    if (not settings.AutoPrediction and not settings.BulletDropCompensation)
        or not tune or not bulletService then return Combat.RedirectMuzzle(cf,target) end
    local ok,speed=pcall(bulletService.GetInfo,bulletService,tune.Caliber,tune.Barrel)
    if not ok or type(speed)~="number" or speed<=0 then return Combat.RedirectMuzzle(cf,target) end
    local sample=Combat.samples[target.actor]
    local velocity=settings.AutoPrediction and sample and os.clock()-sample.time<.35 and sample.velocity or Vector3.zero
    local point=Combat.PartPosition(target.actor,target.part)
    local aim=Combat.Intercept(cf.Position,point,velocity,speed,settings.BulletDropCompensation)
    local frame=Combat.RedirectMuzzle(cf,{position=aim})
    -- Discharge adds the sight's zeroing angle after GetMuzzleCFrame.
    -- Remove it here so it does not add a second correction to the trajectory.
    local actor=weapon._actor
    local zero=actor and actor.ADS and actor.ViewModel and actor.ViewModel.Zero
    if type(zero)=="table" then zero=zero[4] end
    if settings.BulletDropCompensation and type(zero)=="number" then
        local angle=math.asin(math.clamp(zero*32.2/(speed*speed),-1,1))*.5
        frame=frame*CFrame.Angles(-angle,0,0)
    end
    return frame
end

function Combat.Install()
    if Combat.installed then return true end
    local class
    for _,module in ipairs(getloadedmodules()) do
        if module.Name=="FirearmInventory" then
            local ok,result=pcall(require,module)
            if ok and type(result)=="table" then class=result end
        elseif module.Name=="BulletService" then
            local ok,result=pcall(require,module)
            if ok and type(result)=="table" and type(result.GetInfo)=="function" then Combat.bulletService=result end
        end
    end
    if not class or type(class.Discharge)~="function" or type(class.GetMuzzleCFrame)~="function" then
        Combat.hookState="FirearmInventory not loaded yet"
        return false
    end
    local originalDischarge,originalMuzzle=class.Discharge,class.GetMuzzleCFrame
    local rawDischarge,rawMuzzle=rawget(class,"Discharge"),rawget(class,"GetMuzzleCFrame")
    local contexts=setmetatable({}, {__mode="k"})
    local function discharge(weapon,...)
        local thread=coroutine.running()
        local oldContext=contexts[thread]
        local c=Combat.Service();local me=c and c.Replicator and c.Replicator.LocalActor
        local selected
        local rageActive=Combat.RageActive()
        local settings=rageActive and Rage or Silent
        -- An actual firearm discharge is already a game-accepted shot. UI menu
        -- visibility must not cancel its aim correction; typing still blocks it.
        if Combat.active and settings.Enabled and (rageActive or Combat.silentActive) and weapon._actor==me
            and not Library:IsTyping()
            and math.random(1,100)<=(settings.HitChance or 100) then
            selected=Combat.FindTarget(settings,nil,nil,Combat.sticky)
        end
        contexts[thread]=selected and {weapon=weapon,target=selected,settings=settings} or nil
        local result=table.pack(pcall(originalDischarge,weapon,...))
        contexts[thread]=oldContext
        if not result[1] then error(result[2],0) end
        return table.unpack(result,2,result.n)
    end
    local function muzzle(weapon,...)
        local result=table.pack(originalMuzzle(weapon,...))
        local ctx=contexts[coroutine.running()]
        if Combat.active and ctx and ctx.settings.Enabled and ctx.weapon==weapon and Combat.Allowed(ctx.target.actor,ctx.settings) then
            result[1]=Combat.ShotFrame(weapon,result[1],ctx.target,ctx.settings)
        end
        return table.unpack(result,1,result.n)
    end
    class.Discharge=discharge
    class.GetMuzzleCFrame=muzzle
    Combat.installed=true;Combat.hookState="Local firearm adapter ready"
    Combat.hookClass=class;Combat.hookDischarge=discharge;Combat.hookMuzzle=muzzle
    Combat.Unhook=function()
        if class.Discharge==discharge then class.Discharge=rawDischarge end
        if class.GetMuzzleCFrame==muzzle then class.GetMuzzleCFrame=rawMuzzle end
        Combat.installed=false
    end
    return true
end



local GRAD_FOV_SEGMENTS = 48
local function makeGradientRing()
    local segments = {}
    if Drawing then
        for i = 1, GRAD_FOV_SEGMENTS do
            local ln = Drawing.new("Line")
            table.insert(Combat.drawings,ln)
            ln.Thickness = 2
            ln.Transparency = 1
            ln.Visible = false
            segments[i] = ln
        end
    end
    local ring = { segments = segments }

    function ring:hide()
        for _, ln in ipairs(self.segments) do ln.Visible = false end
    end

    -- A single UIGradient avoids seams between translucent Drawing polygons.
    local gui=Instance.new("ScreenGui")
    gui.Name="LinoriaFOVGradient";gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false
    gui.DisplayOrder=0;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.Parent=(gethui and gethui()) or game:GetService("CoreGui")
    Combat.gradientGui=gui
    local fill=Instance.new("Frame")
    fill.Name="Fill";fill.AnchorPoint=Vector2.new(.5,.5)
    fill.BackgroundColor3=Color3.new(1,1,1);fill.BorderSizePixel=0
    fill.Visible=false;fill.Active=false;fill.Parent=gui
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=fill
    local gradient=Instance.new("UIGradient");gradient.Parent=fill
    local hideOutline=ring.hide
    function ring:hide()
        hideOutline(self);fill.Visible=false
    end
    ring.phase=0
    function ring:draw(center,radius,colorA,colorB,filled,alpha,dt)
        if Silent.GradientSpin then
            self.phase=(self.phase+(dt or 0)*Silent.GradientSpinSpeed*math.pi*2)%(math.pi*2)
        else self.phase=0 end
        local n=#self.segments
        for i,ln in ipairs(self.segments) do
            local a0=(i-1)/n*math.pi*2
            local a1=i/n*math.pi*2
            ln.From=center+Vector2.new(math.cos(a0),math.sin(a0))*radius
            ln.To=center+Vector2.new(math.cos(a1),math.sin(a1))*radius
            ln.Color=colorA:Lerp(colorB,(math.sin((a0+a1)*.5-self.phase)+1)*.5)
            ln.Transparency=1;ln.Visible=true;ln.ZIndex=1
        end
        fill.Visible=filled and alpha>0
        fill.Position=UDim2.fromOffset(center.X,center.Y)
        fill.Size=UDim2.fromOffset(radius*2,radius*2)
        fill.BackgroundTransparency=1-math.clamp(alpha,0,1)
        gradient.Color=ColorSequence.new(colorA,colorB)
        gradient.Rotation=90+math.deg(self.phase)
    end

    return ring
end


local SilentFOVCircle, SilentFOVFill
if Drawing then
    SilentFOVFill = Drawing.new("Circle")
    table.insert(Combat.drawings,SilentFOVFill)
    SilentFOVFill.NumSides = 64
    SilentFOVFill.Filled = true
    SilentFOVFill.Color = Silent.FOVFillColor
    SilentFOVFill.Transparency = Silent.FOVFillTransparency
    SilentFOVFill.Visible = false

    SilentFOVCircle = Drawing.new("Circle")
    table.insert(Combat.drawings,SilentFOVCircle)
    SilentFOVCircle.Thickness = 1
    SilentFOVCircle.NumSides = 64
    SilentFOVCircle.Color = Silent.FOVColor
    SilentFOVCircle.Filled = false
    SilentFOVCircle.Transparency = 1
    SilentFOVCircle.Visible = false
end


local SilentGradRing = makeGradientRing()
table.insert(Combat.connections, AimRunService.RenderStepped:Connect(function(dt)
    local show = Silent.Enabled and Silent.FOVEnabled and Silent.ShowFOV
    local mouse = aim_getMouseLocation()
    if SilentFOVFill then
        SilentFOVFill.Visible = show and Silent.FillFOV and not Silent.GradientFOV
        SilentFOVFill.Position = mouse
        SilentFOVFill.Radius = Silent.FOV
        SilentFOVFill.Color = Silent.FOVFillColor
        SilentFOVFill.Transparency = Silent.FOVFillTransparency
    end
    if show and Silent.GradientFOV then
        if SilentFOVCircle then SilentFOVCircle.Visible = false end
        SilentGradRing:draw(mouse, Silent.FOV, Silent.GradientColorA,
            Silent.GradientColorB, Silent.FillFOV, Silent.FOVFillTransparency, dt)
    else
        SilentGradRing:hide()
        if SilentFOVCircle then
            SilentFOVCircle.Visible = show
            SilentFOVCircle.Position = mouse
            SilentFOVCircle.Radius = Silent.FOV
            SilentFOVCircle.Color = Silent.FOVColor
        end
    end
end))

-- Bind controls to the existing BRM5 combat state.
local function addToggle(group, id, text, settings, field)
    local control = group:AddToggle(id, { Text = text, Default = settings[field] })
    control:OnChanged(function()
        settings[field] = control.Value
        Combat.target = nil
        Combat.sticky = nil
    end)
    return control
end

local function addSlider(group, id, text, settings, field, minimum, maximum, decimals, suffix)
    local control = group:AddSlider(id, {
        Text = text, Default = settings[field], Min = minimum, Max = maximum,
        Rounding = decimals or 0, Suffix = suffix or '',
    })
    control:OnChanged(function(value) settings[field] = value end)
    return control
end

local function addTargets(group, id, settings)
    local kinds = { NPC = 'NPCs', Zombie = 'Zombies', Player = 'Players' }
    local defaults = {}
    for _, name in ipairs({ 'NPC', 'Zombie', 'Player' }) do
        if settings.Targets[kinds[name]] then table.insert(defaults, name) end
    end
    group:AddDropdown(id, {
        Text = 'Target Selection', Values = { 'NPC', 'Zombie', 'Player' },
        Multi = true, Default = defaults,
    }):OnChanged(function(selected)
        local values = {}
        for _, name in ipairs({ 'NPC', 'Zombie', 'Player' }) do
            if selected[name] then table.insert(values, kinds[name]) end
        end
        Combat.SetTargets(settings, values)
    end)
end

local SilentGroup = Tabs.Main:AddLeftGroupbox('Silent Aim')
local EnabledControl = addToggle(SilentGroup, 'silent_enabled', 'Enabled', Silent, 'Enabled')
EnabledControl:AddKeyPicker('silent_key', {
    Default = 'None', Mode = 'Hold', Modes = { 'Always', 'Hold', 'Toggle' },
    Text = 'Silent Aim', SyncToggleState = false,
})
SilentKeyPicker = Options.silent_key

local ShowControl = addToggle(SilentGroup, 'silent_fov_show', 'Show FOV', Silent, 'ShowFOV')
ShowControl:AddColorPicker('silent_fov_color', { Default = Silent.FOVColor, Title = 'FOV Color' })
Options.silent_fov_color:OnChanged(function(color) Silent.FOVColor = color end)

local FillControl = addToggle(SilentGroup, 'silent_fov_fill', 'Fill', Silent, 'FillFOV')
FillControl:AddColorPicker('silent_fov_fill_color', {
    Default = Silent.FOVFillColor, Transparency = 1 - Silent.FOVFillTransparency, Title = 'Fill Color',
})
Options.silent_fov_fill_color:OnChanged(function(color)
    Silent.FOVFillColor = color
    Silent.FOVFillTransparency = 1 - Options.silent_fov_fill_color.Transparency
end)

local GradientControl = addToggle(SilentGroup, 'silent_fov_gradient', 'Gradient', Silent, 'GradientFOV')
GradientControl:AddColorPicker('silent_fov_gradient_a', { Default = Silent.GradientColorA, Title = 'Gradient Color A' })
GradientControl:AddColorPicker('silent_fov_gradient_b', { Default = Silent.GradientColorB, Title = 'Gradient Color B' })
Options.silent_fov_gradient_a:OnChanged(function(color) Silent.GradientColorA = color end)
Options.silent_fov_gradient_b:OnChanged(function(color) Silent.GradientColorB = color end)

local GradientOptions = SilentGroup:AddDependencyBox()
addToggle(GradientOptions, 'silent_fov_spin', 'Spin', Silent, 'GradientSpin')
local SpinOptions = GradientOptions:AddDependencyBox()
addSlider(SpinOptions, 'silent_fov_spin_speed', 'Spin Speed', Silent, 'GradientSpinSpeed', 0.1, 3, 1, ' rev/s')
SpinOptions:SetupDependencies({ { Toggles.silent_fov_spin, true } })
GradientOptions:SetupDependencies({ { Toggles.silent_fov_gradient, true } })

addTargets(SilentGroup, 'silent_targets', Silent)
SilentGroup:AddDropdown('silent_hitpart', {
    Text = 'Hit Part', Values = HitPartOptions, Default = Silent.HitPart,
}):OnChanged(function(value) Silent.HitPart = value; Combat.sticky = nil end)
addSlider(SilentGroup, 'silent_fov', 'FOV Radius', Silent, 'FOV', 10, 500, 0, 'px')
addSlider(SilentGroup, 'silent_hitchance', 'Hit Chance', Silent, 'HitChance', 0, 100, 0, '%')
addSlider(SilentGroup, 'silent_distance', 'Max Distance', Silent, 'MaxDistance', 50, 5000, 0, ' studs')
addToggle(SilentGroup, 'silent_fov_enabled', 'FOV Check', Silent, 'FOVEnabled')
addToggle(SilentGroup, 'silent_sticky', 'Sticky Aim', Silent, 'StickyAim')

local PredictionGroup = Tabs.Main:AddRightGroupbox('Prediction')
addToggle(PredictionGroup, 'silent_auto_prediction', 'Auto Prediction', Silent, 'AutoPrediction')
addToggle(PredictionGroup, 'silent_bullet_drop_compensation', 'Bullet Drop Compensation', Silent, 'BulletDropCompensation')

local ChecksGroup = Tabs.Main:AddRightGroupbox('Checks')
addToggle(ChecksGroup, 'silent_teamcheck', 'Team Check', Silent, 'TeamCheck')
addToggle(ChecksGroup, 'silent_visiblecheck', 'Wallcheck', Silent, 'VisibleCheck')
addToggle(ChecksGroup, 'silent_hitscan', 'Hitscan', Silent, 'Hitscan')

local TriggerGroup = Tabs.Main:AddLeftGroupbox('Triggerbot')
local TriggerControl = addToggle(TriggerGroup, 'trigger_enabled', 'Enabled', TriggerBotSettings, 'Enabled')
TriggerControl:AddKeyPicker('trigger_key', {
    Default = 'None', Mode = 'Hold', Modes = { 'Always', 'Hold', 'Toggle' },
    Text = 'Triggerbot', SyncToggleState = false,
})
TriggerKeyPicker = Options.trigger_key
addSlider(TriggerGroup, 'trigger_reaction', 'Reaction Time', TriggerBotSettings, 'ReactionTime', 0, 500, 0, ' ms')
addSlider(TriggerGroup, 'trigger_shoot', 'Shoot Time', TriggerBotSettings, 'ShootTime', 0, 1000, 0, ' ms')
addTargets(TriggerGroup, 'trigger_targets', TriggerBotSettings)
addToggle(TriggerGroup, 'trigger_teamcheck', 'Team Check', TriggerBotSettings, 'TeamCheck')
addToggle(TriggerGroup, 'trigger_visiblecheck', 'Wallcheck', TriggerBotSettings, 'VisibleCheck')
addToggle(TriggerGroup, 'trigger_magnetic', 'Magnetic Trigger', TriggerBotSettings, 'Magnetic')
addSlider(TriggerGroup, 'trigger_distance', 'Max Distance', TriggerBotSettings, 'MaxDistance', 50, 5000, 0, ' studs')

-- Keep precise wheel adjustment without changing the library's slider implementation.
-- .Container is a LinoriaLib-internal Frame reference gen3's groupboxes don't
-- expose (Airflow builds its own Instance tree) — pcall-guarded so a missing
-- Container just skips this nicety instead of aborting everything after it.
pcall(function()
for _, id in ipairs({ 'trigger_reaction', 'trigger_shoot' }) do
    local slider = Options[id]
    local text = id == 'trigger_reaction' and 'Reaction Time' or 'Shoot Time'
    local label
    for _, child in ipairs(TriggerGroup.Container:GetChildren()) do
        if child:IsA('TextLabel') and child.Text == text then label = child; break end
    end
    if label then
        label.Active = true
        table.insert(Combat.connections, label.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel and input.Position.Z ~= 0
                and not Library:MouseIsOverOpenedFrame() then
                slider:SetValue(math.clamp(slider.Value + math.sign(input.Position.Z), slider.Min, slider.Max))
                Library:AttemptSave()
            end
        end))
    end
end
end)

-- Each primary tab owns a horizontal subnavigation row and its control pages.
-- group.Container is a LinoriaLib-internal Frame reference gen3's groupboxes
-- don't expose (Airflow builds its own Instance tree), so this whole nav-bar
-- builder is wrapped in pcall below: on gen3 it safely no-ops (all the real
-- groupboxes/controls stay visible directly on the tab, just without the
-- subtab-style grouping/switcher bar) instead of aborting every tab built
-- after it.
local function addSubtabsImpl(name, pages)
    local function groupFrame(group)
        return group.Container.Parent.Parent
    end
    local firstFrame = groupFrame(pages[1].Groups[1])
    local mainFrame = firstFrame.Parent.Parent
    local bar = Library:Create('Frame', {
        Name = name .. 'Subtabs', BackgroundTransparency = 1,
        Position = UDim2.fromOffset(7, 4), Size = UDim2.new(1, -14, 0, 28),
        ZIndex = 3, Parent = mainFrame,
    })
    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
        Parent = bar,
    })
    local divider = Library:Create('Frame', {
        Name = 'SubtabDivider', BackgroundColor3 = Library.OutlineColor,
        BorderSizePixel = 0, Position = UDim2.fromOffset(7, 32),
        Size = UDim2.new(1, -14, 0, 1), ZIndex = 3, Parent = mainFrame,
    })
    Library:AddToRegistry(divider, { BackgroundColor3 = 'OutlineColor' })
    for _, side in ipairs(mainFrame:GetChildren()) do
        if side:IsA('ScrollingFrame') then
            side.Position = side.Position + UDim2.fromOffset(0, 36)
            side.Size = side.Size - UDim2.fromOffset(0, 36)
        end
    end
    local function selectPage(selected)
        for _, page in ipairs(pages) do
            local active = page == selected
            page.Active = active
            page.Indicator.Visible = active
            page.Button.BackgroundTransparency = active and 0 or 1
            page.Button.TextTransparency = active and 0 or 0.18
            for _, group in ipairs(page.Groups) do
                groupFrame(group).Visible = active
            end
            local background = active and 'MainColor' or 'BackgroundColor'
            local foreground = active and 'AccentColor' or 'FontColor'
            page.Button.BackgroundColor3 = Library[background]
            page.Button.TextColor3 = Library[foreground]
            Library.RegistryMap[page.Button].Properties.BackgroundColor3 = background
            Library.RegistryMap[page.Button].Properties.TextColor3 = foreground
        end
    end
    for index, page in ipairs(pages) do
        page.Button = Library:Create('TextButton', {
            Text = page.Name, Font = Library.Font, TextSize = 14,
            AutoButtonColor = false, BackgroundColor3 = Library.BackgroundColor,
            TextColor3 = Library.FontColor, BorderSizePixel = 0,
            Size = UDim2.fromOffset(math.max(58, Library:GetTextBounds(page.Name, Library.Font, 14) + 18), 28), LayoutOrder = index,
            ZIndex = 4, Parent = bar,
        })
        Library:AddToRegistry(page.Button, {
            BackgroundColor3 = 'BackgroundColor', TextColor3 = 'FontColor',
        })
        Library:Create('UICorner', {CornerRadius=UDim.new(0,2),Parent=page.Button})
        page.Indicator = Library:Create('Frame', {
            Name = 'ActiveIndicator', BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0,6,1,0), Size = UDim2.new(1,-12,0,2),
            Visible = false, ZIndex = 5, Parent = page.Button,
        })
        Library:AddToRegistry(page.Indicator, { BackgroundColor3 = 'AccentColor' })
        Library:GiveSignal(page.Button.MouseEnter:Connect(function()
            if not page.Active then page.Button.TextTransparency = 0 end
        end))
        Library:GiveSignal(page.Button.MouseLeave:Connect(function()
            if not page.Active then page.Button.TextTransparency = 0.18 end
        end))
        Library:GiveSignal(page.Button.MouseButton1Click:Connect(function()
            if not Library:MouseIsOverOpenedFrame() then selectPage(page) end
        end))
    end
    selectPage(pages[1])
end

local function addSubtabs(name, pages)
    pcall(addSubtabsImpl, name, pages)
end

local RageGroup = Tabs.Ragebot:AddLeftGroupbox('Ragebot')
local RageControl = addToggle(RageGroup, 'rage_enabled', 'Enabled', Rage, 'Enabled')
RageControl:AddKeyPicker('rage_key', {
    Default = 'None', Mode = 'Hold', Modes = { 'Always', 'Hold', 'Toggle' },
    Text = 'Ragebot', SyncToggleState = false,
})
RageKeyPicker = Options.rage_key
RageGroup:AddDropdown('rage_hitpart', {
    Text = 'Hit Part', Values = {
        'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso',
        'LeftUpperArm', 'RightUpperArm', 'LeftUpperLeg', 'RightUpperLeg',
    }, Default = Rage.HitPart,
}):OnChanged(function(value) Rage.HitPart = value end)
addTargets(RageGroup, 'rage_targets', Rage)
local RageChecks = Tabs.Ragebot:AddLeftGroupbox('Checks')
addToggle(RageChecks, 'rage_visiblecheck', 'Wallcheck', Rage, 'VisibleCheck')
addToggle(RageChecks, 'rage_teamcheck', 'Team Check', Rage, 'TeamCheck')
addToggle(RageChecks, 'rage_hitscan', 'Hitscan', Rage, 'Hitscan')
addToggle(RageChecks, 'rage_distancecheck', 'Distance Check', Rage, 'DistanceCheck')
addSlider(RageChecks, 'rage_distance', 'Max Distance', Rage, 'MaxDistance', 1, 5000, 0, ' studs')

addSubtabs('Main', {
    { Name = 'Silent Aim', Groups = { SilentGroup, PredictionGroup, ChecksGroup } },
    { Name = 'Triggerbot', Groups = { TriggerGroup } },
})
addSubtabs('Ragebot', {
    { Name = 'General', Groups = { RageGroup } },
    { Name = 'Checks', Groups = { RageChecks } },
})

do
local Sense = (function()
    local E: {[string]: any} = {
        _hasLoaded = false, objects = {}, errors = {}, scanAt = 0,
        sharedSettings = {textSize=13, textFont=2,
            teamBasedColor=false, neutralColor=Color3.fromRGB(100,220,150)},
        teamSettings = {}, chams = {}, advanced = {},
    }
    local white, black = Color3.new(1,1,1), Color3.new(0,0,0)
    local t = {
        enabled=true, limitDistance=false, maxDistance=1000, box=false, box3d=false, boxColor={white,1}, box3dColor={white,1},
        boxOutline=true, boxOutlineColor={black,1}, boxOutlineThickness=1,
        boxFill=false, boxFillColor={Color3.fromRGB(150,80,255),.2},
        healthBar=false, healthyColor=Color3.new(0,1,0), dyingColor=Color3.new(1,0,0),
        healthBarOutline=true, healthText=false, healthTextColor={white,1}, healthTextOutline=true,
        name=false, nameColor={white,1}, nameOutline=true,
        weapon=false, weaponColor={white,1}, weaponOutline=true,
        distance=false, distanceColor={white,1}, distanceOutline=true,
        tracer=false, tracerOrigin="Bottom", tracerColor={white,1}, tracerOutline=true,
        offScreenArrow=false, offScreenArrowSize=15, offScreenArrowRadius=150,
        offScreenArrowColor={white,1},
    }
    E.teamSettings.npc = t
    E.teamSettings.players={}
    for k,v in pairs(t) do E.teamSettings.players[k]=type(v)=="table" and table.clone(v) or v end
    E.teamSettings.players.enabled=false
    E.teamSettings.players.teamCheck=false
    E.teamSettings.players.boxOutlineThickness=1
    E.chams.npc = {enabled=false, visibleColor=Color3.fromRGB(0,255,100),visibleIntensity=.85,
        occludedColor=white,occludedIntensity=.25}
    E.advanced.npc = {nameType="Name",skeleton=false,skeletonColor=white,
        skeletonThickness=1,skeletonOpacity=1,skeletonOutline=true,skeletonOutlineColor=black}
    E.chams.players=table.clone(E.chams.npc)
    E.advanced.players=table.clone(E.advanced.npc)
    for _,kind in ipairs({"zombies","corpses"}) do
        E.teamSettings[kind]={}
        for k,v in pairs(t) do E.teamSettings[kind][k]=type(v)=="table" and table.clone(v) or v end
        E.teamSettings[kind].enabled=false
        E.teamSettings[kind].name=true
        E.teamSettings[kind].distance=true
        E.chams[kind]=table.clone(E.chams.npc)
        E.advanced[kind]=table.clone(E.advanced.npc)
    end
    -- per-ability type filter: when false, hides ALL ESP for that zombie type
    E.teamSettings.zombies.abilityFilter={[1]=true,[2]=true,[3]=true,[4]=true}
    local service, resolveAt, connection, anchor
    local signs = {Vector3.new(-1,-1,-1),Vector3.new(-1,1,-1),Vector3.new(-1,1,1),Vector3.new(-1,-1,1),
        Vector3.new(1,-1,-1),Vector3.new(1,1,-1),Vector3.new(1,1,1),Vector3.new(1,-1,1)}
    local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.IgnoreWater = true
    function E.Service()
        if service then return service end
        if resolveAt and os.clock() < resolveAt then return nil end
        resolveAt = os.clock()+2
        for _, module in ipairs(getloadedmodules()) do
            if module.Name == "ClientService" then
                local ok, value = pcall(require,module)
                if ok and type(value)=="table" and value.Replicator then service=value; break end
            end
        end
        return service
    end
    function E.IsNPC(actor)
        local c = E.Service()
        local registry = c and c.Replicator and c.Replicator.Actors
        return type(actor)=="table" and registry and actor.UID and registry[actor.UID]==actor
            and actor.Owner==nil and actor.IsLocalPlayer~=true
            and typeof(actor.Character)=="Instance" and actor.Character:IsA("Model")
    end
    function E.IsPlayer(actor)
        local c=E.Service();local registry=c and c.Replicator and c.Replicator.Actors
        return type(actor)=="table" and registry and actor.UID and registry[actor.UID]==actor
            and typeof(actor.Owner)=="Instance" and actor.Owner:IsA("Player")
            and actor.Owner~=AimLocalPlayer and actor.IsLocalPlayer~=true
            and typeof(actor.Character)=="Instance" and actor.Character:IsA("Model")
    end
    function E.Kind(actor)
        if E.IsNPC(actor) or E.IsPlayer(actor) then
            if not Combat.IsAlive(actor) then return "corpses" end
            if actor.Zombie then return "zombies" end
        end
        if E.IsNPC(actor) then return "npc" end
        if E.IsPlayer(actor) then return "players" end
    end
    local function newDrawing(o,key,class,props)
        local d = (o.DrawingFactory or E.DrawingFactory or Drawing.new)(class)
        d.Visible=false
        d.Transparency=1
        for k,v in pairs(props or {}) do d[k]=v end
        o.drawings[key]=d
        return d
    end
    local function drawing(o,key,class,props)
        return o.drawings[key] or newDrawing(o,key,class,props)
    end
    local function hide(o)
        for _, label in pairs(o.fontLabels or {}) do label.Visible = false end
        for _,d in pairs(o.drawings) do d.Visible=false end
        for _,d in pairs(o.adornments) do d.Visible=false end
    end
    local function destroy(o)
        for _, label in pairs(o.fontLabels or {}) do label:Destroy() end
        for _,listener in ipairs(o.rigListeners or {}) do listener:Disconnect() end
        for _,d in pairs(o.drawings) do d:Remove() end
        for _,d in pairs(o.adornments) do d:Destroy() end
    end
    local skeletonPairs = {
        {"UpperTorso","Head","Neck"},{"LowerTorso","UpperTorso","Waist"},
        {"UpperTorso","LeftUpperArm","LeftShoulder"},{"LeftUpperArm","LeftLowerArm","LeftElbow"},
        {"LeftLowerArm","LeftHand","LeftWrist"},
        {"UpperTorso","RightUpperArm","RightShoulder"},{"RightUpperArm","RightLowerArm","RightElbow"},
        {"RightLowerArm","RightHand","RightWrist"},
        {"LowerTorso","LeftUpperLeg","LeftHip"},{"LeftUpperLeg","LeftLowerLeg","LeftKnee"},
        {"LeftLowerLeg","LeftFoot","LeftAnkle"},
        {"LowerTorso","RightUpperLeg","RightHip"},{"RightUpperLeg","RightLowerLeg","RightKnee"},
        {"RightLowerLeg","RightFoot","RightAnkle"},
        {"Torso","Head","Neck"},{"Torso","Left Arm","LeftShoulder"},
        {"Torso","Right Arm","RightShoulder"},{"Torso","Left Leg","LeftHip"},{"Torso","Right Leg","RightHip"},
    }
    local function buildSkeleton(o,descendants)
        local nodes,links,body,names,connections,known={},{},{},{},{},{}
        local jointPairs={}
        local function node(part,offset,bone)
            nodes[#nodes+1]={part=part,offset=offset or Vector3.zero,bone=bone}
            return #nodes
        end
        local function link(a,b)
            if a~=b then links[#links+1]={a,b} end
        end
        for _,part in ipairs(o.parts) do
            if part.Name~="Root" and part.Name~="HumanoidRootPart" then
                local parent=part.Parent
                local equipment=false
                while parent and parent~=o.model do
                    if parent:IsA("Accessory") or parent:IsA("Tool") then equipment=true;break end
                    parent=parent.Parent
                end
                if not equipment then body[part]={};names[part.Name]=part end
            end
        end
        local function mark(a,b,physicalJoint)
            if not body[a] or not body[b] or a==b then return false end
            known[a]=known[a] or {};known[b]=known[b] or {}
            known[a][b]=true;known[b][a]=true
            if physicalJoint then
                jointPairs[a]=jointPairs[a] or {};jointPairs[a][b]=true
            end
            return true
        end
        local function connect(a,b,offsetA,offsetB,shared)
            if not mark(a,b) then return end
            connections[a]=connections[a] or {};connections[b]=connections[b] or {}
            if connections[a][b] then return end
            -- A motor's child pivot includes the animated pose. Both adjoining
            -- segments share it, keeping elbows and knees joined while moving.
            local nb=node(b,offsetB)
            local na=shared and nb or node(a,offsetA)
            connections[a][b]=na;connections[b][a]=nb
            body[a][#body[a]+1]=na;body[b][#body[b]+1]=nb
        end
        for _,joint in ipairs(descendants) do
            if joint:IsA("Motor6D") and mark(joint.Part0,joint.Part1,true) and joint.Enabled then
                connect(joint.Part0,joint.Part1,joint.C0.Position,joint.C1.Position,true)
            end
        end
        for _,joint in ipairs(descendants) do
            if joint:IsA("BallSocketConstraint") or joint:IsA("HingeConstraint") then
                local a,b=joint.Attachment0,joint.Attachment1
                if a and b and mark(a.Parent,b.Parent,true) and joint.Enabled then
                    -- Ragdoll attachments stay on their own limb; separated
                    -- parts must not acquire a line spanning the gap.
                    connect(a.Parent,b.Parent,a.Position,b.Position,false)
                end
            end
        end
        -- Remember physical joints that were removed, so a detached limb does
        -- not get reconnected by the streamed-rig fallback on the next scan.
        for a,neighbors in pairs(o.skeletonJointPairs or {}) do
            for b in pairs(neighbors) do mark(a,b,true) end
        end
        o.skeletonJointPairs=jointPairs
        -- Standard living rigs still work before their joints stream in.
        local allowFallback=o.preview or Combat.IsAlive(o.actor)
        for _,pair in ipairs(skeletonPairs) do
            local a,b=names[pair[1]],names[pair[2]]
            if allowFallback and a and b and not (known[a] and known[a][b]) then
                local aa=a:FindFirstChild(pair[3].."RigAttachment")
                local ab=b:FindFirstChild(pair[3].."RigAttachment")
                local offsetB=ab and ab:IsA("Attachment") and ab.Position
                    or Vector3.new(0,((b.Name=="Head" or pair[3]=="Waist") and -.5 or .5)*b.Size.Y,0)
                local offsetA=aa and aa:IsA("Attachment") and aa.Position or Vector3.zero
                connect(a,b,offsetA,offsetB,true)
            end
        end
        local skinned={}
        local boneNodes={}
        for _,bone in ipairs(descendants) do
            if bone:IsA("Bone") then
                local part=bone.Parent
                while part and part~=o.model and not part:IsA("BasePart") do part=part.Parent end
                if body[part] then boneNodes[bone]=node(part,nil,bone) end
            end
        end
        for bone,index in pairs(boneNodes) do
            local parent=boneNodes[bone.Parent]
            if parent then link(parent,index);skinned[nodes[index].part]=true end
        end
        for part,points in pairs(body) do
            if skinned[part] or #points==0 then continue end
            local central=part.Name=="Head" or part.Name:find("Torso")~=nil or #points>2
            if central then
                local center=node(part)
                local joints=connections[part] or {}
                local left=joints[names.LeftUpperArm or names["Left Arm"]]
                local right=joints[names.RightUpperArm or names["Right Arm"]]
                local neck=joints[names.Head]
                if (part.Name=="Torso" or part.Name=="UpperTorso") and left and right then
                    nodes[left].shoulderPart=part;nodes[right].shoulderPart=part
                    -- One straight shoulder bar at the base of the neck. Its
                    -- midpoint follows both animated pivots, so the spine does
                    -- not fan out diagonally from the middle of the chest.
                    nodes[#nodes+1]={midpointA=left,midpointB=right}
                    local collar=#nodes
                    link(left,right);link(center,collar)
                    if neck then link(collar,neck) end
                    for _,point in ipairs(points) do
                        if point~=left and point~=right and point~=neck then link(center,point) end
                    end
                else
                    for _,point in ipairs(points) do link(center,point) end
                end
            elseif #points==2 then
                link(points[1],points[2])
            else
                local anchor=nodes[points[1]]
                local localAnchor=anchor.part==part and anchor.offset
                    or part.CFrame:PointToObjectSpace(anchor.part.CFrame:PointToWorldSpace(anchor.offset))
                local tip=Vector3.new(0,(localAnchor.Y>=0 and -.45 or .45)*part.Size.Y,0)
                if part.Name:find("Foot") then tip=Vector3.new(0,-part.Size.Y*.25,-part.Size.Z*.4) end
                link(points[1],node(part,tip))
            end
        end
        o.skeletonNodes=nodes;o.links=links
        o.skeletonFrames={};o.skeletonWorld={};o.skeletonProjected={}
        -- Streaming can shrink a rig. Release surplus Drawing objects now.
        for key,d in pairs(o.drawings) do
            local index=key:match("^bone(%d+)$") or key:match("^boneOutline(%d+)$")
            if index and tonumber(index)>#links then d:Remove();o.drawings[key]=nil end
        end
    end
    local function rig(o)
        o.rigDirty=false
        o.parts={}
        local seen={}
        local function add(part)
            if typeof(part)=="Instance" and part:IsA("BasePart") and part:IsDescendantOf(o.model) and not seen[part] then
                o.parts[#o.parts+1]=part;seen[part]=true
            end
        end
        for _,part in pairs(o.actor.Parts or {}) do add(part) end
        -- Fill gaps in partially streamed R6/R15 Parts tables without equipment.
        local names={}
        for _,pair in ipairs(skeletonPairs) do names[pair[1]]=true;names[pair[2]]=true end
        local useAll=#o.parts==0
        for _,part in ipairs(o.model:GetChildren()) do
            if names[part.Name] or (useAll and part~=o.actor.RootPart) then add(part) end
        end
        local descendants=o.model:GetDescendants()
        buildSkeleton(o,descendants)
        o.rigRefreshAt=os.clock()+2
    end
    function E.Sync(force)
        if not force and os.clock()<E.scanAt then return end
        E.scanAt=os.clock()+.4
        for actor,o in pairs(E.objects) do
            if not E.Kind(actor) or actor.Character~=o.model or not o.model.Parent then
                destroy(o);E.objects[actor]=nil
            end
        end
        local c=E.Service()
        for _,actor in pairs(c and c.Replicator and c.Replicator.Actors or {}) do
            if E.Kind(actor) and actor.Character.Parent then
                local o=E.objects[actor]
                if not o then
                    o={actor=actor,model=actor.Character,drawings={},adornments={},nextRay=0}
                    local function changed(instance)
                        if instance:IsA("BasePart") or instance:IsA("Attachment")
                            or instance:IsA("Motor6D") or instance:IsA("Bone")
                            or instance:IsA("BallSocketConstraint") or instance:IsA("HingeConstraint") then
                            o.rigDirty=true
                        end
                    end
                    o.rigListeners={
                        o.model.DescendantAdded:Connect(changed),
                        o.model.DescendantRemoving:Connect(changed)
                    }
                    E.objects[actor]=o;rig(o)
                elseif o.rigDirty or o.partsSource~=actor.Parts or os.clock()>=(o.rigRefreshAt or 0) then rig(o) end
                o.partsSource=actor.Parts
            end
        end
    end
    local function color(value)
        if typeof(value)=="Color3" then return value,1 end
        if type(value)=="table" then return value[1],math.clamp(value[2] or 1,0,1) end
        return white,1
    end
    function E.TeamColor(actor)
        if E.IsPlayer(actor) and actor.Owner.Team then return actor.Owner.Team.TeamColor.Color end
        for _,value in pairs({actor.TeamColor,actor.FactionColor,actor.Team,actor.Faction,actor.Company}) do
            if typeof(value)=="Color3" then return value end
            if typeof(value)=="BrickColor" then return value.Color end
            if typeof(value)=="Instance" and value:IsA("Team") then return value.TeamColor.Color end
            if type(value)=="table" then
                if typeof(value.Color)=="Color3" then return value.Color end
                if typeof(value.TeamColor)=="BrickColor" then return value.TeamColor.Color end
            end
        end
        return E.sharedSettings.neutralColor
    end
    local function style(d,value,override)
        local c,a=color(value);d.Color=override or c;d.Transparency=a;d.Visible=a>0
    end
    local function clipLine(a,b,viewport)
        local v=viewport or workspace.CurrentCamera.ViewportSize
        local delta=b-a
        local lo,hi=0,1
        for axis=1,2 do
            local start=axis==1 and a.X or a.Y
            local step=axis==1 and delta.X or delta.Y
            local limit=axis==1 and v.X or v.Y
            if math.abs(step)<1e-8 then
                if start<0 or start>limit then return nil end
            else
                local enter,leave=-start/step,(limit-start)/step
                if enter>leave then enter,leave=leave,enter end
                lo=math.max(lo,enter);hi=math.min(hi,leave)
                if lo>hi then return nil end
            end
        end
        return a+delta*lo,a+delta*hi
    end
    local function line(o,key,a,b,value,thickness,override)
        a,b=clipLine(a,b,o.previewViewportSize)
        if not a then return nil end
        local d=drawing(o,key,"Line")
        d.From=a;d.To=b;d.Thickness=thickness or 1;style(d,value,override)
        return d
    end
    local function square(o,key,pos,size,value,filled,thickness,override)
        local view=o.previewViewportSize or workspace.CurrentCamera.ViewportSize
        local corner=(pos+size):Min(view)
        pos=pos:Max(Vector2.zero)
        size=corner-pos
        if size.X<=0 or size.Y<=0 then return nil end
        local d=drawing(o,key,"Square")
        d.Position=pos;d.Size=size;d.Filled=filled;d.Thickness=thickness or 1;style(d,value,override)
        return d
    end
    local function textAt(o,key,value,pos,col,outline,override)
        local view=workspace.CurrentCamera.ViewportSize
        if pos.X<0 or pos.Y<0 or pos.X>view.X or pos.Y>view.Y then return end
        if E.sharedSettings.textFace and not o.preview then
            if not E.textGui then
                E.textGui = Instance.new('ScreenGui')
                E.textGui.Name = 'LinoriaESPText'; E.textGui.IgnoreGuiInset = true
                E.textGui.ResetOnSpawn = false; E.textGui.DisplayOrder = 0
                E.textGui.Parent = (gethui and gethui()) or game:GetService('CoreGui')
            end
            o.fontLabels = o.fontLabels or {}
            local label = o.fontLabels[key]
            if not label then
                label = Instance.new('TextLabel')
                label.Name = key; label.BackgroundTransparency = 1
                label.AnchorPoint = Vector2.new(0.5, 0); label.BorderSizePixel = 0
                label.TextXAlignment = Enum.TextXAlignment.Center; label.TextYAlignment = Enum.TextYAlignment.Top
                label.RichText = false; label.Active = false; label.TextStrokeColor3 = black
                label.Parent = E.textGui; o.fontLabels[key] = label
            end
            local tint, opacity = color(col)
            local content = tostring(value)
            if label.Text ~= content then label.Text = content end
            if label.FontFace ~= E.sharedSettings.textFace then label.FontFace = E.sharedSettings.textFace end
            if label.TextSize ~= E.sharedSettings.textSize then label.TextSize = E.sharedSettings.textSize end
            label.Size = UDim2.fromOffset(2048, E.sharedSettings.textSize * 3)
            label.Position = UDim2.fromOffset(pos.X, pos.Y)
            label.TextColor3 = override or tint
            label.TextTransparency = 1 - opacity
            label.TextStrokeTransparency = outline and 1 - opacity or 1
            label.Visible = opacity > 0
            return
        end
        local d=drawing(o,key,"Text")
        d.Text=tostring(value);d.Position=pos;d.Size=E.sharedSettings.textSize
        d.Font=E.sharedSettings.textFont;d.Center=true;d.Outline=outline;d.OutlineColor=black
        style(d,col,override)
    end
    local function renderSkeleton(o,camera,adv,override)
        local opacity=math.clamp(adv.skeletonOpacity or 1,0,1)
        if opacity<=0 then return end
        local thickness=math.clamp(adv.skeletonThickness or 1,1,4)
        local tint={adv.skeletonColor,opacity}
        local outline={adv.skeletonOutlineColor or black,opacity}
        local frames,world,projected=o.skeletonFrames,o.skeletonWorld,o.skeletonProjected
        table.clear(frames);table.clear(world);table.clear(projected)
        for i,node in ipairs(o.skeletonNodes) do
            local point
            local part=node.part
            if node.midpointA then
                local a,b=world[node.midpointA],world[node.midpointB]
                if a and b then point=(a+b)*.5 end
            elseif part.Parent and (not node.bone or node.bone.Parent) then
                local cf=frames[part]
                if not cf then
                    cf=o.preview and part.CFrame or Combat.PartCFrame(o.actor,part)
                    frames[part]=cf
                end
                if node.bone then
                    local animated=node.bone.TransformedWorldCFrame.Position
                    point=cf:PointToWorldSpace(part.CFrame:PointToObjectSpace(animated))
                else point=cf:PointToWorldSpace(node.offset) end
            end
            if point and node.shoulderPart and node.shoulderPart.Parent then
                local torso=node.shoulderPart
                local cf=frames[torso]
                if not cf then
                    cf=o.preview and torso.CFrame or Combat.PartCFrame(o.actor,torso)
                    frames[torso]=cf
                end
                point-=cf.UpVector*(torso.Size.Y*.10)
            end
            if point then world[i]=point;projected[i]=camera:WorldToViewportPoint(point) end
        end
        local near=.05
        for i,pair in ipairs(o.links) do
            local a,b=pair[1],pair[2]
            local p,q=projected[a],projected[b]
            if not p or not q or (p.Z<near and q.Z<near) then continue end
            -- Clip in world space before projecting the endpoint behind the
            -- camera. Then clip to the viewport even when both ends are outside.
            if p.Z<near then
                p=camera:WorldToViewportPoint(world[a]:Lerp(world[b],(near-p.Z)/(q.Z-p.Z)))
            elseif q.Z<near then
                q=camera:WorldToViewportPoint(world[b]:Lerp(world[a],(near-q.Z)/(p.Z-q.Z)))
            end
            local from,to=clipLine(Vector2.new(p.X,p.Y),Vector2.new(q.X,q.Y),camera.ViewportSize)
            if not from or (to-from).Magnitude<.25 then continue end
            if adv.skeletonOutline~=false then
                local d=drawing(o,"boneOutline"..i,"Line")
                d.From=from;d.To=to;d.Thickness=thickness+2;d.ZIndex=4;style(d,outline)
            end
            local d=drawing(o,"bone"..i,"Line")
            d.From=from;d.To=to;d.Thickness=thickness;d.ZIndex=5;style(d,tint,override)
        end
    end
    local function bodyBounds(o,delta,position)
        local lo,hi
        for _,p in ipairs(o.parts) do
            if p.Parent then
                local cf=p.CFrame;local h=p.Size*.5
                local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
                local extent=Vector3.new(math.abs(r.X)*h.X+math.abs(u.X)*h.Y+math.abs(l.X)*h.Z,
                    math.abs(r.Y)*h.X+math.abs(u.Y)*h.Y+math.abs(l.Y)*h.Z,
                    math.abs(r.Z)*h.X+math.abs(u.Z)*h.Y+math.abs(l.Z)*h.Z)
                local center=p.Position+delta
                lo=lo and lo:Min(center-extent) or center-extent
                hi=hi and hi:Max(center+extent) or center+extent
            end
        end
        if not lo then return position,Vector3.new(2,5,2) end
        return (lo+hi)*.5,hi-lo
    end
    function E.Weapon(actor)
        local item=actor._inventory and actor._inventory[actor._equipped]
        if not item then return "Unarmed" end
        local model=item._heroModel or item._lodModel
        if typeof(model)=="Instance" then return model.Name:gsub("^AI_","") end
        local name=item._item and item._item.Name
        return name and name:gsub("^FirearmPrimary",""):gsub("^AI_","") or "Unknown"
    end
    local function chams(o,camera,delta,position,teamColor)
        local cfg=E.chams[E.Kind(o.actor)]
        if not cfg then return end
        if not cfg.enabled then return end
        if os.clock()>=o.nextRay then
            o.nextRay=os.clock()+.12
            local c=E.Service();local me=c and c.Replicator and c.Replicator.LocalActor
            local ignore={o.model,workspace.CurrentCamera}
            if me and me.Character then ignore[#ignore+1]=me.Character end
            ray.FilterDescendantsInstances=ignore
            o.partClear={}
            for _,p in ipairs(o.parts) do
                if p:IsDescendantOf(o.model) then
                    local cf=Combat.PartCFrame(o.actor,p)
                    for _,offset in ipairs({0,.35,-.35}) do
                        local point=cf:PointToWorldSpace(Vector3.new(0,p.Size.Y*offset,0))
                        local hit=workspace:Raycast(camera.CFrame.Position,point-camera.CFrame.Position,ray)
                        if not hit then o.partClear[p]=true;break end
                    end
                end
            end
        end
        if not anchor then
            anchor=Instance.new("Part");anchor.Name="LeanNPCOverlayAnchor"
            anchor.Size=Vector3.new(.01,.01,.01);anchor.CFrame=CFrame.identity
            anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false
            anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false
        end
        anchor.Parent=workspace.CurrentCamera
        for i,p in ipairs(o.parts) do
            if p:IsDescendantOf(o.model) and p~=o.actor.RootPart then
                local clear=o.partClear and o.partClear[p]
                local col=clear and cfg.visibleColor or cfg.occludedColor
                local alpha=clear and cfg.visibleIntensity or cfg.occludedIntensity
                local ad=o.adornments[i]
                if not ad then
                    ad=Instance.new("BoxHandleAdornment");ad.Name="LeanNPCChams"
                    ad.Adornee=anchor;ad.AlwaysOnTop=true;ad.ZIndex=3;ad.Parent=anchor
                    o.adornments[i]=ad
                end
                ad.Size=p.Size;ad.CFrame=Combat.PartCFrame(o.actor,p);ad.Color3=teamColor or col
                ad.Transparency=1-math.clamp(alpha,0,1);ad.Visible=alpha>0
            end
        end
    end
    function E.RenderActor(o,camera,origin)
        hide(o)
        local a=o.actor
        local kind=o.preview and a.Kind or E.Kind(a)
        if o.preview then o.previewViewportSize=camera.ViewportSize end
        if not kind then return end
        -- per-zombie-type visibility filter
        if kind=="zombies" then
            local ability=a.Health and type(a.Health)=="table" and a.Health.Ability
            local filter=E.teamSettings.zombies.abilityFilter
            if ability and filter and filter[ability]==false then return end
        end
        local t=E.teamSettings[kind]
        local enabledChams=E.chams[kind] and E.chams[kind].enabled
        local enabledSkeleton=E.advanced[kind] and E.advanced[kind].skeleton
        if not t.enabled or not (t.box or t.box3d or t.boxFill or t.name or t.weapon
            or t.distance or t.healthBar or t.healthText or t.tracer or t.offScreenArrow
            or enabledChams or enabledSkeleton) then return end
        if not o.preview and kind=="players" and t.teamCheck and Combat.IsTeammate(a) then return end
        -- Fail closed every frame, including owner changes and replacement models.
        if not t.enabled or (not o.preview and not E.Kind(a)) or a.Character~=o.model or not o.model.Parent
            or (not o.preview and kind~="corpses" and not Combat.IsAlive(a)) then return end
        local root=a.RootPart
        local position=a.Position or (root and root.Position)
        if kind=="corpses" then
            if not o.model:IsDescendantOf(workspace) then return end
            root=nil
            position=o.model:GetPivot().Position
        end
        if typeof(position)~="Vector3" then return end
        local dist=(position-origin).Magnitude
        local shared=E.sharedSettings
        if t.limitDistance and dist>t.maxDistance then return end
        local adv=E.advanced[kind]
        local override=shared.teamBasedColor and (o.preview and a.PreviewTeamColor or E.TeamColor(a)) or nil
        local delta=root and position-root.Position or Vector3.zero
        local view=camera.ViewportSize
        local sp,onScreen=camera:WorldToViewportPoint(position)
        if not onScreen and t.offScreenArrow then
            local rel=camera.CFrame:PointToObjectSpace(position)
            local direction=Vector2.new(rel.X,rel.Z)
            if direction.Magnitude<.0001 then direction=Vector2.new(0,1) else direction=direction.Unit end
            local center=view*.5
            local radius=math.min(t.offScreenArrowRadius,math.max(0,math.min(view.X,view.Y)*.5-t.offScreenArrowSize-4))
            local tip=center+direction*radius
            local back=tip-direction*t.offScreenArrowSize
            local side=Vector2.new(-direction.Y,direction.X)*t.offScreenArrowSize*.5
            local d=drawing(o,"arrow","Triangle")
            d.PointA=tip;d.PointB=back+side;d.PointC=back-side;d.Filled=true;style(d,t.offScreenArrowColor,override)
        end
        if sp.Z<=.05 then
            if adv.skeleton then renderSkeleton(o,camera,adv,override) end
            return
        end
        local needsBox=t.box or t.box3d or t.boxFill or t.name or t.weapon or t.distance or t.healthBar or t.healthText or t.tracer
        local min,max,corners
        if needsBox then
            local center,size=bodyBounds(o,delta,position)
            corners={}
            for i,sign in ipairs(signs) do
                local p=camera:WorldToViewportPoint(center+size*.5*sign)
                corners[i]=p
                if p.Z>.05 then
                    local v=Vector2.new(p.X,p.Y)
                    min=min and min:Min(v) or v;max=max and max:Max(v) or v
                end
            end
        end
        local boxVisible=min and max and max.X>=0 and max.Y>=0 and min.X<=view.X and min.Y<=view.Y
        if not o.preview and (onScreen or boxVisible) then chams(o,camera,delta,position,override) end
        if boxVisible then
            local size=max-min;local cx=(min.X+max.X)*.5
            if t.boxFill then square(o,"fill",min,size,t.boxFillColor,true,1,override) end
            if t.box then
                if t.boxOutline then square(o,"boxOutline",min,size,t.boxOutlineColor,false,1+2*t.boxOutlineThickness) end
                square(o,"box",min,size,t.boxColor,false,1,override)
            end
            if t.box3d then
                for i,edge in ipairs(edges) do
                    local p,q=corners[edge[1]],corners[edge[2]]
                    if p.Z>.05 and q.Z>.05 then
                        local v,w=Vector2.new(p.X,p.Y),Vector2.new(q.X,q.Y)
                        if t.boxOutline then line(o,"edgeOutline"..i,v,w,t.boxOutlineColor,1+2*t.boxOutlineThickness) end
                        line(o,"edge"..i,v,w,t.box3dColor,1,override)
                    end
                end
            end
            local hp,maxhp=type(a.Health)=="number" and a.Health or 0,a.MaxHealth or 100
            local ratio=math.clamp(hp/math.max(1,maxhp),0,1)
            if t.healthBar then
                local bottom=Vector2.new(min.X-5,max.Y)
                if t.healthBarOutline then line(o,"hpOutline",bottom+Vector2.new(0,1),Vector2.new(min.X-5,min.Y-1),black,4) end
                line(o,"hp",bottom,Vector2.new(min.X-5,max.Y-size.Y*ratio),t.dyingColor:Lerp(t.healthyColor,ratio),2)
            end
            if t.healthText then textAt(o,"hpText",math.ceil(hp),Vector2.new(min.X-20,max.Y-size.Y*ratio-shared.textSize*.5),t.healthTextColor,t.healthTextOutline) end
            if t.name then
                local label=kind=="players" and a.Owner.Name or o.model.Name
                if kind=="players" and adv.nameType=="Display Name" then label=a.Owner.DisplayName
                elseif adv.nameType=="Display Name" then
                    label=a.DisplayName or (a.OwnerName~="???" and a.OwnerName) or (a.Zombie and "Zombie" or "NPC")
                    if not o.preview then label=tostring(label).." ["..tostring(a.UID):sub(1,6).."]" end
                end
                if kind=="zombies" then
                    label=(o.model and o.model.Name or "Zombie"):gsub("^AI_",""):gsub("_+"," "):gsub("^ ",""):gsub(" $","")
                    local _abilityTag={[1]="Crippled",[2]="Slow",[3]="Normal",[4]="Sprinter"}
                    local _ab=a.Health and type(a.Health)=="table" and a.Health.Ability
                    if _ab and _abilityTag[_ab] then label=label.." ["..(_abilityTag[_ab]).."]" end
                elseif kind=="corpses" then label="Corpse: "..(a.Zombie and "Zombie" or (E.IsPlayer(a) and a.Owner.Name or "NPC")) end
                textAt(o,"name",label,Vector2.new(cx,min.Y-shared.textSize-3),t.nameColor,t.nameOutline,override)
            end
            local textY=max.Y+2
            if kind=="players" and t.weapon then textAt(o,"weapon",o.preview and a.PreviewWeapon or E.Weapon(a),Vector2.new(cx,textY),t.weaponColor,t.weaponOutline,override);textY+=shared.textSize+2 end
            if t.distance then textAt(o,"distance",string.format("%.0f studs",dist),Vector2.new(cx,textY),t.distanceColor,t.distanceOutline,override) end
            if t.tracer then
                local y=t.tracerOrigin=="Top" and 0 or (t.tracerOrigin=="Middle" and view.Y*.5 or view.Y)
                local from,to=Vector2.new(view.X*.5,y),Vector2.new(cx,max.Y)
                if t.tracerOutline then line(o,"tracerOutline",from,to,black,3) end
                line(o,"tracer",from,to,t.tracerColor,1,override)
            end
        end
        if adv.skeleton then renderSkeleton(o,camera,adv,override) end
    end
    function E.Render(cameraOverride)
        if E.Paused then return end
        E.Sync()
        local camera=cameraOverride or workspace.CurrentCamera
        if not camera then return end
        local c=E.Service();local me=c and c.Replicator and c.Replicator.LocalActor
        local origin=me and me.Position or camera.CFrame.Position
        for actor,o in pairs(E.objects) do
            local ok,err=pcall(E.RenderActor,o,camera,origin)
            if not ok then
                hide(o)
                if not E.errors[tostring(err)] then E.errors[tostring(err)]=true;warn("[NPC ESP]",err) end
            end
        end
    end
    function E.Load()
        if E._hasLoaded then return end
        E._hasLoaded=true
        E.Sync(true)
        connection=AimRunService.RenderStepped:Connect(function() E.Render() end)
    end
    function E.Unload()
        if connection then connection:Disconnect();connection=nil end
        for a,o in pairs(E.objects) do destroy(o);E.objects[a]=nil end
        if anchor then anchor:Destroy();anchor=nil end
        if E.textGui then E.textGui:Destroy(); E.textGui=nil end
        E._hasLoaded=false
    end
    function E.CreatePreviewObject(actor,factory)
        local o:any={actor=actor,model=actor.Character,drawings={},adornments={},nextRay=0,preview=true,DrawingFactory=factory}
        rig(o)
        return o
    end
    E.DestroyPreviewObject=destroy
    return E
end)()

Combat.ESP = Sense
local destroyBeforeVisuals = Combat.Destroy
Combat.Destroy = function()
    Sense.Unload()
    destroyBeforeVisuals()
end
-- ── HIGHLIGHT ESP INFRASTRUCTURE ─────────────────────────────────
do
    local hlInstances = {}
    local hlSettings = {
        npc     = {enabled=false,fillColor=Color3.fromRGB(255,170,0),  outlineColor=Color3.fromRGB(255,255,255),fillTransp=0.5,outlineTransp=0},
        players = {enabled=false,fillColor=Color3.fromRGB(255,50,50),  outlineColor=Color3.fromRGB(255,255,255),fillTransp=0.5,outlineTransp=0},
        -- zombies: single fill OR per-ability fill colors (1=Crippled 2=Slow 3=Normal 4=Sprinter)
        zombies = {enabled=false,
            useAbilityColors=true,
            fillColor=Color3.fromRGB(255,50,0),
            abilityColors={
                [1]=Color3.fromRGB(148,74,0),
                [2]=Color3.fromRGB(255,255,0),
                [3]=Color3.fromRGB(255,0,0),
                [4]=Color3.fromRGB(148,0,255),
            },
            abilityEnabled={[1]=true,[2]=true,[3]=true,[4]=true},
            outlineColor=Color3.fromRGB(255,255,255),fillTransp=0.5,outlineTransp=0},
        corpses = {enabled=false,fillColor=Color3.fromRGB(150,150,150),outlineColor=Color3.fromRGB(200,200,200),fillTransp=0.5,outlineTransp=0},
    }
    Sense.highlightSettings = hlSettings
    local function destroyHL(actor)
        if hlInstances[actor] then
            pcall(function() hlInstances[actor]:Destroy() end)
            hlInstances[actor]=nil
        end
    end
    local function syncHL()
        for actor,obj in pairs(Sense.objects) do
            local kind=Sense.Kind(actor)
            local cfg=kind and hlSettings[kind]
            -- skip 3D-preview models (not in workspace) and team-mates
            local inWorld=obj.model and obj.model.Parent and obj.model:IsDescendantOf(workspace)
            local isTeammate=kind=="players" and Sense.teamSettings.players.teamCheck and Combat.IsTeammate(actor)
            local espEnabled = Sense.teamSettings[kind] and Sense.teamSettings[kind].enabled
            if cfg and cfg.enabled and espEnabled and inWorld and not isTeammate then
                local hl=hlInstances[actor]
                if not hl or not hl.Parent then
                    hl=Instance.new("Highlight")
                    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent=obj.model
                    hlInstances[actor]=hl
                end
                if kind=="zombies" then
                    local ability=actor.Health and type(actor.Health)=="table" and actor.Health.Ability
                    -- per-ability toggle: if this type is disabled, destroy and skip
                    if ability and cfg.abilityEnabled and cfg.abilityEnabled[ability]==false then
                        destroyHL(actor); continue
                    end
                    local fillColor=(ability and cfg.abilityColors and cfg.abilityColors[ability])
                        or (cfg.abilityColors and cfg.abilityColors[3]) or Color3.fromRGB(255,0,0)
                    hl.FillColor=fillColor
                else
                    hl.FillColor=cfg.fillColor
                end
                hl.OutlineColor=cfg.outlineColor
                hl.FillTransparency=cfg.fillTransp
                hl.OutlineTransparency=cfg.outlineTransp
            else
                destroyHL(actor)
            end
        end
        for actor in pairs(hlInstances) do
            if not Sense.objects[actor] then destroyHL(actor) end
        end
    end
    table.insert(Combat.connections,AimRunService.Heartbeat:Connect(syncHL))
    local prevDestroyHL=Combat.Destroy
    Combat.Destroy=function()
        for actor in pairs(hlInstances) do destroyHL(actor) end
        prevDestroyHL()
    end
end
-- Adapt the Tokaihub visual controls to Linoria without changing the renderer.
local visualPages = {}
local function visualPage(name)
    local page = { Name = name, Groups = {} }
    table.insert(visualPages, page)
    function page:AddSection(info)
        local group = info.Side == 'Right' and Tabs.Visuals:AddRightGroupbox(info.Title)
            or Tabs.Visuals:AddLeftGroupbox(info.Title)
        table.insert(self.Groups, group)
        local section = {}
        local lastToggle
        function section:AddToggle(data)
            local control = group:AddToggle(data.Flag, { Text = data.Text, Default = data.Default })
            control:OnChanged(data.Callback)
            lastToggle = control
            return control
        end
        function section:AddDropdown(data)
            local control = group:AddDropdown(data.Flag, {
                Text = data.Text, Values = data.Options, Default = data.Default,
                Multi = data.Multi or false,
            })
            control:OnChanged(data.Callback)
            return control
        end
        function section:AddSlider(data)
            local control = group:AddSlider(data.Flag, {
                Text = data.Text, Default = data.Default, Min = data.Min, Max = data.Max,
                Rounding = data.Rounding or 0, Suffix = data.Suffix or '',
            })
            control:OnChanged(data.Callback)
            return control
        end
        function section:AddColorPicker(data)
            assert(lastToggle, 'A visual color picker must belong to a toggle')
            lastToggle:AddColorPicker(data.Flag, {
                Default = data.Default, Title = data.Text,
                Transparency = data.Transparency ~= nil and 1 - data.Transparency or nil,
            })
            local picker = Options[data.Flag]
            picker:OnChanged(function(color)
                data.Callback(color, data.Transparency ~= nil and 1 - picker.Transparency or nil)
            end)
            return picker
        end
        return section
    end
    return page
end
local NpcPage = visualPage('NPCs')
local PlayersPage = visualPage('Players')
local ZombiePage = visualPage('Zombies')
local CorpsePage = visualPage('Corpses')
local CrosshairPage = visualPage('Crosshair')
local CrosshairGroup = Tabs.Visuals:AddLeftGroupbox('Crosshair')
table.insert(CrosshairPage.Groups, CrosshairGroup)
local Crosshair = {
    Enabled=false, Color=Color3.new(1,1,1), Style="Static", Speed=1,
    FollowTarget=false, Length=10, Gap=4, Thickness=1, Segments=4,
    Outline=true, OutlineColor=Color3.new(0,0,0),
    CenterDot=false, DotColor=Color3.new(1,1,1), Phase=0
}
Combat.Crosshair=Crosshair
local CrosshairTargetSettings=setmetatable({FOVEnabled=true},{__index=Silent})
CrosshairGroup:AddToggle('crosshair_enabled',{Text='Enabled',Default=false})
Toggles.crosshair_enabled:OnChanged(function(v) Crosshair.Enabled=v end)
Toggles.crosshair_enabled:AddColorPicker('crosshair_color',{Title='Color',Default=Crosshair.Color})
Options.crosshair_color:OnChanged(function(v) Crosshair.Color=v end)
CrosshairGroup:AddDropdown('crosshair_style',{Text='Style',Values={'Static','Spin'},Default='Static'})
local CrosshairSpeed=CrosshairGroup:AddDependencyBox()
CrosshairSpeed:AddSlider('crosshair_speed',{Text='Speed',Min=.1,Max=5,Default=1,Rounding=1,Suffix=' rev/s'})
Options.crosshair_speed:OnChanged(function(v) Crosshair.Speed=v end)
local CrosshairSpinDependency={Type='Toggle',Value=false}
CrosshairSpeed:SetupDependencies({{CrosshairSpinDependency,true}})
Options.crosshair_style:OnChanged(function(v)
    Crosshair.Style=v
    CrosshairSpinDependency.Value=v=='Spin'
    CrosshairSpeed:Update()
end)
CrosshairGroup:AddToggle('crosshair_follow',{Text='Follow Target',Default=false})
Toggles.crosshair_follow:OnChanged(function(v) Crosshair.FollowTarget=v end)
for _,info in ipairs({
    {'length','Length',1,40,10}, {'gap','Gap',0,30,4},
    {'thickness','Thickness',1,8,1}, {'segments','Segments',1,8,4}
}) do
    local key=info[2]
    CrosshairGroup:AddSlider('crosshair_'..info[1],{
        Text=key,Min=info[3],Max=info[4],Default=info[5],Rounding=0,
        Suffix=key=='Segments' and '' or 'px'
    })
    Options['crosshair_'..info[1]]:OnChanged(function(v) Crosshair[key]=v end)
end
CrosshairGroup:AddToggle('crosshair_outline',{Text='Outline',Default=true})
Toggles.crosshair_outline:OnChanged(function(v) Crosshair.Outline=v end)
Toggles.crosshair_outline:AddColorPicker('crosshair_outline_color',{Title='Outline Color',Default=Crosshair.OutlineColor})
Options.crosshair_outline_color:OnChanged(function(v) Crosshair.OutlineColor=v end)
CrosshairGroup:AddToggle('crosshair_dot',{Text='Center Dot',Default=false})
Toggles.crosshair_dot:OnChanged(function(v) Crosshair.CenterDot=v end)
Toggles.crosshair_dot:AddColorPicker('crosshair_dot_color',{Title='Center Dot Color',Default=Crosshair.DotColor})
Options.crosshair_dot_color:OnChanged(function(v) Crosshair.DotColor=v end)
local CrosshairLines,CrosshairOutlines={},{}
local function crosshairDrawing(class,z)
    local d=Drawing.new(class)
    d.Visible=false;d.Transparency=1;d.ZIndex=z
    table.insert(Combat.drawings,d)
    return d
end
for i=1,8 do
    CrosshairOutlines[i]=crosshairDrawing('Line',19)
    CrosshairLines[i]=crosshairDrawing('Line',20)
end
local CrosshairDotOutline=crosshairDrawing('Circle',21)
local CrosshairDot=crosshairDrawing('Circle',22)
CrosshairDotOutline.Filled=true;CrosshairDot.Filled=true
table.insert(Combat.connections,AimRunService.RenderStepped:Connect(function(dt)
    local camera=workspace.CurrentCamera
    local enabled=Combat.active and Crosshair.Enabled and camera~=nil
    if not enabled then
        for i=1,8 do CrosshairLines[i].Visible=false;CrosshairOutlines[i].Visible=false end
        CrosshairDot.Visible=false;CrosshairDotOutline.Visible=false
        return
    end
    local center=aim_getMouseLocation()
    local selected
    if Crosshair.FollowTarget then
        selected=Combat.FindTarget(CrosshairTargetSettings,camera,center,Crosshair.sticky)
        Crosshair.sticky=selected and selected.actor
    else Crosshair.sticky=nil end
    if selected and selected.part and selected.part.Parent then
        local point=Combat.PartPosition(selected.actor,selected.part)
        local projected,onScreen=camera:WorldToViewportPoint(point)
        local screen=Vector2.new(projected.X,projected.Y)
        if onScreen and projected.Z>0 and (screen-center).Magnitude<=Silent.FOV then center=screen end
    end
    if Crosshair.Style=='Spin' then
        Crosshair.Phase=(Crosshair.Phase+dt*Crosshair.Speed*math.pi*2)%(math.pi*2)
    else Crosshair.Phase=0 end
    local count=math.clamp(math.floor(Crosshair.Segments),1,8)
    for i=1,8 do
        local line,outline=CrosshairLines[i],CrosshairOutlines[i]
        line.Visible=i<=count;outline.Visible=i<=count and Crosshair.Outline
        if i<=count then
            local angle=Crosshair.Phase+(i-1)*math.pi*2/count
            local direction=Vector2.new(math.cos(angle),math.sin(angle))
            line.From=center+direction*Crosshair.Gap
            line.To=center+direction*(Crosshair.Gap+Crosshair.Length)
            line.Color=Crosshair.Color;line.Thickness=Crosshair.Thickness
            outline.From=line.From-direction;outline.To=line.To+direction
            outline.Color=Crosshair.OutlineColor;outline.Thickness=Crosshair.Thickness+2
        end
    end
    CrosshairDot.Visible=Crosshair.CenterDot
    CrosshairDotOutline.Visible=Crosshair.CenterDot and Crosshair.Outline
    CrosshairDot.Position=center;CrosshairDot.Radius=math.max(1,Crosshair.Thickness*.5)
    CrosshairDot.Color=Crosshair.DotColor
    CrosshairDotOutline.Position=center;CrosshairDotOutline.Radius=CrosshairDot.Radius+1
    CrosshairDotOutline.Color=Crosshair.OutlineColor
end))
local SharedPage = visualPage('Settings')

local ChamsEngine, AdvancedESP = Sense.chams, Sense.advanced
local function espSetColor(tbl,key)
    return function(c,a)
        if type(tbl[key])=="table" then tbl[key][1]=c;if a~=nil then tbl[key][2]=a end
        else tbl[key]=c end
    end
end
local function espDefault(tbl,key)
    if type(tbl[key])=="table" then return tbl[key][1],tbl[key][2] end
    return tbl[key],1
end


local function addESPDistance(section,kind)
    local settings=Sense.teamSettings[kind]
    section:AddToggle({Text="Distance Check",Flag=kind.."_distance_check",Default=settings.limitDistance,
        Callback=function(v) settings.limitDistance=v end})
    section:AddSlider({Text="Max Distance",Flag=kind.."_max_distance",Min=50,Max=2000,
        Default=settings.maxDistance,Suffix=" studs",Callback=function(v) settings.maxDistance=v end})
end
local NpcGeneral = NpcPage:AddSection({Title="General",Side="Left"})
NpcGeneral:AddToggle({Text="ESP Enabled",Flag="npc_enabled",Default=true,
    Callback=function(v) Sense.teamSettings.npc.enabled=v end})
addESPDistance(NpcGeneral,"npc")
local function buildTeamPage(page, team)
    local t     = Sense.teamSettings[team]
    local chams = ChamsEngine[team]
    local adv   = AdvancedESP[team]
    local prefix = team .. "_"

    -- Box state (single toggle + 2D/3D dropdown, mutually exclusive)
    local boxState = {enabled = false, kind = "2D"}
    local function applyBox()
        t.box   = boxState.enabled and boxState.kind == "2D"
        t.box3d = boxState.enabled and boxState.kind == "3D"
    end

    -- ═══ LEFT: Boxes ═══════════════════════════════════════════
    local Boxes = page:AddSection({Title = "Boxes", Side = "Left"})

    Boxes:AddToggle({
        Text = "Box",
        Flag = prefix .. "box",
        Default = false,
        Callback = function(v) boxState.enabled = v; applyBox() end
    })

    Boxes:AddDropdown({
        Text = "Box Type",
        Flag = prefix .. "box_type",
        Options = {"2D", "3D"},
        Default = "2D",
        Callback = function(v) boxState.kind = v; applyBox() end
    })

    Boxes:AddColorPicker({
        Text = "Box Color",
        Flag = prefix .. "boxColor",
        Default = (espDefault(t, "boxColor")),
        Transparency = select(2, espDefault(t, "boxColor")),
        Callback = function(color, alpha)
            -- one picker drives both 2D and 3D box colors
            espSetColor(t, "boxColor")(color, alpha)
            espSetColor(t, "box3dColor")(color, alpha)
        end
    })

    Boxes:AddToggle({
        Text = "Box Outline",
        Flag = prefix .. "boxOutline",
        Default = t.boxOutline,
        Callback = function(v) t.boxOutline = v end
    })

    Boxes:AddColorPicker({
        Text = "Outline Color",
        Flag = prefix .. "boxOutlineColor",
        Default = (espDefault(t, "boxOutlineColor")),
        Transparency = select(2, espDefault(t, "boxOutlineColor")),
        Callback = espSetColor(t, "boxOutlineColor")
    })

    Boxes:AddToggle({
        Text = "Box Fill",
        Flag = prefix .. "boxFill",
        Default = t.boxFill,
        Callback = function(v) t.boxFill = v end
    })

    Boxes:AddColorPicker({
        Text = "Fill Color",
        Flag = prefix .. "boxFillColor",
        Default = (espDefault(t, "boxFillColor")),
        Transparency = select(2, espDefault(t, "boxFillColor")),
        Callback = espSetColor(t, "boxFillColor")
    })

    -- ═══ LEFT: Health ══════════════════════════════════════════
    if team=="npc" or team=="players" then
    local Health = page:AddSection({Title = "Health", Side = "Left"})

    Health:AddToggle({
        Text = "Health Bar",
        Flag = prefix .. "healthBar",
        Default = t.healthBar,
        Callback = function(v) t.healthBar = v end
    })
    Health:AddColorPicker({
        Text = "Healthy Color",
        Flag = prefix .. "healthyColor",
        Default = (espDefault(t, "healthyColor")),
        Callback = espSetColor(t, "healthyColor")
    })
    Health:AddColorPicker({
        Text = "Dying Color",
        Flag = prefix .. "dyingColor",
        Default = (espDefault(t, "dyingColor")),
        Callback = espSetColor(t, "dyingColor")
    })
    Health:AddToggle({
        Text = "Health Bar Outline",
        Flag = prefix .. "healthBarOutline",
        Default = t.healthBarOutline,
        Callback = function(v) t.healthBarOutline = v end
    })

    Health:AddToggle({
        Text = "Health Text",
        Flag = prefix .. "healthText",
        Default = t.healthText,
        Callback = function(v) t.healthText = v end
    })
    Health:AddColorPicker({
        Text = "Text Color",
        Flag = prefix .. "healthTextColor",
        Default = (espDefault(t, "healthTextColor")),
        Transparency = select(2, espDefault(t, "healthTextColor")),
        Callback = espSetColor(t, "healthTextColor")
    })
    Health:AddToggle({
        Text = "Health Text Outline",
        Flag = prefix .. "healthTextOutline",
        Default = t.healthTextOutline,
        Callback = function(v) t.healthTextOutline = v end
    })

    end
    -- ═══ LEFT: Skeleton ════════════════════════════════════════
    local Skeleton = page:AddSection({Title = "Skeleton", Side = "Left"})

    Skeleton:AddToggle({
        Text = "Skeleton",
        Flag = prefix .. "skeleton",
        Default = false,
        Callback = function(v) adv.skeleton = v end
    })

    Skeleton:AddColorPicker({
        Text = "Skeleton Color",
        Flag = prefix .. "skeleton_color",
        Default = adv.skeletonColor,
        Transparency = adv.skeletonOpacity,
        Callback = function(color, opacity)
            adv.skeletonColor = color
            adv.skeletonOpacity = opacity
        end
    })
    Skeleton:AddSlider({
        Text = "Thickness", Flag = prefix .. "skeleton_thickness",
        Min = 1, Max = 4, Default = adv.skeletonThickness, Suffix = " px",
        Callback = function(v) adv.skeletonThickness = v end
    })
    Skeleton:AddToggle({
        Text = "Skeleton Outline", Flag = prefix .. "skeleton_outline",
        Default = adv.skeletonOutline,
        Callback = function(v) adv.skeletonOutline = v end
    })
    Skeleton:AddColorPicker({
        Text = "Outline Color", Flag = prefix .. "skeleton_outline_color",
        Default = adv.skeletonOutlineColor,
        Callback = function(color) adv.skeletonOutlineColor = color end
    })

    -- ═══ RIGHT: Text ═══════════════════════════════════════════
    local TextSec = page:AddSection({Title = "Text", Side = "Right"})

    TextSec:AddToggle({
        Text = "Name",
        Flag = prefix .. "name",
        Default = t.name,
        Callback = function(v) t.name = v end
    })
    TextSec:AddDropdown({
        Text = "Name Type",
        Flag = prefix .. "name_type",
        Options = {"Name", "Display Name"},
        Default = "Name",
        Callback = function(v) adv.nameType = v end
    })
    TextSec:AddColorPicker({
        Text = "Name Color",
        Flag = prefix .. "nameColor",
        Default = (espDefault(t, "nameColor")),
        Transparency = select(2, espDefault(t, "nameColor")),
        Callback = espSetColor(t, "nameColor")
    })
    TextSec:AddToggle({
        Text = "Name Outline",
        Flag = prefix .. "nameOutline",
        Default = t.nameOutline,
        Callback = function(v) t.nameOutline = v end
    })

    if team=="players" then
    TextSec:AddToggle({
        Text = "Weapon",
        Flag = prefix .. "weapon",
        Default = t.weapon,
        Callback = function(v) t.weapon = v end
    })
    TextSec:AddColorPicker({
        Text = "Weapon Color",
        Flag = prefix .. "weaponColor",
        Default = (espDefault(t, "weaponColor")),
        Transparency = select(2, espDefault(t, "weaponColor")),
        Callback = espSetColor(t, "weaponColor")
    })
    TextSec:AddToggle({
        Text = "Weapon Outline",
        Flag = prefix .. "weaponOutline",
        Default = t.weaponOutline,
        Callback = function(v) t.weaponOutline = v end
    })

    end
    TextSec:AddToggle({
        Text = "Distance",
        Flag = prefix .. "distance",
        Default = t.distance,
        Callback = function(v) t.distance = v end
    })
    TextSec:AddColorPicker({
        Text = "Distance Color",
        Flag = prefix .. "distanceColor",
        Default = (espDefault(t, "distanceColor")),
        Transparency = select(2, espDefault(t, "distanceColor")),
        Callback = espSetColor(t, "distanceColor")
    })
    TextSec:AddToggle({
        Text = "Distance Outline",
        Flag = prefix .. "distanceOutline",
        Default = t.distanceOutline,
        Callback = function(v) t.distanceOutline = v end
    })

    -- ═══ RIGHT: Tracer & Arrow ═════════════════════════════════
    local Tracers = page:AddSection({Title = "Tracer & Arrow", Side = "Right"})

    Tracers:AddToggle({
        Text = "Tracer",
        Flag = prefix .. "tracer",
        Default = t.tracer,
        Callback = function(v) t.tracer = v end
    })
    Tracers:AddDropdown({
        Text = "Tracer Origin",
        Flag = prefix .. "tracer_origin",
        Options = {"Top", "Middle", "Bottom"},
        Default = t.tracerOrigin,
        Callback = function(v) t.tracerOrigin = v end
    })
    Tracers:AddColorPicker({
        Text = "Tracer Color",
        Flag = prefix .. "tracerColor",
        Default = (espDefault(t, "tracerColor")),
        Transparency = select(2, espDefault(t, "tracerColor")),
        Callback = espSetColor(t, "tracerColor")
    })
    Tracers:AddToggle({
        Text = "Tracer Outline",
        Flag = prefix .. "tracerOutline",
        Default = t.tracerOutline,
        Callback = function(v) t.tracerOutline = v end
    })

    Tracers:AddToggle({
        Text = "Off Screen Arrow",
        Flag = prefix .. "offScreenArrow",
        Default = t.offScreenArrow,
        Callback = function(v) t.offScreenArrow = v end
    })
    Tracers:AddSlider({
        Text = "Arrow Size",
        Flag = prefix .. "arrow_size",
        Min = 5, Max = 40,
        Default = t.offScreenArrowSize,
        Suffix = "px",
        Callback = function(v) t.offScreenArrowSize = v end
    })
    Tracers:AddSlider({
        Text = "Arrow Radius",
        Flag = prefix .. "arrow_radius",
        Min = 50, Max = 400,
        Default = t.offScreenArrowRadius,
        Suffix = "px",
        Callback = function(v) t.offScreenArrowRadius = v end
    })
    Tracers:AddColorPicker({
        Text = "Arrow Color",
        Flag = prefix .. "offScreenArrowColor",
        Default = (espDefault(t, "offScreenArrowColor")),
        Transparency = select(2, espDefault(t, "offScreenArrowColor")),
        Callback = espSetColor(t, "offScreenArrowColor")
    })

    -- ═══ RIGHT: Chams ══════════════════════════════
    local ChamsSec = page:AddSection({Title = "Chams", Side = "Right"})

    ChamsSec:AddToggle({
        Text = "Chams",
        Flag = prefix .. "cs2_chams",
        Default = false,
        Callback = function(v) chams.enabled = v end
    })

    ChamsSec:AddColorPicker({
        Text = "Visible",
        Flag = prefix .. "cs2_visible",
        Default = chams.visibleColor,
        Transparency = chams.visibleIntensity,
        Callback = function(color, alpha)
            chams.visibleColor = color
            if alpha ~= nil then chams.visibleIntensity = alpha end
        end
    })

    ChamsSec:AddColorPicker({
        Text = "Occluded",
        Flag = prefix .. "cs2_occluded",
        Default = chams.occludedColor,
        Transparency = chams.occludedIntensity,
        Callback = function(color, alpha)
            chams.occludedColor = color
            if alpha ~= nil then chams.occludedIntensity = alpha end
        end
    })

    -- ── Highlight ─────────────────────────────────────────────────
    local hlCfg = Sense.highlightSettings and Sense.highlightSettings[team]
    if hlCfg then
        local HLSec = page:AddSection({Title = "Highlight", Side = "Right"})
        HLSec:AddToggle({Text="Highlight",Flag=prefix.."hl_enabled",Default=false,
            Callback=function(v) hlCfg.enabled=v end})
        if team=="zombies" then
            -- tipmobile style: each zombie type = own row [toggle] + [color], ordered Crippled/Slow/Normal/Sprinter
            local abilityLabels={[1]="Zombie: Crippled",[2]="Zombie: Slow",[3]="Zombie: Normal",[4]="Zombie: Sprinter"}
            for ability=1,4 do
                local ab=ability
                HLSec:AddToggle({Text=abilityLabels[ab],Flag=prefix.."hl_zb_en"..ab,
                    Default=(hlCfg.abilityEnabled==nil or hlCfg.abilityEnabled[ab]~=false),
                    Callback=function(v)
                        if not hlCfg.abilityEnabled then hlCfg.abilityEnabled={[1]=true,[2]=true,[3]=true,[4]=true} end
                        hlCfg.abilityEnabled[ab]=v
                    end})
                HLSec:AddColorPicker({Text="Color",Flag=prefix.."hl_zb"..ab,
                    Default=hlCfg.abilityColors[ab],
                    Callback=function(color) hlCfg.abilityColors[ab]=color end})
            end
        else
            HLSec:AddColorPicker({Text="Fill Color",Flag=prefix.."hl_fill",
                Default=hlCfg.fillColor,
                Callback=function(color) hlCfg.fillColor=color end})
        end
        HLSec:AddColorPicker({Text="Outline Color",Flag=prefix.."hl_outline",
            Default=hlCfg.outlineColor,
            Callback=function(color) hlCfg.outlineColor=color end})
        -- Transparency sliders: 0 = fully visible, 1 = invisible
        HLSec:AddSlider({Text="Fill Transparency",Flag=prefix.."hl_fill_transp",
            Min=0,Max=1,Default=hlCfg.fillTransp,Rounding=2,Suffix="",
            Callback=function(v) hlCfg.fillTransp=v end})
        HLSec:AddSlider({Text="Outline Transparency",Flag=prefix.."hl_outline_transp",
            Min=0,Max=1,Default=hlCfg.outlineTransp,Rounding=2,Suffix="",
            Callback=function(v) hlCfg.outlineTransp=v end})
    end
end

buildTeamPage(NpcPage,"npc")
local PlayerGeneral=PlayersPage:AddSection({Title="General",Side="Left"})
PlayerGeneral:AddToggle({Text="ESP Enabled",Flag="players_enabled",Default=false,
    Callback=function(v) Sense.teamSettings.players.enabled=v end})
addESPDistance(PlayerGeneral,"players")
PlayerGeneral:AddToggle({Text="Team Check",Flag="players_team_check",Default=false,
    Callback=function(v) Sense.teamSettings.players.teamCheck=v end})
buildTeamPage(PlayersPage,"players")
for _,entry in ipairs({{ZombiePage,"zombies"},{CorpsePage,"corpses"}}) do
    local page,kind=entry[1],entry[2]
    local general=page:AddSection({Title="General",Side="Left"})
    general:AddToggle({Text="ESP Enabled",Flag=kind.."_enabled",Default=false,
        Callback=function(v) Sense.teamSettings[kind].enabled=v end})
    addESPDistance(general,kind)
    buildTeamPage(page,kind)
end
-- Settings page ───────────────────────────────────────────────
local SharedLeft = SharedPage:AddSection({Title = "Settings", Side = "Left"})

SharedLeft:AddSlider({
    Text = "Text Size",
    Flag = "esp_text_size",
    Min = 8, Max = 24,
    Default = Sense.sharedSettings.textSize,
    Callback = function(v) Sense.sharedSettings.textSize = v end
})

-- Roblox Drawing font indices
local ESP_FONT_MAP = { ["UI"] = 0, ["System"] = 1, ["Plex"] = 2, ["Monospace"] = 3 }
local espFonts={"UI","System","Plex","Monospace"}
for _,name in ipairs(Fonts.Names) do espFonts[#espFonts+1]=name end
SharedLeft:AddDropdown({
    Text = "Font",
    Flag = "esp_text_font",
    Options = espFonts,
    Default = "Plex",
    Callback = function(v)
        local previous = Sense.sharedSettings.fontName or 'Plex'
        if ESP_FONT_MAP[v] ~= nil then
            Sense.sharedSettings.textFace = nil
            Sense.sharedSettings.textFont = ESP_FONT_MAP[v]
            Sense.sharedSettings.fontName = v
            return
        end
        local ok, face = pcall(Fonts.Resolve, v)
        if ok then
            Sense.sharedSettings.textFace = face
            Sense.sharedSettings.fontName = v
        else
            Library:Notify('ESP font could not be loaded: ' .. tostring(v))
            warn('[Fonts] ' .. tostring(face))
            if Options.esp_text_font.Value ~= previous then Options.esp_text_font:SetValue(previous) end
        end
    end
})

SharedLeft:AddSlider({Text="Box Outline Thickness",Flag="npc_box_outline_thickness",Min=1,Max=5,Default=1,Suffix="px",
    Callback=function(v) Sense.teamSettings.npc.boxOutlineThickness=v;Sense.teamSettings.players.boxOutlineThickness=v end})

-- ── NIGHT VISION / THERMAL ────────────────────────────────────────
do
    local nvEffect,nvActive,nvMode=nil,false,"Night Vision"
    local NV_BUILTIN_KEYS={"Night Vision","Thermal"}
    local NV_BUILTIN_CFG={
        ["Night Vision"]={Brightness=0.5,Contrast=0.1,Saturation=-0.8,TintColor=Color3.fromRGB(130,255,130)},
        ["Thermal"]     ={Brightness=0.3,Contrast=0.5,Saturation=-1,  TintColor=Color3.fromRGB(255,120,40)},
    }
    local NV_PRESET_FILE="Tokaihub/BRM5/nv_presets.json"
    local userPresets={}
    pcall(function()
        if isfile(NV_PRESET_FILE) then
            local ok,decoded=pcall(function()
                return game:GetService("HttpService"):JSONDecode(readfile(NV_PRESET_FILE))
            end)
            if ok and type(decoded)=="table" then
                for name,cfg in pairs(decoded) do
                    if type(cfg)=="table" then
                        userPresets[name]={
                            Brightness=tonumber(cfg.Brightness) or 0,
                            Contrast  =tonumber(cfg.Contrast)   or 0,
                            Saturation=tonumber(cfg.Saturation) or 0,
                            TintColor =Color3.fromRGB(
                                tonumber(cfg.R) or 255,
                                tonumber(cfg.G) or 255,
                                tonumber(cfg.B) or 255),
                        }
                    end
                end
            end
        end
    end)
    local function savePresetsFile()
        pcall(function()
            local data={}
            for name,cfg in pairs(userPresets) do
                data[name]={
                    Brightness=cfg.Brightness, Contrast=cfg.Contrast, Saturation=cfg.Saturation,
                    R=math.floor(cfg.TintColor.R*255+0.5),
                    G=math.floor(cfg.TintColor.G*255+0.5),
                    B=math.floor(cfg.TintColor.B*255+0.5),
                }
            end
            if not isfolder("Tokaihub/BRM5") then makefolder("Tokaihub/BRM5") end
            writefile(NV_PRESET_FILE,game:GetService("HttpService"):JSONEncode(data))
        end)
    end
    local function getDropdownList()
        local list={}
        for _,n in ipairs(NV_BUILTIN_KEYS) do list[#list+1]=n end
        local userNames={}
        for name in pairs(userPresets) do userNames[#userNames+1]=name end
        table.sort(userNames)
        for _,n in ipairs(userNames) do list[#list+1]=n end
        return list
    end
    local function applyNV()
        if not nvActive then
            if nvEffect then nvEffect:Destroy();nvEffect=nil end;return
        end
        local Lighting=game:GetService("Lighting")
        if not nvEffect or not nvEffect.Parent then
            nvEffect=Instance.new("ColorCorrectionEffect")
            nvEffect.Name="ERISKOI_NV";nvEffect.Parent=Lighting
        end
        local cfg=NV_BUILTIN_CFG[nvMode] or userPresets[nvMode] or NV_BUILTIN_CFG["Night Vision"]
        nvEffect.Brightness=cfg.Brightness;nvEffect.Contrast=cfg.Contrast
        nvEffect.Saturation=cfg.Saturation;nvEffect.TintColor=cfg.TintColor
    end
    SharedLeft:AddToggle({Text="Night Vision",Flag="nv_enabled",Default=false,
        Callback=function(v) nvActive=v;applyNV() end})
    SharedLeft:AddDropdown({Text="NV Mode",Flag="nv_mode",
        Options=getDropdownList(),Default="Night Vision",
        Callback=function(v) nvMode=v;applyNV() end})
    -- Preset builder on the right side of the settings page
    local NVPresetSec=SharedPage:AddSection({Title="NV Preset Builder",Side="Right"})
    local NVRaw=SharedPage.Groups[#SharedPage.Groups]
    NVRaw:AddInput("nv_preset_name",{Text="Preset Name",Placeholder="Enter name...",Default=""})
    NVRaw:AddSlider("nv_build_brightness",{Text="Brightness",Min=-1,Max=1,Default=0,Rounding=2,Suffix=""})
    NVRaw:AddSlider("nv_build_contrast",  {Text="Contrast",  Min=-1,Max=1,Default=0,Rounding=2,Suffix=""})
    NVRaw:AddSlider("nv_build_saturation",{Text="Saturation",Min=-1,Max=1,Default=0,Rounding=2,Suffix=""})
    NVPresetSec:AddToggle({Text="Custom Tint",Flag="nv_build_tint_enabled",Default=false,Callback=function() end})
    NVPresetSec:AddColorPicker({Text="Tint Color",Flag="nv_build_tint",
        Default=Color3.fromRGB(130,255,130),Callback=function() end})
    NVRaw:AddButton("Save Preset",function()
        local name=Options["nv_preset_name"] and tostring(Options["nv_preset_name"].Value) or ""
        name=name:gsub("^%s+",""):gsub("%s+$","")
        if name=="" then Library:Notify("Enter a preset name first.");return end
        if NV_BUILTIN_CFG[name] then Library:Notify("Cannot overwrite built-in preset.");return end
        local tintEnabled=Options["nv_build_tint_enabled"] and Options["nv_build_tint_enabled"].Value or false
        local tintColor=tintEnabled and Options["nv_build_tint"] and Options["nv_build_tint"].Value or Color3.fromRGB(255,255,255)
        userPresets[name]={
            Brightness=Options["nv_build_brightness"] and Options["nv_build_brightness"].Value or 0,
            Contrast  =Options["nv_build_contrast"]   and Options["nv_build_contrast"].Value   or 0,
            Saturation=Options["nv_build_saturation"] and Options["nv_build_saturation"].Value or 0,
            TintColor =tintColor,
        }
        savePresetsFile()
        Options["nv_mode"]:SetValues(getDropdownList())
        Library:Notify("Preset '"..name.."' saved.")
    end)
    NVRaw:AddButton("Delete Selected",function()
        if NV_BUILTIN_CFG[nvMode] then Library:Notify("Cannot delete a built-in preset.");return end
        if not userPresets[nvMode] then Library:Notify("No custom preset selected.");return end
        local deleted=nvMode
        userPresets[nvMode]=nil
        savePresetsFile()
        nvMode="Night Vision"
        Options["nv_mode"]:SetValues(getDropdownList())
        Options["nv_mode"]:SetValue("Night Vision")
        applyNV()
        Library:Notify("Preset '"..deleted.."' deleted.")
    end)
    local prevDestroyNV=Combat.Destroy
    Combat.Destroy=function()
        if nvEffect then nvEffect:Destroy();nvEffect=nil end
        prevDestroyNV()
    end
end

addSubtabs('Visuals', visualPages)
-- Visuals 3D Preview: Players, NPCs and Zombies.
do
-- Installs an isolated, category-aware preview into an existing Linoria menu.
local installPreview=function(Context)
    local Library, Window, Sense = Context.Library, Context.Window, Context.Sense
    local Player, Input, RunService = Context.Player, Context.Input, Context.RunService
    local pages = Context.Pages
    local labels = {players="Players", npc="NPCs", zombies="Zombies"}
    local bodyNames = {Head=true,UpperTorso=true,LowerTorso=true,Torso=true,
        LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,
        LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true,
        ["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true}
    local Preview:any = {enabled={players=true,npc=true,zombies=true}, sources={}, views={}, chams={},
        nextFrame=0,nextSourceCheck=0,dragging=false,connections={},destroyed=false,random=Random.new()}

    local function connect(signal, callback)
        local connection=signal:Connect(callback)
        Preview.connections[#Preview.connections+1]=connection
        return connection
    end
    local function validModel(model)
        return typeof(model)=="Instance" and model:IsA("Model") and model.Parent~=nil
    end
    local function visiblePage()
        if Preview.destroyed or Library.Unloaded or not Window.Holder.Visible then return nil end
        for kind,page in pairs(pages) do
            if page.Active and Preview.enabled[kind] then
                local parent=page.Button and page.Button.Parent
                local visible=parent~=nil
                while parent and parent~=Window.Holder do
                    if parent:IsA("GuiObject") and not parent.Visible then visible=false;break end
                    parent=parent.Parent
                end
                if visible then return kind end
            end
        end
        return nil
    end
    function Preview.Resolve(kind, force)
        local service=Sense.Service()
        local replicator=service and service.Replicator
        local previous=Preview.sources[kind]
        if kind=="players" then
            local actor=replicator and replicator.LocalActor
            local model=actor and actor.Character
            if not validModel(model) then model=Player.Character;actor=nil end
            return validModel(model) and {model=model,actor=actor,label=Player.DisplayName,
                detail="Your character",revision=#model:GetChildren()} or nil
        end
        local function eligible(actor)
            if type(actor)~="table" or actor.Owner~=nil or actor.IsLocalPlayer then return false end
            if (not not actor.Zombie)~=(kind=="zombies") then return false end
            return validModel(actor.Character) and Context.IsAlive(actor)
        end
        local registry=replicator and replicator.Actors or {}
        if not force and previous and eligible(previous.actor) and previous.actor.Character==previous.model
            and previous.actor.UID and registry[previous.actor.UID]==previous.actor then return previous end
        local candidates={}
        for _,actor in pairs(registry) do
            if eligible(actor) and (not force or not previous or actor.Character~=previous.model) then
                candidates[#candidates+1]=actor
            end
        end
        if #candidates>0 then
            local actor=candidates[Preview.random:NextInteger(1,#candidates)]
            local name=actor.DisplayName or (actor.OwnerName~="???" and actor.OwnerName) or actor.Character.Name
            return {model=actor.Character,actor=actor,label=kind=="zombies" and "Zombie" or tostring(name),
                detail=kind=="zombies" and "Live zombie · snapshot" or "Random NPC · snapshot"}
        end
        if previous and eligible(previous.actor) then return previous end
        if kind=="zombies" then
            local root=game:GetService("ReplicatedStorage")
            for _,name in ipairs({"Assets","Models","Character","Zombie"}) do
                root=root and root:FindFirstChild(name)
            end
            if validModel(root) then return {model=root,label="Zombie",detail="Game zombie model"} end
        end
        return nil
    end
    function Preview.ClearModel()
        if Preview.object then Sense.DestroyPreviewObject(Preview.object);Preview.object=nil end
        if Preview.world then Preview.world:ClearAllChildren() end
        Preview.model=nil;Preview.actor=nil;Preview.source=nil
        table.clear(Preview.chams)
    end
    local function cloneModel(source)
        local changed={}
        local ok,result=pcall(function()
            local objects=source:GetDescendants();objects[#objects+1]=source
            for _,object in ipairs(objects) do
                if not object.Archivable then changed[#changed+1]=object;object.Archivable=true end
            end
            return source:Clone()
        end)
        for _,object in ipairs(changed) do pcall(function() object.Archivable=false end) end
        if ok then return result end
        return nil
    end
    function Preview.Drawing(class)
        local properties:any={Visible=false,Transparency=1,Color=Color3.new(1,1,1)}
        local object:any={}
        local frame:any=Instance.new(class=="Text" and "TextLabel" or "Frame")
        frame.Name=class;frame.BorderSizePixel=0;frame.Active=false;frame.Visible=false
        frame.ZIndex=14;frame.Parent=Preview.overlay
        local border
        if class=="Text" then
            frame.BackgroundTransparency=1;frame.RichText=false
            frame.TextXAlignment=Enum.TextXAlignment.Center;frame.TextYAlignment=Enum.TextYAlignment.Top
        elseif class=="Square" then
            border=Instance.new("UIStroke");border.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;border.Parent=frame
        end
        function object:Remove() frame:Destroy() end
        function object:Flush()
            frame.Visible=properties.Visible==true
            if not frame.Visible then return end
            frame.ZIndex=14+(properties.ZIndex or 0)
            local opacity=math.clamp(properties.Transparency or 1,0,1)
            local color=properties.Color
            if class=="Text" then
                frame.FontFace=Sense.sharedSettings.textFace or Font.fromEnum(
                    ({Library.Font,Enum.Font.Arial,Enum.Font.Gotham,Enum.Font.Code})[(properties.Font or 2)+1] or Library.Font)
                frame.Text=tostring(properties.Text or "");frame.TextSize=properties.Size or 13
                frame.TextColor3=color;frame.TextTransparency=1-opacity
                frame.TextStrokeColor3=properties.OutlineColor or Color3.new(0,0,0)
                frame.TextStrokeTransparency=properties.Outline and 1-opacity or 1
                frame.AnchorPoint=Vector2.new(properties.Center and .5 or 0,0)
                frame.Size=UDim2.fromOffset(500,(properties.Size or 13)*2)
                frame.Position=UDim2.fromOffset(properties.Position.X,properties.Position.Y)
            elseif class=="Line" then
                local delta=properties.To-properties.From;local midpoint=(properties.From+properties.To)*.5
                frame.AnchorPoint=Vector2.new(.5,.5);frame.Position=UDim2.fromOffset(midpoint.X,midpoint.Y)
                frame.Size=UDim2.fromOffset(delta.Magnitude,properties.Thickness or 1)
                frame.Rotation=math.deg(math.atan2(delta.Y,delta.X))
                frame.BackgroundColor3=color;frame.BackgroundTransparency=1-opacity
            elseif class=="Square" then
                frame.Position=UDim2.fromOffset(properties.Position.X,properties.Position.Y)
                frame.Size=UDim2.fromOffset(properties.Size.X,properties.Size.Y)
                frame.BackgroundColor3=color;frame.BackgroundTransparency=properties.Filled and 1-opacity or 1
                border.Enabled=not properties.Filled;border.Color=color;border.Transparency=1-opacity
                border.Thickness=properties.Thickness or 1
            else frame.Visible=false end
        end
        return setmetatable(object,{__index=function(_,key) return properties[key] end,
            __newindex=function(_,key,value) properties[key]=value end})
    end
    function Preview.BuildModel(kind, source)
        Preview.ClearModel()
        if not source then return false end
        local model=cloneModel(source.model)
        if not model then return false end
        -- Sanitize before parenting: the copied appearance is entirely inert.
        for _,object in ipairs(model:GetDescendants()) do
            if object:IsA("LuaSourceContainer") or object:IsA("Sound") or object:IsA("LayerCollector")
                or object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail")
                or object:IsA("Highlight") or object:IsA("ForceField") or object:IsA("Animator")
                or object:IsA("Light") or object:IsA("ProximityPrompt") then object:Destroy()
            elseif object:IsA("BasePart") then
                object.Anchored=true;object.CanCollide=false;object.CanTouch=false;object.CanQuery=false
                object.CastShadow=false;object.LocalTransparencyModifier=0
                object.AssemblyLinearVelocity=Vector3.zero;object.AssemblyAngularVelocity=Vector3.zero
            end
        end
        local rootName=source.actor and source.actor.RootPart and source.actor.RootPart.Name
        local root=(rootName and model:FindFirstChild(rootName,true)) or model:FindFirstChild("Root")
            or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("UpperTorso")
        if not root or not root:IsA("BasePart") then model:Destroy();return false end
        local body,joints={},{}
        for _,part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and bodyNames[part.Name] and part.Parent==model then body[part.Name]=part end
            if part:IsA("Motor6D") or part:IsA("Weld") then joints[#joints+1]=part end
        end
        -- Put the root at the origin, then resolve the stored neutral pose and equipment welds.
        local transform=root.CFrame:Inverse()
        for _,part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then part.CFrame=transform*part.CFrame end
        end
        local placed={[root]=true}
        for _=1,24 do
            local changed=false
            for _,joint in ipairs(joints) do
                local a,b=joint.Part0,joint.Part1
                if a and b and a:IsDescendantOf(model) and b:IsDescendantOf(model) then
                    if placed[a] and not placed[b] then
                        b.CFrame=a.CFrame*joint.C0*joint.C1:Inverse();placed[b]=true;changed=true
                    elseif placed[b] and not placed[a] then
                        a.CFrame=b.CFrame*joint.C1*joint.C0:Inverse();placed[a]=true;changed=true
                    end
                end
            end
            if not changed then break end
        end
        local humanoid=model:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
        if root.Name=="Root" or root.Name=="HumanoidRootPart" then root.Transparency=1 end
        model.PrimaryPart=root;model.Name=source.label;model.Parent=Preview.world
        local sourceActor=source.actor
        local maxHealth=sourceActor and type(sourceActor.MaxHealth)=="number" and sourceActor.MaxHealth or 100
        local health=sourceActor and type(sourceActor.Health)=="number" and sourceActor.Health or maxHealth*.75
        local actor={Character=model,RootPart=root,Position=root.Position,Kind=kind,Health=health,MaxHealth=maxHealth,
            Owner=kind=="players" and {Name=Player.Name,DisplayName=Player.DisplayName,Neutral=Player.Neutral} or nil,
            DisplayName=source.label,OwnerName=source.label,UID=sourceActor and sourceActor.UID or "preview",
            Parts=body,Zombie=kind=="zombies",PreviewWeapon=sourceActor and Sense.Weapon(sourceActor) or "Unarmed",
            PreviewTeamColor=sourceActor and Sense.TeamColor(sourceActor) or Sense.sharedSettings.neutralColor}
        Preview.model=model;Preview.actor=actor;Preview.source=source
        Preview.object=Sense.CreatePreviewObject(actor,Preview.Drawing)
        -- Capture joint offsets before removing inert clone constraints. The
        -- preview and live skeleton now use exactly the same topology builder.
        for _,joint in ipairs(joints) do joint:Destroy() end
        for _,object in ipairs(model:GetDescendants()) do
            if object:IsA("Constraint") or object:IsA("BodyMover") then object:Destroy() end
        end
        for _,part in pairs(body) do
            if part~=root and part.Transparency<1 then
                local overlay=part:Clone()
                for _,child in ipairs(overlay:GetChildren()) do
                    if child:IsA("SpecialMesh") then child.TextureId="" else child:Destroy() end
                end
                if overlay:IsA("MeshPart") then overlay.TextureID="" end
                overlay.Name="PreviewChams";overlay.Size=part.Size+Vector3.one*.012
                overlay.Material=Enum.Material.SmoothPlastic;overlay.Transparency=1;overlay.Parent=Preview.world
                Preview.chams[#Preview.chams+1]=overlay
            end
        end
        local bounds,size=model:GetBoundingBox()
        Preview.focus=bounds.Position;Preview.radius=math.max(size.Magnitude*.5,1)
        Preview.LastError=nil
        return true
    end
    local function label(parent,text,position,size,textSize)
        local object=Library:Create("TextLabel",{BackgroundTransparency=1,Text=text,Font=Library.Font,
            TextSize=textSize,TextColor3=Library.FontColor,TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd,Position=position,Size=size,ZIndex=12,Parent=parent})
        Library:AddToRegistry(object,{TextColor3="FontColor"})
        return object
    end
    local function button(parent,text,position,size,callback)
        local object=Library:Create("TextButton",{Text=text,Font=Library.Font,TextSize=12,
            TextColor3=Library.FontColor,BackgroundColor3=Library.MainColor,BorderSizePixel=0,
            Position=position,Size=size,ZIndex=15,Parent=parent})
        Library:AddToRegistry(object,{TextColor3="FontColor",BackgroundColor3="MainColor"})
        Library:Create("UICorner",{CornerRadius=UDim.new(0,3),Parent=object})
        connect(object.MouseButton1Click,callback)
        return object
    end
    function Preview.EnsureGui()
        if Preview.panel then return end
        local panel=Library:Create("Frame",{Name="Visuals3DPreview",BorderSizePixel=0,
            BackgroundColor3=Library.BackgroundColor,Size=UDim2.fromOffset(264,430),Visible=false,
            ClipsDescendants=true,ZIndex=10,Parent=Window.Holder})
        Library:AddToRegistry(panel,{BackgroundColor3="BackgroundColor"})
        local border=Library:Create("UIStroke",{Color=Library.OutlineColor,Thickness=1,Parent=panel})
        Library:AddToRegistry(border,{Color="OutlineColor"})
        local accent=Library:Create("Frame",{BorderSizePixel=0,BackgroundColor3=Library.AccentColor,
            Size=UDim2.new(1,0,0,2),ZIndex=11,Parent=panel})
        Library:AddToRegistry(accent,{BackgroundColor3="AccentColor"})
        Preview.title=label(panel,"Visuals 3D Preview",UDim2.fromOffset(12,8),UDim2.new(1,-24,0,20),14)
        Preview.subtitle=label(panel,"",UDim2.fromOffset(12,31),UDim2.new(1,-24,0,17),12)
        Preview.subtitle.TextTransparency=.25
        local viewport=Instance.new("ViewportFrame")
        viewport.Name="Model";viewport.BackgroundTransparency=1;viewport.BorderSizePixel=0
        viewport.Position=UDim2.fromOffset(8,55);viewport.Size=UDim2.new(1,-16,1,-127)
        viewport.Ambient=Color3.fromRGB(165,169,180);viewport.LightColor=Color3.fromRGB(245,237,221)
        viewport.LightDirection=Vector3.new(-1,-.7,-1);viewport.ZIndex=11;viewport.Active=true;viewport.Parent=panel
        local world=Instance.new("WorldModel");world.Parent=viewport
        local camera=Instance.new("Camera");camera.FieldOfView=30;camera.Parent=viewport;viewport.CurrentCamera=camera
        local overlay=Instance.new("Frame");overlay.Name="Overlay";overlay.BackgroundTransparency=1
        overlay.Size=UDim2.fromScale(1,1);overlay.ClipsDescendants=true;overlay.ZIndex=12;overlay.Parent=viewport
        Preview.empty=label(panel,"Waiting for a model…",UDim2.new(0,18,.5,-24),UDim2.new(1,-36,0,48),13)
        Preview.empty.TextWrapped=true;Preview.empty.TextXAlignment=Enum.TextXAlignment.Center
        Preview.status=label(panel,"",UDim2.new(0,12,1,-68),UDim2.new(1,-24,0,17),11)
        Preview.hint=label(panel,"Drag to rotate · Scroll to zoom",UDim2.new(0,12,1,-49),UDim2.new(1,-24,0,15),11)
        Preview.hint.TextTransparency=.35
        Preview.panel=panel;Preview.viewport=viewport;Preview.world=world;Preview.camera=camera;Preview.overlay=overlay
        Preview.reset=button(panel,"Reset view",UDim2.new(0,12,1,-29),UDim2.new(.5,-18,0,22),function()
            if Preview.kind then Preview.views[Preview.kind]={yaw=.3,pitch=.02,zoom=1} end
        end)
        Preview.shuffle=button(panel,"Another NPC",UDim2.new(.5,6,1,-29),UDim2.new(.5,-18,0,22),function()
            if Preview.kind then Preview.Refresh(Preview.kind,true) end
        end)
        connect(viewport.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 and Preview.panel.Visible then
                Preview.dragging=true;Preview.lastMouse=Input:GetMouseLocation()
            end
        end)
        connect(viewport.InputChanged,function(input)
            if input.UserInputType==Enum.UserInputType.MouseWheel and Preview.kind then
                local view=Preview.views[Preview.kind]
                view.zoom=math.clamp(view.zoom-input.Position.Z*.1,.65,1.8)
            end
        end)
        connect(Input.InputEnded,function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then Preview.dragging=false end
        end)
        connect(Input.WindowFocusReleased,function() Preview.dragging=false end)
    end
    function Preview.Refresh(kind,force)
        local source=Preview.Resolve(kind,force)
        local old=Preview.source
        Preview.sources[kind]=source
        if force or not Preview.object or not source or not old or old.model~=source.model or old.revision~=source.revision then
            local ok=Preview.BuildModel(kind,source)
            Preview.empty.Visible=not ok
            Preview.empty.Text=source and "Model could not be copied. Retrying…" or
                (kind=="players" and "Waiting for your character…" or "No "..labels[kind].." model available. Retrying…")
        end
        Preview.subtitle.Text=source and (labels[kind].." · "..source.label) or labels[kind]
        Preview.shuffle.Visible=kind~="players"
        Preview.shuffle.Text=kind=="npc" and "Another NPC" or
            (source and source.actor and "Another zombie" or "Refresh model")
        Preview.nextSourceCheck=os.clock()+2
    end
    function Preview.Layout()
        local camera=workspace.CurrentCamera
        if not camera then return end
        local screen=camera.ViewportSize
        local pos,size=Window.Holder.AbsolutePosition,Window.Holder.AbsoluteSize
        local width=math.min(264,math.max(120,screen.X-16))
        local height=math.min(430,math.max(220,screen.Y-16),math.max(220,size.Y))
        local x=pos.X+size.X+12
        if x+width>screen.X-8 then x=pos.X-width-12 end
        x=math.clamp(x,8,math.max(8,screen.X-width-8))
        local y=math.clamp(pos.Y,8,math.max(8,screen.Y-height-8))
        Preview.panel.Size=UDim2.fromOffset(width,height)
        Preview.panel.Position=UDim2.fromOffset(x-pos.X,y-pos.Y)
    end
    function Preview.Step(now)
        local kind=visiblePage()
        if not kind then
            if Preview.panel then Preview.panel.Visible=false end
            Preview.dragging=false
            return
        end
        Preview.EnsureGui()
        local switched=Preview.kind~=kind
        if not switched and now<Preview.nextFrame then return end
        Preview.nextFrame=now+1/30
        Preview.panel.Visible=true;Preview.Layout()
        if switched then
            Preview.kind=kind;Preview.dragging=false
            Preview.views[kind]=Preview.views[kind] or {yaw=.3,pitch=.02,zoom=1}
            Preview.ClearModel();Preview.Refresh(kind,false)
        elseif now>=Preview.nextSourceCheck then Preview.Refresh(kind,false) end
        if not Preview.object then return end
        local viewState=Preview.views[kind]
        if Preview.dragging then
            local mouse=Input:GetMouseLocation();local delta=mouse-Preview.lastMouse;Preview.lastMouse=mouse
            viewState.yaw-=delta.X*.009;viewState.pitch=math.clamp(viewState.pitch+delta.Y*.006,-.65,.65)
        end
        local view=Preview.viewport.AbsoluteSize
        if view.X<1 or view.Y<1 then return end
        local tangent=math.tan(math.rad(Preview.camera.FieldOfView*.5))
        local limitingHalfFov=math.atan(tangent*math.min(1,view.X/view.Y))
        local distance=Preview.radius/math.sin(limitingHalfFov)*1.12*viewState.zoom
        local yaw,pitch=viewState.yaw,viewState.pitch
        local offset=Vector3.new(math.sin(yaw)*math.cos(pitch),math.sin(pitch),-math.cos(yaw)*math.cos(pitch))*distance
        Preview.camera.CFrame=CFrame.lookAt(Preview.focus+offset,Preview.focus)
        local camera:any={CFrame=Preview.camera.CFrame,ViewportSize=view}
        function camera:WorldToViewportPoint(point)
            local relative=self.CFrame:PointToObjectSpace(point);local depth=-relative.Z
            local focal=view.Y/(2*tangent)
            local x=view.X*.5+relative.X*focal/math.max(.001,depth)
            local y=view.Y*.5-relative.Y*focal/math.max(.001,depth)
            return Vector3.new(x,y,depth),depth>0 and x>=0 and x<=view.X and y>=0 and y<=view.Y
        end
        local settings=Sense.teamSettings[kind]
        local sampleDistance=math.min(40,settings.maxDistance or 40)
        local origin=Preview.actor.Position-Vector3.new(0,0,sampleDistance)
        Sense.RenderActor(Preview.object,camera,origin)
        for _,drawing in pairs(Preview.object.drawings) do drawing:Flush() end
        local chams=Sense.chams[kind]
        for _,part in ipairs(Preview.chams) do
            part.Color=Sense.sharedSettings.teamBasedColor and Preview.actor.PreviewTeamColor or chams.visibleColor
            part.Transparency=settings.enabled and chams.enabled and 1-chams.visibleIntensity or 1
        end
        Preview.status.Text=(Preview.source and Preview.source.detail or "")..(settings.enabled and "" or " · ESP off")
    end
    function Preview.Destroy()
        if Preview.destroyed then return end
        Preview.destroyed=true
        for _,connection in ipairs(Preview.connections) do connection:Disconnect() end
        table.clear(Preview.connections)
        Preview.ClearModel()
        if Preview.panel then Preview.panel:Destroy();Preview.panel=nil end
        table.clear(Preview.sources);table.clear(Preview.views)
    end
    for kind,page in pairs(pages) do
        local toggle=page.Groups[1]:AddToggle(kind.."_visuals_3d_preview",{Text="Visuals 3D Preview",Default=true})
        toggle:OnChanged(function(value) Preview.enabled[kind]=value end)
    end
    connect(RunService.RenderStepped,function()
        if Preview.destroyed then return end
        local ok,err=pcall(Preview.Step,os.clock())
        if not ok then
            if Preview.panel then Preview.panel.Visible=false end
            if Preview.LastError~=tostring(err) then Preview.LastError=tostring(err);warn("[Visuals 3D Preview]",err) end
        end
    end)
    return Preview
end

local preview=installPreview({Library=Library,Window=Window,Sense=Sense,Player=AimLocalPlayer,
    Input=AimUIS,RunService=AimRunService,IsAlive=Combat.IsAlive,
    Pages={players=PlayersPage,npc=NpcPage,zombies=ZombiePage}})
Combat.Preview=preview
local destroyWithPreview=Combat.Destroy
Combat.Destroy=function() preview.Destroy();destroyWithPreview() end
end

end

do
local function legacyPage(tab, pages, name)
    local page = { Name = name, Groups = {} }
    table.insert(pages, page)
    function page:AddSection(info)
        local group = info.Side == 'Right' and tab:AddRightGroupbox(info.Title)
            or tab:AddLeftGroupbox(info.Title)
        table.insert(self.Groups, group)
        local section = {}
        local lastToggle
        function section:AddToggle(data)
            local control = group:AddToggle(data.Flag, { Text = data.Text, Default = data.Default })
            control:OnChanged(data.Callback)
            lastToggle = control
            return control
        end
        function section:AddSlider(data)
            local step = data.Rounding or 1
            local decimals = step < 1 and math.ceil(-math.log10(step)) or 0
            local control = group:AddSlider(data.Flag, {
                Text = data.Text, Default = data.Default, Min = data.Min, Max = data.Max,
                Rounding = decimals, Suffix = data.Suffix or '',
            })
            control:OnChanged(function(value)
                local rounded = math.clamp(math.floor(value / step + 0.5) * step, data.Min, data.Max)
                rounded = tonumber(string.format('%.' .. decimals .. 'f', rounded))
                if math.abs(value - rounded) > 1e-7 then control:SetValue(rounded); return end
                data.Callback(rounded)
            end)
            return control
        end
        function section:AddDropdown(data)
            local control = group:AddDropdown(data.Flag, {
                Text = data.Text, Values = data.Options, Default = data.Default, Multi = data.Multi or false,
            })
            control:OnChanged(data.Callback)
            return control
        end
        function section:AddColorPicker(data)
            assert(lastToggle, 'A mod color picker must belong to a toggle')
            lastToggle:AddColorPicker(data.Flag, {
                Default = data.Default, Title = data.Text,
                Transparency = data.Transparency ~= nil and 1 - data.Transparency or nil,
            })
            local picker = Options[data.Flag]
            picker:OnChanged(function(color)
                data.Callback(color, data.Transparency ~= nil and 1 - picker.Transparency or nil)
            end)
            return picker
        end
        function section:AddKeyPicker(data)
            assert(lastToggle, 'A mod keybind must belong to a toggle')
            local key = data.Default
            if typeof(key) == 'EnumItem' then
                key = key.Name == 'MouseButton1' and 'MB1' or key.Name == 'MouseButton2' and 'MB2' or key.Name
            end
            lastToggle:AddKeyPicker(data.Flag, {
                Text = data.Text, Default = key, Mode = data.Mode or 'Hold',
                Modes = { 'Always', 'Hold', 'Toggle' }, SyncToggleState = false,
                Callback = data.Callback,
            })
            return Options[data.Flag]
        end
        function section:AddButton(data)
            return group:AddButton(data.Text or data.Name or "Button", data.Callback or function() end)
        end
        return section
    end
    return page
end

local movementPages, modPages = {}, {}
do
    local MovementPage = legacyPage(Tabs.Movement, movementPages, "Movement")
    local FlightPage = legacyPage(Tabs.Movement, movementPages, "Flight")
    local M={active=true,hooks={},Speed=false,SpeedValue=24,Smoothing=false,Stamina=false,
        AutoSprint=false,AirStrafe=false,AirStrafeSpeed=24,BunnyHop=false,NoJumpDelay=true,
        AutoHeal=false,HealThreshold=75,HealItems={Vitamins=true,Bandage=true,Dressing=true},HealAvoid={},nextHeal=0,nextHealCheck=0,
        Penalties=false,Survival=false,NoFallDamage=false,Fly=false,FlySpeed=40,Modifier=false,Multiplier=2,Noclip=false,
        speedState={},flyState={},modifierState={}}
    Combat.Movement=M
    local left=MovementPage:AddSection({Title="Movement",Side="Left"})
    local right=MovementPage:AddSection({Title="Misc",Side="Right"})
    local flight=FlightPage:AddSection({Title="Fly",Side="Left"})
    local modifier=FlightPage:AddSection({Title="Modifier",Side="Right"})
    local function toggle(section,text,key)
        return section:AddToggle({Text=text,Flag="movement_"..key,Default=false,
            Callback=function(v) M[key]=v end})
    end
    toggle(left,"Speed", "Speed")
    left:AddSlider({Text="Speed",Flag="movement_speed_value",Min=1,Max=150,Default=24,Rounding=1,Suffix=" studs/s",
        Callback=function(v) M.SpeedValue=v end})
    M.speedKey=left:AddKeyPicker({Text="Speed Key",Flag="movement_speed_key",Default=Enum.KeyCode.G,Mode="Toggle",Callback=function() end})
    toggle(left,"No Movement Smoothing","Smoothing")
    toggle(left,"Auto Sprint","AutoSprint")
    toggle(left,"Air Strafe","AirStrafe")
    left:AddSlider({Text="Air Strafe Speed",Flag="movement_air_strafe_speed",Min=1,Max=150,Default=24,Rounding=1,Suffix=" studs/s",
        Callback=function(v) M.AirStrafeSpeed=v end})
    toggle(left,"Bunny Hop","BunnyHop")
    M.bunnyKey=left:AddKeyPicker({Text="Bunny Hop",Flag="movement_bunny_key",Default="None",Mode="Hold",Callback=function() end})
    left:AddToggle({Text="No Jump Delay",Flag="movement_NoJumpDelay",Default=true,
        Callback=function(v) M.NoJumpDelay=v end})

    toggle(left,"Omni Sprint","OmniSprint")
    toggle(left,"Aim / Shoot While Sprinting","SprintCombat")
    toggle(right,"Infinite Stamina","Stamina")
    toggle(right,"No Speed Penalties","Penalties")
    toggle(right,"No Fall Damage","NoFallDamage")
    toggle(right,"Auto Heal","AutoHeal")
    right:AddDropdown({Text="Avoid",Flag="movement_heal_avoid",Options={"While Aiming","While Running","While Shooting"},
        Default={},Multi=true,Callback=function(v) M.HealAvoid=v end})
    right:AddDropdown({Text="Healing Items",Flag="movement_heal_items",Options={"Vitamins","Bandage","Dressing"},
        Default={"Vitamins","Bandage","Dressing"},Multi=true,Callback=function(v) M.HealItems=v end})
    right:AddSlider({Text="Heal Below",Flag="movement_heal_threshold",Min=1,Max=100,Default=75,Rounding=1,Suffix="%",
        Callback=function(v) M.HealThreshold=v end})
    toggle(flight,"Fly","Fly")
    flight:AddSlider({Text="Fly Speed",Flag="movement_fly_speed",Min=1,Max=150,Default=40,Rounding=1,Suffix=" studs/s",
        Callback=function(v) M.FlySpeed=v end})
    M.flyKey=flight:AddKeyPicker({Text="Fly Key",Flag="movement_fly_key",Default=Enum.KeyCode.H,Mode="Toggle",Callback=function() end})
    toggle(flight,"Fly Noclip","Noclip")
    toggle(modifier,"Fly Modifier","Modifier")
    modifier:AddSlider({Text="Speed Multiplier",Flag="movement_fly_multiplier",Min=1,Max=5,Default=2,Rounding=.1,Suffix="x",
        Callback=function(v) M.Multiplier=v end})
    M.modifierKey=modifier:AddKeyPicker({Text="Modifier Key",Flag="movement_modifier_key",Default=Enum.KeyCode.LeftShift,Mode="Hold",Callback=function() end})
    function M.IsLocal(ctrl)
        local service=Combat.Service()
        return M.active and service and service.Replicator and ctrl._localActor==service.Replicator.LocalActor
    end
    function M.CanMove(ctrl)
        local a=ctrl._localActor
        return a and not (a.Downed or a.Frozen or a.Forced or a.Rappelling or a.Ladder or ctrl.Goal or ctrl._forceCFrame or ctrl._startPhysics
            or (a.CurrentState and (a.CurrentState.Dragged or a.CurrentState.Emote)))
    end
    function M.Wrap(class,key,handler)
        local original=class[key]
        assert(type(original)=="function","Missing CharacterController."..key)
        local wrapper=function(ctrl,...)
            if M.IsLocal(ctrl) then return handler(original,ctrl,...) end
            return original(ctrl,...)
        end
        class[key]=wrapper
        table.insert(M.hooks,{class=class,key=key,original=original,wrapper=wrapper})
    end
    function M.ResolveActions()
        for _,module in ipairs(getloadedmodules()) do
            if module.Name=="InputService" and not M.inputService then
                local ok,value=pcall(require,module)
                if ok and type(value)=="table" then M.inputService=value end
            elseif module.Name=="ActionInterface" and not M.medicalInterface then
                local ok,value=pcall(require,module)
                if ok and type(value)=="table" and type(value._medical)=="function" and type(value._getMedical)=="function" then
                    -- Build the game's self-treatment callbacks without changing the radial menu.
                    local context={_getMedical=function() return 0,0,0 end}
                    local actions
                    context._setOptions=function(_,options)
                        actions={Bandage=options[1][5],Vitamins=options[2][5],Dressing=options[3][5]}
                    end
                    local built=pcall(value._medical,context)
                    if built and actions then M.medicalInterface=value;M.healActions=actions end
                end
            end
            if M.inputService and M.medicalInterface then break end
        end
    end
    function M.InputBlocked()
        local input=M.inputService
        return Window.Holder.Visible or Library:IsTyping()
            or not input or input.PauseOpen or input.InventoryOpen or input.RadialOpen
    end
    function M.ShouldAvoidHeal(actor)
        local avoid=M.HealAvoid
        if not next(avoid) then return false end
        local weapon=Combat.Weapon()
        if avoid["While Aiming"] and (actor.ADS or (weapon and weapon.ADS)) then return true end
        local controller=M.currentController
        if avoid["While Running"] and (actor.Sprinting or (controller and controller._localActor==actor and controller.IsSprinting)) then return true end
        if avoid["While Shooting"] and weapon and weapon._firearm
            and (weapon._shooting or (type(weapon._next)=="number" and os.clock()<weapon._next)) then return true end
        return false
    end
    function M.StepAutoHeal(now)
        if not M.AutoHeal or now<M.nextHealCheck then return end
        M.nextHealCheck=now+.25
        if now<M.nextHeal or not M.medicalInterface or M.InputBlocked() then return end
        local service=Combat.Service()
        local actor=service and service.Replicator and service.Replicator.LocalActor
        if not actor or actor.Alive==false or actor.Downed or actor.Frozen or actor.Forced then return end
        if M.ShouldAvoidHeal(actor) then return end
        local health=actor.Health
        local maximum=type(actor.MaxHealth)=="number" and actor.MaxHealth>0 and actor.MaxHealth or 100
        if type(health)~="number" or health~=health or health<=0 or health>=maximum*M.HealThreshold/100 then return end
        if type(actor.MedicalEnd)=="number" and now<actor.MedicalEnd then return end
        local ok,bandages,dressings,vitamins=pcall(M.medicalInterface._getMedical,M.medicalInterface)
        if not ok then M.healError=tostring(bandages);M.nextHeal=now+2;return end
        local item
        local selected=M.HealItems
        local hasBandage=selected.Bandage and bandages>0
        if selected.Vitamins and vitamins>0 and (maximum-health>=25 or not hasBandage) then item="Vitamins"
        elseif hasBandage then item="Bandage"
        elseif selected.Dressing and dressings>0 then item="Dressing" end
        if not item then return end
        -- Vitamins keep healing over time. Wait before considering another consumable.
        M.nextHeal=now+(item=="Vitamins" and 8 or 3)
        local used,err=pcall(M.healActions[item])
        if not used then M.healError=tostring(err) end
    end
    function M.ResetBunny()
        M.bunnyController=nil;M.bunnyWaitingForAir=false;M.bunnyNextAttempt=0
    end
    function M.StepBunny(ctrl,now)
        local actor=ctrl._localActor
        if not M.bunnyActive or M.flyActive or not M.CanMove(ctrl) or not actor.Alive
            or ctrl.IsSwimming or ctrl.IsSliding or ctrl._emoting
            or (actor.CurrentState and actor.CurrentState.Dragging) then M.ResetBunny();return end
        if M.bunnyController~=ctrl then M.ResetBunny();M.bunnyController=ctrl end
        if not ctrl.IsGrounded then
            M.bunnyWaitingForAir=false
            return
        end
        if not M.heightStates or ctrl.HeightState~=M.heightStates.Standing then M.ResetBunny();return end
        if not M.NoJumpDelay and now<(M.bunnyNextAttempt or 0) then return end
        if M.bunnyWaitingForAir and ctrl.VelocityGravity>0 then return end
        local jump=M.inputService and M.inputService._mounts and M.inputService._mounts.Jump
        if type(jump)~="function" and M.inputService and M.inputService._mounts then
            for k,v in pairs(M.inputService._mounts) do
                if type(v)=="function" and tostring(k):lower():find("jump") then jump=v;break end
            end
        end
        if type(jump)~="function" then
            jump=M.inputService and type(M.inputService.Jump)=="function" and M.inputService.Jump or nil
        end
        if type(jump)~="function" then return end
        local previousUp=ctrl._up
        -- Scope the cooldown override to this Bunny Hop request only.
        M.bunnyJumpingController=ctrl
        local ok,err=pcall(jump,true,false,false)
        M.bunnyJumpingController=nil
        ctrl._up=previousUp
        M.bunnyNextAttempt=M.NoJumpDelay and now or now+.2
        M.bunnyWaitingForAir=ok and ctrl.VelocityGravity>0
        if not ok then M.bunnyError=tostring(err) end
    end
    function M.RestoreAirSpeed()
        local ctrl=M.airController
        if ctrl and ctrl.MoveSpeed==M.airAppliedSpeed then ctrl.MoveSpeed=M.airOriginalSpeed end
        M.airController=nil;M.airOriginalSpeed=nil;M.airAppliedSpeed=nil
    end
    function M.AirDirection(ctrl,input,nativeDirection)
        local states=M.heightStates
        if not M.AirStrafe or not M.airInputAllowed or M.flyActive or not M.CanMove(ctrl)
            or not ctrl._localActor.Alive or ctrl.IsGrounded or ctrl.IsSwimming or ctrl.IsSliding or ctrl._emoting
            or not states or (ctrl.HeightState~=states.Standing and ctrl.HeightState~=states.Falling)
            or input.Magnitude<.01 then return nativeDirection end
        local camera=workspace.CurrentCamera
        if not camera then return nativeDirection end
        local look=camera.CFrame.LookVector
        local yaw=math.atan2(-look.X,-look.Z)
        local direction=CFrame.Angles(0,yaw,0):VectorToWorldSpace(Vector3.new(input.X,0,input.Y).Unit)
        -- The native controller still handles vertical motion and collision resolution.
        ctrl._groundedInputDirection=input
        M.airController=ctrl;M.airOriginalSpeed=ctrl.MoveSpeed
        M.airAppliedSpeed=M.AirStrafeSpeed*math.min(input.Magnitude,1)
        ctrl.MoveSpeed=M.airAppliedSpeed
        return direction
    end
    function M.Install(class)
        local standing
        -- shared.import belongs to the game's module environment, not the executor.
        local inspect=(debug and debug.getupvalues) or getupvalues
        if inspect then
            for _,fn in ipairs({class.new,class.Update}) do
                local ok,values=pcall(inspect,fn)
                if ok then
                    for _,value in pairs(values) do
                        if type(value)=="table" and type(value.CharacterHeightState)=="table" then
                            M.heightStates=value.CharacterHeightState
                            standing=value.CharacterHeightState.Standing
                            break
                        end
                    end
                end
                if standing~=nil then break end
            end
        end
        if standing==nil then warn("[Movements] Sprint options unavailable: controller enum could not be resolved") end
        for _,key in ipairs({"_accelerate","_decelerate","_exhaust","Update","_processNewPosition","_processMovementInput"}) do
            assert(type(class[key])=="function","Missing CharacterController."..key)
        end
        M.Wrap(class,"_processMovementInput",function(original,ctrl,input,dt)
            M.RestoreAirSpeed()
            local actor=ctrl._localActor
            if standing~=nil and (M.OmniSprint or M.SprintCombat) and M.CanMove(ctrl) and ctrl.TrySprinting
                and ctrl.HeightState==standing and not ctrl.IsSliding and not ctrl.IsSwimming
                and not actor.CurrentState.Dragging and input.Magnitude>.01 then
                local directionOK=M.OmniSprint or input.Y<-.5
                local aimOK=M.SprintCombat or not actor.ADS
                if directionOK and aimOK then ctrl.IsSprinting=true end
            end
            return M.AirDirection(ctrl,input,original(ctrl,input,dt))
        end)
        M.Wrap(class,"_accelerate",function(original,ctrl,dt,magnitude)
            local a=ctrl._localActor
            local saved={}
            local function change(object,key,value)
                table.insert(saved,{object=object,key=key,value=rawget(object,key)})
                object[key]=value
            end
            if M.Penalties then
                change(a,"SpeedPenalty",nil);change(a,"HitSlowness",nil)
                change(a,"CQB",nil);change(a,"Weight",0);change(ctrl,"_weightMulti",1)
            end
            if M.Survival or M.Penalties then
                local client=Combat.Service().LocalClient
                if client then
                    local full={getValue=function() return 1 end}
                    change(client,"Hunger",full);change(client,"Thirst",full)
                end
            end
            local result=table.pack(pcall(original,ctrl,M.Smoothing and 1000000 or dt,magnitude))
            for i=#saved,1,-1 do local v=saved[i];v.object[v.key]=v.value end
            if not result[1] then error(result[2],0) end
            if M.speedActive and M.CanMove(ctrl) then ctrl.MoveSpeed=M.SpeedValue*math.clamp(magnitude,0,1) end
            return table.unpack(result,2,result.n)
        end)
        M.Wrap(class,"_decelerate",function(original,ctrl,...)
            if M.Smoothing then ctrl.MoveSpeed=0;return end
            return original(ctrl,...)
        end)
        M.Wrap(class,"_exhaust",function(original,ctrl,...)
            if M.NoJumpDelay and M.bunnyJumpingController==ctrl then return true end
            if M.Stamina then ctrl._exhaustStart=tick()-2;ctrl._exhausted=tick()-1;return true end
            return original(ctrl,...)
        end)
        M.Wrap(class,"Update",function(original,ctrl,input,dt)
            M.currentController=ctrl
            if M.Stamina then ctrl._exhaustStart=tick()-2;ctrl._exhausted=tick()-1 end
            if M.Smoothing then ctrl._lastMovement=input end
            if not (M.flyActive and M.CanMove(ctrl)) then
                -- Request sprint before the native controller computes IsSprinting.
                -- UI access stays in Heartbeat so it cannot interrupt native movement.
                local actor=ctrl._localActor
                local autoSprint=M.AutoSprint and M.sprintInputAllowed and standing~=nil
                    and not M.flyActive and M.CanMove(ctrl) and ctrl.HeightState==standing
                    and ctrl.IsGrounded and not ctrl.IsSliding and not ctrl.IsSwimming and not ctrl._emoting
                    and not (actor.CurrentState and actor.CurrentState.Dragging)
                    and (M.SprintCombat or not actor.ADS)
                    and input.Magnitude>.01 and (M.OmniSprint or input.Y<-.5)
                local previousSprint=ctrl.TrySprinting
                if autoSprint then ctrl.TrySprinting=true end
                local result=table.pack(pcall(original,ctrl,input,dt))
                if autoSprint then ctrl.TrySprinting=previousSprint end
                if not result[1] then error(result[2],0) end
                local hopOK,hopError=pcall(M.StepBunny,ctrl,os.clock())
                if not hopOK then M.bunnyError=tostring(hopError);M.ResetBunny() end
                -- FirearmInventory checks Actor.Sprinting even inside its yielding fire loop.
                -- Keep physical sprint speed on the controller; expose a ready weapon pose.
                if M.SprintCombat and M.CanMove(ctrl) then
                    M.sprintActor=ctrl._localActor;M.sprintController=ctrl
                    ctrl._localActor.Sprinting=false
                else M.sprintActor=nil;M.sprintController=nil end
                return table.unpack(result,2,result.n)
            end
            local camera=workspace.CurrentCamera
            if not camera then return original(ctrl,input,dt) end
            M.RestoreAirSpeed();M.ResetBunny()
            local position=ctrl._position
            if ctrl._groundHitbox then position=ctrl._groundHitbox.CFrame:PointToWorldSpace(position) end
            local direction=Vector3.zero
            if not Library:IsTyping() then
                local function down(key) return AimUIS:IsKeyDown(key) and 1 or 0 end
                direction=camera.CFrame.LookVector*(down(Enum.KeyCode.W)-down(Enum.KeyCode.S))
                    +camera.CFrame.RightVector*(down(Enum.KeyCode.D)-down(Enum.KeyCode.A))
                    +Vector3.yAxis*(down(Enum.KeyCode.Space)-down(Enum.KeyCode.LeftControl))
            end
            if direction.Magnitude>1 then direction=direction.Unit end
            local speed=M.FlySpeed*(M.modifierActive and M.Multiplier or 1)
            local target=position+direction*speed*math.clamp(dt,0,.1)
            local grounded,normal=false,Vector3.yAxis
            if not M.Noclip then
                local oldPosition=ctrl._position
                ctrl._position=position
                local result=table.pack(pcall(ctrl._processNewPosition,ctrl,target))
                ctrl._position=oldPosition
                if not result[1] then error(result[2],0) end
                target,grounded,normal=result[2],result[3],result[4]
            end
            ctrl._position=target;ctrl._correctedPosition=target;ctrl._groundHitbox=nil
            ctrl.VelocityGravity=0;ctrl.MoveSpeed=0;ctrl.IsGrounded=grounded;ctrl.SlopeNormal=normal
            ctrl.IsSliding=false;ctrl.IsSprinting=false;ctrl._lastMovement=Vector2.zero
            local actor=ctrl._localActor
            actor.Platform=nil;actor.SimulatedPosition=target;actor.Grounded=grounded
            actor.ForceNextPosition=target;actor.Position=target
            if typeof(actor.CFrame)=="CFrame" then actor.CFrame=CFrame.new(target)*actor.CFrame.Rotation end
            actor.Sliding=false;actor.Sprinting=false
        end)
    end
    function M.InstallFallDamage()
        if M.fallInstalled then return true end
        local service=Combat.Service()
        local replicator=service and service.Replicator
        local inspect=(debug and debug.getupvalues) or getupvalues
        if not replicator or type(replicator.Update)~="function" or not inspect then return false end
        local ok,values=pcall(inspect,replicator.Update)
        if not ok then return false end
        local network,states
        for _,value in pairs(values) do
            if type(value)=="table" then
                local found,method=pcall(function() return value.FireUnreliableServer end)
                if found and type(method)=="function" then network=value end
                local foundStates,result=pcall(function() return value.CharacterHeightState end)
                if foundStates and type(result)=="table" then states=result end
            end
        end
        if not network or not states or states.Standing==nil or states.Falling==nil or states.Skydiving==nil then return false end
        local original=network.FireUnreliableServer
        local function wrapper(self,route,uid,x,y,z,orientation,sprinting,height,...)
            -- Preserve position and physics; only normalize the local airborne replication state.
            if M.active and M.NoFallDamage and route=="ReplicateMovement" then
                local current=Combat.Service()
                local replica=current and current.Replicator
                if replica and replica.LocalActor and uid==replica._uid
                    and (height==states.Falling or height==states.Skydiving) then
                    height=states.Standing
                end
            end
            return original(self,route,uid,x,y,z,orientation,sprinting,height,...)
        end
        network.FireUnreliableServer=wrapper
        table.insert(M.hooks,{class=network,key="FireUnreliableServer",original=original,wrapper=wrapper})
        M.fallInstalled=true
        return true
    end
    function M.Destroy()
        M.active=false
        M.RestoreAirSpeed();M.ResetBunny()
        if M.sprintActor and M.sprintController then M.sprintActor.Sprinting=M.sprintController.IsSprinting end
        if M.connection then M.connection:Disconnect() end
        for i=#M.hooks,1,-1 do
            local h=M.hooks[i]
            if h.class[h.key]==h.wrapper then h.class[h.key]=h.original end
        end
        table.clear(M.hooks)
    end
    local oldDestroy=Combat.Destroy
    Combat.Destroy=function() M.Destroy();oldDestroy() end
    M.connection=AimRunService.Heartbeat:Connect(function()
        local now=tick()
        if (M.AutoHeal or M.AutoSprint or M.AirStrafe or M.BunnyHop) and (not M.inputService or not M.medicalInterface)
            and now>(M.nextActionResolve or 0) then
            M.nextActionResolve=now+2
            M.ResolveActions()
        end
        M.StepAutoHeal(now)
        M.sprintInputAllowed=false
        if M.AutoSprint then
            local ok,blocked=pcall(M.InputBlocked)
            M.sprintInputAllowed=ok and not blocked
            if not ok then M.sprintInputError=tostring(blocked) end
        end
        local movementBlocked=true
        if M.AirStrafe or M.BunnyHop then
            local ok,blocked=pcall(M.InputBlocked)
            movementBlocked=not ok or blocked or game:GetService("GuiService").MenuIsOpen
                or (type(isrbxactive)=="function" and not isrbxactive())
        end
        M.airInputAllowed=not movementBlocked
        M.bunnyActive=M.BunnyHop and not movementBlocked and Combat.KeyActive(M.bunnyKey)
        if not M.bunnyActive then M.ResetBunny() end
        if not M.AirStrafe or movementBlocked then M.RestoreAirSpeed() end
        local focused=Library:IsTyping()
        if not focused then
            local speed=Combat.KeyActive(M.speedKey,M.speedState)
            local fly=Combat.KeyActive(M.flyKey,M.flyState)
            local boost=Combat.KeyActive(M.modifierKey,M.modifierState)
            M.speedActive=M.Speed and speed;M.flyActive=M.Fly and fly
            M.modifierActive=M.flyActive and M.Modifier and boost
        else M.speedActive=false;M.flyActive=M.Fly and M.flyActive;M.modifierActive=false end
        if M.NoFallDamage and not M.fallInstalled and tick()>(M.nextFallResolve or 0) then
            M.nextFallResolve=tick()+2
            local ok,err=pcall(M.InstallFallDamage)
            if not ok then M.fallError=tostring(err) end
        end
        if not M.installed and tick()> (M.nextResolve or 0) then
            M.nextResolve=tick()+2
            for _,module in ipairs(getloadedmodules()) do
                if module.Name=="CharacterController" then
                    local ok,class=pcall(require,module)
                    if ok and type(class)=="table" then
                        local installed,err=pcall(M.Install,class)
                        if installed then M.installed=true
                        else M.Destroy();warn("[Movements] "..tostring(err)) end
                    end
                    break
                end
            end
        end
    end)
end

-- ── SPINBOT ──────────────────────────────────────────────────────
do
    local SpinSec = movementPages[1]:AddSection({Title="Spinbot", Side="Right"})
    local spinEnabled = false
    local spinSpeed = 20
    local spinHeartConn = nil
    local spinCC = nil  -- hooked CharacterCamera ref

    -- Layer 1: hook CharacterCamera.Update (same technique as reference script)
    -- Sets actor.Orientation/GoalOrientation/CameraX so the camera tracks the spin client-side
    local function hookCameraUpdate()
        if spinCC then return end
        local cc = getgenv and getgenv().CharacterCamera
        if not cc then
            for _, obj in pairs(getgc(true)) do
                if type(obj)=="table" and rawget(obj,"Update") and rawget(obj,"Render") and rawget(obj,"Watch") then
                    cc = obj; break
                end
            end
        end
        if not cc or not cc.Update or cc._spinbotOrig then return end
        cc._spinbotOrig = cc.Update
        cc.Update = function(self, ...)
            local res = cc._spinbotOrig(self, ...)
            if spinEnabled then
                local ok, svc = pcall(Combat.Service)
                local actor = ok and svc and svc.Replicator and svc.Replicator.LocalActor
                if actor and actor.Alive then
                    local yaw = (tick() * spinSpeed) % (math.pi * 2)
                    actor.Orientation = yaw; actor.GoalOrientation = yaw; actor.CameraX = yaw
                end
            end
            return res
        end
        spinCC = cc
    end

    local function bindSpin()
        if spinHeartConn then spinHeartConn:Disconnect(); spinHeartConn = nil end
        AimRunService:UnbindFromRenderStep("ERISKOI_Spinbot")
        if not spinEnabled then return end
        pcall(hookCameraUpdate)
        -- Layer 2 (Heartbeat): drives actor orientation fields + actor.CFrame → replicator reads these
        -- Layer 3 (RenderStep 2000): keeps visual root.CFrame in sync after character controller runs
        spinHeartConn = AimRunService.Heartbeat:Connect(function()
            local ok, svc = pcall(Combat.Service)
            local actor = ok and svc and svc.Replicator and svc.Replicator.LocalActor
            if not actor or not actor.Alive then return end
            local root = actor.RootPart
            if not root then return end
            local yaw = (tick() * spinSpeed) % (math.pi * 2)
            -- actor orientation fields (network replication path, same as reference script)
            actor.Orientation = yaw; actor.GoalOrientation = yaw
            actor.CameraX = yaw; actor.CameraY = 0
            -- actor.CFrame rotation (BRM5 replication layer)
            if typeof(actor.CFrame) == "CFrame" then
                actor.CFrame = CFrame.new(actor.Position) * CFrame.Angles(0, yaw, 0)
            end
        end)
        AimRunService:BindToRenderStep("ERISKOI_Spinbot", 2000, function()
            local ok, svc = pcall(Combat.Service)
            local actor = ok and svc and svc.Replicator and svc.Replicator.LocalActor
            if not actor or not actor.Alive then return end
            local root = actor.RootPart
            if not root then return end
            local yaw = (tick() * spinSpeed) % (math.pi * 2)
            local vel = root.AssemblyLinearVelocity
            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
            root.AssemblyLinearVelocity = vel
        end)
    end

    SpinSec:AddToggle({Text="Enable Spinbot", Flag="spinbot_enabled", Default=false,
        Callback=function(v) spinEnabled=v; bindSpin() end})
    SpinSec:AddSlider({Text="Spin Speed", Flag="spinbot_speed", Min=1, Max=100, Default=20, Rounding=1, Suffix="",
        Callback=function(v) spinSpeed=v end})

    local prevDestroySpinbot = Combat.Destroy
    Combat.Destroy = function()
        if spinHeartConn then spinHeartConn:Disconnect(); spinHeartConn = nil end
        AimRunService:UnbindFromRenderStep("ERISKOI_Spinbot")
        if spinCC and spinCC._spinbotOrig then
            spinCC.Update = spinCC._spinbotOrig; spinCC._spinbotOrig = nil
        end
        spinCC = nil
        prevDestroySpinbot()
    end
end

local GunPage = legacyPage(Tabs.Mods, modPages, 'Gun Mods')
local TurretPage = legacyPage(Tabs.Mods, modPages, 'Turret Mods')
local VehiclePage = legacyPage(Tabs.Mods, modPages, 'Vehicle Mods')
local MeleePage = legacyPage(Tabs.Mods, modPages, 'Melee Mods')
local AKPage = legacyPage(Tabs.Mods, modPages, 'Aura Kill V3')
local GunVisualsPage = GunPage
local Gun: {[string]: any}={NoRecoil=false,InstantADS=false,NoSway=false,NoSpread=false,SpreadReduction=100,
    UnlockModes=false,AutoReload=false,ForceHeadshot=false,active=true,originals={},hooks={},nextResolve=0,
    Visuals=false,Transparency=0,Material="Original",visualParts={},nextVisualScan=0,nextReload=0,
    WeaponColor=Color3.fromRGB(150,80,255),Tracers=false,TracerStyle="Lightning",
    TracerColor=Color3.fromRGB(150,80,255),TracerDuration=.6,TracerWidth=.08}
Combat.Gun=Gun
function Gun.RestoreTunes()
    for tune,fields in pairs(Gun.originals) do
        for key,saved in pairs(fields) do
            if tune[key]==saved.applied then tune[key]=saved.value end
        end
    end
    Gun.originals={}
end
function Gun.ApplyField(tune,key,enabled,transform)
    local fields=Gun.originals[tune]
    local saved=fields and fields[key]
    if not enabled then
        if saved then
            if tune[key]==saved.applied then tune[key]=saved.value end
            fields[key]=nil
        end
        return
    end
    if not fields then fields={};Gun.originals[tune]=fields end
    if not saved then saved={value=tune[key]};fields[key]=saved
    elseif tune[key]~=saved.applied then saved.value=tune[key] end
    saved.applied=transform(saved.value)
    tune[key]=saved.applied
end
function Gun.RestoreModes(weapon)
    local tune=weapon and weapon._firearm and weapon._firearm.Tune
    local saved=tune and Gun.originals[tune] and Gun.originals[tune].Firemodes
    local meta=weapon and weapon._item and weapon._item.MetaData
    if saved and type(saved.value)=="table" and meta then
        local mode=tune.Firemodes[meta.Mode]
        meta.Mode=table.find(saved.value,mode) or 1
    end
    if tune then Gun.ApplyField(tune,"Firemodes",false) end
end
function Gun.ApplyWeapon(weapon)
    local tune=weapon and weapon._firearm and weapon._firearm.Tune
    if type(tune)~="table" then return end
    Gun.modeWeapons=Gun.modeWeapons or {}
    if not Gun.UnlockModes and Gun.modeWeapons[weapon] then
        Gun.RestoreModes(weapon);Gun.modeWeapons[weapon]=nil;weapon._fireMode=nil
    end
    Gun.ApplyField(tune,"Barrel_Spread",Gun.NoSpread,function(base) return (base or 1)*(1-Gun.SpreadReduction/100) end)
    Gun.ApplyField(tune,"RPM",Gun.RPM==true,function() return math.clamp(Gun.RPMValue or 900,60,3000) end)
    Gun.ApplyField(tune,"Equip_Delay",Gun.NoEquipDelay==true,function() return 0 end)
    if type(tune.Firemodes)=="table" then
        local before=tune.Firemodes
        Gun.ApplyField(tune,"Firemodes",Gun.UnlockModes,function(base)
            local fields=Gun.originals[tune]
            local saved=fields and fields.Firemodes
            if saved and saved.expanded and saved.base==base then return saved.expanded end
            local modes=table.clone(base)
            for _,mode in ipairs({1,2,3,0}) do if not table.find(modes,mode) then modes[#modes+1]=mode end end
            if saved then saved.base=base;saved.expanded=modes end
            return modes
        end)
        if Gun.UnlockModes then Gun.modeWeapons[weapon]=true end
        if before~=tune.Firemodes then
            weapon._fireMode=nil
            if weapon.Equipped and type(weapon.UpdateHUD)=="function" then pcall(weapon.UpdateHUD,weapon) end
        end
    end
end
function Gun.ReloadReady(weapon)
    if not weapon or not weapon.Equipped or weapon._reloading or not weapon._firearm then return false end
    local meta=weapon._item and weapon._item.MetaData
    if not meta then return false end
    local ammo=weapon._mag and weapon._mag.Capacity or 0
    return ammo<=0 and (weapon._firearm.Tune.NoChamber or not meta.Chamber)
end
function Gun.RequestReload(weapon)
    if not Gun.ReloadReady(weapon) then return "Not ready" end
    local mags=weapon:_getMags()
    if type(mags)~="table" or not mags[1] then return "No compatible reserve ammunition" end
    local reload=Gun.firearmClass and Gun.firearmClass._reload
    if type(reload)~="function" then return "Reload adapter unavailable" end
    weapon._cancelReload=false
    reload(weapon,true)
    return weapon._reloading and "Reloading" or "Waiting for game"
end
function Gun.UpdateTune()
    local weapons=Combat.Weapons();local live={};local keep={}
    for _,weapon in ipairs(weapons) do
        keep[weapon]=true;live[weapon._firearm.Tune]=true
        Gun.ApplyWeapon(weapon)
    end
    for weapon in pairs(Gun.modeWeapons or {}) do
        if not keep[weapon] then Gun.RestoreModes(weapon);Gun.modeWeapons[weapon]=nil end
    end
    for tune,fields in pairs(Gun.originals) do
        if not live[tune] then
            for key,saved in pairs(fields) do if tune[key]==saved.applied then tune[key]=saved.value end end
            Gun.originals[tune]=nil
        end
    end
    local weapon=Combat.Weapon()
    if Gun.AutoReload and Gun.ReloadReady(weapon) and os.clock()>=Gun.nextReload and not Gun.reloadPending
        and Gun.firearmClass and type(Gun.firearmClass._reload)=="function" then
        Gun.nextReload=os.clock()+.6;Gun.reloadPending=true
        task.defer(function()
            local ok,err=pcall(function()
                if not Gun.active or not Gun.AutoReload or Combat.Weapon()~=weapon or not Gun.ReloadReady(weapon) then return end
                Gun.reloadStatus=Gun.RequestReload(weapon)
            end)
            Gun.reloadError=not ok and tostring(err) or nil
            Gun.reloadPending=false
        end)
    end
end

function Gun.RestoreVisuals()
    for part,saved in pairs(Gun.visualParts) do
        if part.Parent then
            for key,value in pairs(saved.original) do
                if part[key]==saved.applied[key] then part[key]=value end
            end
        end
    end
    Gun.visualParts={};Gun.visualModel=nil;Gun.nextVisualScan=0
end
function Gun.UpdateVisuals()
    if not Gun.Visuals then
        if Gun.visualModel or next(Gun.visualParts)~=nil then Gun.RestoreVisuals() end
        return
    end
    local c=Combat.Service()
    local actor=c and c.Replicator and c.Replicator.LocalActor
    local weapon=Combat.Weapon()
    local model=weapon and weapon._firearm and actor.ViewModel and actor.ViewModel.CurrentModel
    if model~=Gun.visualModel then Gun.RestoreVisuals() end
    if not model or not model.Parent then return end
    Gun.visualModel=model
    if os.clock()>=Gun.nextVisualScan then
        Gun.nextVisualScan=os.clock()+.2
        for _,part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency<1 and not Gun.visualParts[part] then
                Gun.visualParts[part]={original={Material=part.Material,MaterialVariant=part.MaterialVariant,
                    Transparency=part.Transparency,Color=part.Color},applied={}}
            end
        end
    end
    for part,saved in pairs(Gun.visualParts) do
        if not part:IsDescendantOf(model) then
            if part.Parent then
                for key,value in pairs(saved.original) do
                    if part[key]==saved.applied[key] then part[key]=value end
                end
            end
            Gun.visualParts[part]=nil
        else
            local material=Gun.Material=="Original" and saved.original.Material or Enum.Material[Gun.Material]
            local values={Material=material,MaterialVariant=Gun.Material=="Original" and saved.original.MaterialVariant or "",
                Transparency=Gun.Transparency/100,Color=Gun.Material~="Original" and Gun.WeaponColor or saved.original.Color}
            for key,value in pairs(values) do
                saved.applied[key]=value
                if part[key]~=value then part[key]=value end
            end
        end
    end
end
function Gun.ClearTracers()
    if Gun.tracerFolder then Gun.tracerFolder:Destroy();Gun.tracerFolder=nil end
end
function Gun.TracerPoints(from,to,style,random)
    local length=(to-from).Magnitude
    if length<.01 then return {} end
    local cf=CFrame.lookAt(from,to)
    local turns=math.clamp(length/18,2,5)
    local smooth=style=="DNA"
    local count=style=="Line" and 1 or (smooth and math.ceil(turns*12) or math.clamp(math.ceil(length/3),12,48))
    local strands=style=="DNA" and 2 or 1
    local paths={}
    for strand=1,strands do
        local points={}
        for i=0,count do
            local t=i/count
            local offset=Vector3.zero
            if i>0 and i<count then
                if style=="Lightning" then
                    local radius=math.min(length*.025,.65)
                    offset=cf.RightVector*random:NextNumber(-radius,radius)+cf.UpVector*random:NextNumber(-radius,radius)
                elseif style=="DNA" then
                    -- Keep the helix open through the middle; taper only its ends.
                    local angle=t*math.pi*2*turns+(strand-1)*math.pi*2/strands
                    local envelope=math.sin(math.min(1,math.min(t,1-t)*8)*math.pi*.5)
                    local radius=math.min(length*.03,.45)*envelope
                    offset=(cf.RightVector*math.cos(angle)+cf.UpVector*math.sin(angle))*radius
                end
            end
            points[#points+1]=from:Lerp(to,t)+offset
        end
        paths[#paths+1]=points
    end
    return paths
end
function Gun.DrawTracer(from,to)
    if not Gun.active or not Gun.Tracers or typeof(from)~="Vector3" or typeof(to)~="Vector3" then return end
    local paths=Gun.TracerPoints(from,to,Gun.TracerStyle,Random.new())
    if #paths==0 or not workspace.CurrentCamera then return end
    if not Gun.tracerFolder then
        Gun.tracerFolder=Instance.new("Folder");Gun.tracerFolder.Name="LeanGunTracers"
    end
    Gun.tracerFolder.Parent=workspace.CurrentCamera
    local existing=Gun.tracerFolder:GetChildren()
    if #existing>=24 then existing[1]:Destroy() end
    local anchor=Instance.new("Part")
    anchor.Name="Tracer";anchor.Anchored=true;anchor.Transparency=1;anchor.Size=Vector3.one*.01
    anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.CastShadow=false
    anchor.CFrame=CFrame.new(from);anchor.Parent=Gun.tracerFolder
    local function connect(a,b,width)
        local beam=Instance.new("Beam")
        beam.Attachment0=a;beam.Attachment1=b;beam.FaceCamera=true
        beam.Width0=width;beam.Width1=width;beam.Segments=1
        beam.Color=ColorSequence.new(Gun.TracerColor);beam.LightEmission=1;beam.LightInfluence=0
        beam.Transparency=NumberSequence.new(0);beam.Parent=anchor
        game:GetService("TweenService"):Create(beam,TweenInfo.new(Gun.TracerDuration),{Width0=0,Width1=0}):Play()
    end
    local attachments={}
    for index,points in ipairs(paths) do
        local list={};attachments[index]=list
        for i,point in ipairs(points) do
            local a=Instance.new("Attachment");a.Position=point-from;a.Parent=anchor;list[i]=a
            if i>1 then connect(list[i-1],a,Gun.TracerWidth) end
        end
    end
    if Gun.TracerStyle=="DNA" and #attachments==2 then
        for i=4,#attachments[1]-3,3 do connect(attachments[1][i],attachments[2][i],Gun.TracerWidth*.35) end
    end
    game:GetService("Debris"):AddItem(anchor,Gun.TracerDuration)
end
function Gun.Hook(class,key,make)
    local original=class[key]
    if type(original)~="function" then return false end
    local raw=rawget(class,key)
    local wrapper=make(original)
    class[key]=wrapper
    Gun.hooks[#Gun.hooks+1]={class=class,key=key,raw=raw,wrapper=wrapper}
    return true
end
function Gun.Resolve()
    if os.clock()<Gun.nextResolve then return end
    Gun.nextResolve=os.clock()+2
    local service=Combat.Service()
    local replicator=service and service.Replicator
    if replicator and replicator~=Gun.effectsReplicator and type(replicator._bulletEffects)=="function" then
        if Gun.Hook(replicator,"_bulletEffects",function(original)
            return function(self,from,to,part,normal,material,caliber,isLocal,...)
                local result=table.pack(original(self,from,to,part,normal,material,caliber,isLocal,...))
                if isLocal then
                    local ok,err=pcall(Gun.DrawTracer,from,to)
                    if not ok then Gun.tracerError=tostring(err) end
                end
                return table.unpack(result,1,result.n)
            end
        end) then Gun.effectsReplicator=replicator end
    end
    if replicator and replicator~=Gun.impactReplicator and type(replicator._bulletProcess)=="function" then
        if Gun.Hook(replicator,"_bulletProcess",function(original)
            return function(self,uid,replicate,position,part,normal,material,elapsed,...)
                if Gun.active and Gun.ForceHeadshot and replicate and part then
                    local actorUID,actor=self:GetFromBodyPart(part)
                    local kind=actor and Combat.Kind(actor)
                    local head=actor and actor.Parts and actor.Parts.Head
                    local friendly=kind=="Players" and actor.Owner.Team~=nil
                        and actor.Owner.Team==AimLocalPlayer.Team
                    if actorUID and kind and not friendly and head and head.Parent
                        and head:IsDescendantOf(actor.Character) then
                        part=head
                    end
                end
                return original(self,uid,replicate,position,part,normal,material,elapsed,...)
            end
        end) then Gun.impactReplicator=replicator end
    end
    if Gun.recoiler and Gun.viewmodel then return end
    for _,m in ipairs(getloadedmodules()) do
        if m.Name=="Recoiler" and not Gun.recoiler then
            local ok,class=pcall(require,m)
            if ok and type(class)=="table" then
                Gun.Hook(class,"GetViewmodelAdjustment",function(original)
                    return function(self,...)
                        if Gun.active and Gun.NoRecoil then return CFrame.identity end
                        return original(self,...)
                    end
                end)
                Gun.Hook(class,"GetCameraAdjustment",function(original)
                    return function(self,...)
                        if Gun.active and Gun.NoRecoil then return CFrame.identity,0 end
                        return original(self,...)
                    end
                end)
                Gun.recoiler=true
            end
        elseif m.Name=="ViewmodelClass" and not Gun.viewmodel then
            local ok,class=pcall(require,m)
            if ok and type(class)=="table" then
                Gun.viewmodel=Gun.Hook(class,"Update",function(original)
                    return function(vm,...)
                        local c=Combat.Service()
                        local localActor=c and c.Replicator and c.Replicator.LocalActor
                        if not Gun.active or vm.Actor~=localActor then return original(vm,...) end
                        if Gun.InstantADS then
                            vm.ADSLerp=(localActor.ADS and not vm.Reloading and not localActor.Sliding) and 1 or 0
                        end
                        local sway,kick=vm._swaySpring,vm.Kick
                        if Gun.NoSway and sway then
                            vm._swaySpring={Position={ToCFrame=function() return CFrame.identity end}}
                        end
                        if Gun.NoRecoil and kick then vm.Kick={Position=Vector3.zero} end
                        local result=table.pack(pcall(original,vm,...))
                        vm._swaySpring=sway;vm.Kick=kick
                        if not result[1] then error(result[2],0) end
                        return table.unpack(result,2,result.n)
                    end
                end)
            end
        end
    end
end
function Gun.Destroy()
    Gun.active=false
    for weapon in pairs(Gun.modeWeapons or {}) do Gun.RestoreModes(weapon) end
    Gun.RestoreModes(Gun.modeWeapon)
    Gun.RestoreTunes()
    Gun.RestoreVisuals()
    Gun.ClearTracers()
    for _,h in ipairs(Gun.hooks) do
        if h.class[h.key]==h.wrapper then h.class[h.key]=h.raw end
    end
    Gun.hooks={}
end
local destroyCombat=Combat.Destroy
Combat.Destroy=function() Gun.Destroy();destroyCombat() end
local GunHandling=GunPage:AddSection({Title="Handling",Side="Left"})
for _,entry in ipairs({{"No Recoil","NoRecoil"},{"Instant ADS","InstantADS"},{"No Sway","NoSway"}}) do
    local key=entry[2]
    GunHandling:AddToggle({Text=entry[1],Flag="gun_"..key,Default=false,
        Callback=function(v) Gun[key]=v end})
end
local GunBallistics=GunPage:AddSection({Title="Ballistics",Side="Right"})
GunBallistics:AddToggle({Text="No Spread",Flag="gun_no_spread",Default=false,
    Callback=function(v) Gun.NoSpread=v;Gun.UpdateTune() end})
GunBallistics:AddSlider({Text="Spread Reduction",Flag="gun_spread_reduction",
    Min=0,Max=100,Rounding=1,Default=100,Suffix="%",
    Callback=function(v) Gun.SpreadReduction=v;Gun.UpdateTune() end})
GunHandling:AddToggle({Text="All Firemodes",Flag="gun_unlock_modes",Default=false,
    Callback=function(v) Gun.UnlockModes=v;Gun.UpdateTune() end})
GunHandling:AddToggle({Text="Auto Reload",Flag="gun_auto_reload",Default=false,
    Callback=function(v) Gun.AutoReload=v;Gun.UpdateTune() end})
GunBallistics:AddToggle({Text="Force Headshot",Flag="gun_force_headshot",Default=false,
    Callback=function(v) Gun.ForceHeadshot=v end})
local GunVisualSection=GunVisualsPage:AddSection({Title="Weapon Appearance",Side="Left"})
GunVisualSection:AddToggle({Text="Enabled",Flag="gun_visuals",Default=false,
    Callback=function(v) Gun.Visuals=v;Gun.UpdateVisuals() end})
GunVisualSection:AddDropdown({Text="Material",Flag="gun_material",Default="Original",
    Options={"Original","ForceField","Neon","SmoothPlastic","Glass","Metal","Ice"},
    Callback=function(v) Gun.Material=v;Gun.UpdateVisuals() end})
GunVisualSection:AddSlider({Text="Transparency",Flag="gun_transparency",Min=0,Max=100,Rounding=1,
    Default=0,Suffix="%",Callback=function(v) Gun.Transparency=v;Gun.UpdateVisuals() end})
GunVisualSection:AddColorPicker({Text="Weapon Color",Flag="gun_weapon_color",Default=Gun.WeaponColor,
    Callback=function(v) Gun.WeaponColor=v;Gun.UpdateVisuals() end})
local GunTracerSection=GunVisualsPage:AddSection({Title="Bullet Tracers",Side="Right"})
GunTracerSection:AddToggle({Text="Enabled",Flag="gun_tracers",Default=false,
    Callback=function(v) Gun.Tracers=v;if not v then Gun.ClearTracers() end end})
GunTracerSection:AddDropdown({Text="Effect",Flag="gun_tracer_style",Default="Lightning",
    Options={"Line","Lightning","DNA"},Callback=function(v)
        Gun.TracerStyle=(v=="Line" or v=="Lightning" or v=="DNA") and v or "Lightning"
    end})
GunTracerSection:AddColorPicker({Text="Tracer Color",Flag="gun_tracer_color",Default=Gun.TracerColor,
    Callback=function(v)
        Gun.TracerColor=v
        if Gun.tracerFolder then
            for _,beam in ipairs(Gun.tracerFolder:GetDescendants()) do
                if beam:IsA("Beam") then beam.Color=ColorSequence.new(v) end
            end
        end
    end})
GunTracerSection:AddSlider({Text="Duration",Flag="gun_tracer_duration",Min=.1,Max=3,Rounding=.1,
    Default=.6,Suffix=" s",Callback=function(v) Gun.TracerDuration=v end})
GunTracerSection:AddSlider({Text="Width",Flag="gun_tracer_width",Min=.02,Max=.3,Rounding=.01,
    Default=.08,Callback=function(v) Gun.TracerWidth=v end})

-- BRM5 adapters verified against place version 10120.
do
    local X: {[string]: any}={classes={},nextScan=0,saved={},active=true}
    local V: {[string]: any}={Speed=false,SpeedValue=80,Stability=false,FastStart=false,Fly=false,FlySpeed=60,Noclip=false,Bounce=false,bounceStates=setmetatable({},{__mode="k"}),keyState={}}
    local T={RPM=false,RPMValue=900,NoSpread=false,NoRecoil=false}
    local A: {[string]: any}={Headshot=false,Reach=false,Distance=8,Aura=false,Targets={Zombies=true,NPCs=true},keyState={},nextSwing=0,nextTargetScan=0}
    Combat.Extensions=X;Combat.Vehicle=V;Combat.Turret=T;Combat.Melee=A
    Gun.RPM=false;Gun.RPMValue=900
    Gun.NoCameraShake=false;Gun.SightZoom=false;Gun.Zoom=2;Gun.NoEquipDelay=false;Gun.Debug=false
    local function actor()
        local s=Combat.Service();return s and s.Replicator and s.Replicator.LocalActor
    end
    local function localWeapon(w) return w and w._actor==actor() end
    local function field(object,key,on,value)
        if type(object)~="table" then return end
        local saved=X.saved[object]
        if on then
            if not saved then saved={};X.saved[object]=saved end
            local old=saved[key]
            if not old then old={value=rawget(object,key)};saved[key]=old end
            object[key]=value;old.applied=value
        elseif saved and saved[key] then
            local old=saved[key]
            if rawget(object,key)==old.applied then object[key]=old.value end
            saved[key]=nil
            if next(saved)==nil then X.saved[object]=nil end
        end
    end
    local function restore(object)
        local saved=X.saved[object]
        if saved then
            for key,old in pairs(saved) do if rawget(object,key)==old.applied then object[key]=old.value end end
            X.saved[object]=nil
        end
    end
    local function toggle(section,text,state,key,flag)
        section:AddToggle({Text=text,Flag=flag,Default=false,Callback=function(v) state[key]=v end})
    end
    local function slider(section,text,state,key,flag,min,max,default,step,suffix)
        section:AddSlider({Text=text,Flag=flag,Min=min,Max=max,Default=default,Rounding=step,Suffix=suffix or "",
            Callback=function(v) state[key]=math.clamp(v,min,max) end})
    end
    toggle(GunHandling,"RPM Modifier",Gun,"RPM","gun_rpm_enabled")
    slider(GunHandling,"RPM",Gun,"RPMValue","gun_rpm_value",60,3000,900,10," RPM")
    toggle(GunHandling,"No Equip Delay",Gun,"NoEquipDelay","gun_no_equip_delay")
    toggle(GunHandling,"No Camera Shake",Gun,"NoCameraShake","gun_no_camera_shake")
    toggle(GunHandling,"Sight Zoom",Gun,"SightZoom","gun_sight_zoom")
    slider(GunHandling,"Sight Magnification",Gun,"Zoom","gun_sight_magnification",1,10,2,.1,"x")
    toggle(GunVisualSection,"Gun Debug HUD",Gun,"Debug","gun_debug_hud")
    local mp=MeleePage
    local ml=mp:AddSection({Title="Melee",Side="Left"})
    local mr=mp:AddSection({Title="Melee Aura",Side="Right"})
    toggle(ml,"Melee Force Headshot",A,"Headshot","melee_force_headshot")
    toggle(ml,"Extended Reach",A,"Reach","melee_extended_reach")
    slider(ml,"Reach Distance",A,"Distance","melee_reach_distance",0,20,8,.5," studs")
    toggle(mr,"Melee Aura",A,"Aura","melee_kill_aura")
    A.key=mr:AddKeyPicker({Text="Kill Aura Key",Flag="melee_aura_key",Default="None",Mode="Toggle",Callback=function() end})
    mr:AddDropdown({Text="Targets",Flag="melee_aura_targets",Options={"Zombie","NPC","Player"},Default={"Zombie","NPC"},Multi=true,
        Callback=function(values)
            local selected={};local map={Zombie="Zombies",NPC="NPCs",Player="Players"}
            if type(values)=="string" then values={values} end
            for k,v in pairs(values or {}) do local name=type(k)=="number" and v or (v and k);if map[name] then selected[map[name]]=true end end
            A.Targets=selected
        end})

    -- ── Aura Kill V2 ──────────────────────────────────────────────────────────
    -- Pipeline: InventoryAction "Slash" → InventoryAction "Impact"
    -- Timing + reach matched to MTC game_tree dump (MeleeInventory.lua / Melee.lua) —
    -- server most likely gates Impact on realistic melee distance + Slash→Impact delay.
    local AK2: {[string]: any} = {
        enabled     = false,
        killAI      = true,
        killZombie  = true,
        killPlayer  = false,
        hitPart     = "Head",
        maxPerCycle = 12,
        cooldown    = 0.15,
        headYOffset = 1.5,
        range       = 8,        -- MTC Melee.lua: max real Reach = 7 (Tomahawk). Server likely
                                 -- validates Impact distance against this — stay close to it.
        impactDelay = 0.3,      -- MTC Melee.lua: real Slash→Impact gap is 0.25-0.3s (MeleeInventory._use).
                                 -- Firing both same-frame (old behavior) looks server-impossible.
        _lastFire   = {},
        _net        = nil,
        _remote     = nil,
        _netRetry   = 0,
    }
    Combat.AK2 = AK2

    local function AK2_findNet()
        if AK2._net then return AK2._net end
        if os.clock() < AK2._netRetry then return nil end
        AK2._netRetry = os.clock() + 1
        -- Method 0: shared.import("network") — cleanest, verified via oldvis RSpy dump
        if shared and type(shared.import) == "function" then
            local ok, net = pcall(function() return shared.import("network") end)
            if ok and net and rawget(net, "_key") and rawget(net, "_code") then
                AK2._net = net; return net
            end
        end
        -- Method 1: getupvalues on Replicator.Update
        local inspect = (debug and debug.getupvalues) or getupvalues
        local svc = Combat.Service()
        local rep = svc and svc.Replicator
        if inspect and rep and type(rep.Update) == "function" then
            local ok, vals = pcall(inspect, rep.Update)
            if ok and type(vals) == "table" then
                for _, v in pairs(vals) do
                    if type(v) == "table" then
                        local ok2, fs = pcall(function() return v.FireServer end)
                        if ok2 and type(fs) == "function" then AK2._net = v; return v end
                    end
                end
            end
        end
        -- Method 2: GC scan — cipher net (_code+_key+_events) OR direct net (FireServer+_events)
        local gok, gc = pcall(function() return filtergc("table") end)
        if not gok then gok, gc = pcall(function() return getgc(true) end) end
        if gok and gc then
            for _, v in ipairs(gc) do
                if type(v) ~= "table" then continue end
                local k  = rawget(v, "_key")
                local co = rawget(v, "_code")
                local ev = rawget(v, "_events")
                -- Cipher net pattern: _code (UUID) + _key (5 nums) + _events
                if type(k)=="table" and #k>=5
                    and type(co)=="string" and co:match("^%x+%-%x+%-%x+%-%x+%-%x+$")
                    and type(ev)=="table" then
                    local allNums = true
                    for _, n in ipairs(k) do if type(n)~="number" then allNums=false; break end end
                    if allNums then AK2._net = v; return v end
                end
                -- Direct net pattern: FireServer method + known event keys
                if type(rawget(v, "FireServer"))=="function" and type(ev)=="table" then
                    if rawget(ev, "ReplicateBulkActor") ~= nil or rawget(ev, "RegisterActor") ~= nil then
                        AK2._net = v; return v
                    end
                end
            end
        end
        return nil
    end

    -- RemoteEvent via ReplicatedStorage.Events — fallback for cipher path (oldvis verified)
    local function AK2_getRemote()
        if AK2._remote and AK2._remote.Parent then return AK2._remote end
        local ev = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
        if ev then
            local re = ev:FindFirstChild("RemoteEvent")
            if re then AK2._remote = re; return re end
        end
        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("RemoteEvent") then AK2._remote = v; return v end
        end
        return nil
    end

    -- XOR-rotation cipher — exact match from Flux_client.lua, verified vs RSpy dump (oldvis)
    local function AK2_netEncode(jsonStr, key)
        local result = ""
        for i = 1, #jsonStr do
            local ki   = i % 4
            local kval = key[ki + 1]
            local nb   = (string.byte(jsonStr, i) - 32 + kval) % 95 + 32
            result = result .. string.char(nb)
        end
        local firstByte = string.byte(jsonStr, 1)
        for v24 = 1, key[5] do
            local v27 = firstByte - string.byte(tostring(v24), 1)
            result = result .. string.char(v27)
        end
        return result
    end

    local function AK2_fire(net, ...)
        -- Cipher path: net has _code + _key — fire encoded payload via RemoteEvent:FireServer
        local code = rawget(net, "_code")
        local key  = rawget(net, "_key")
        if type(code)=="string" and type(key)=="table" and #key>=5 then
            local remote = AK2_getRemote()
            if remote then
                local hs = game:GetService("HttpService")
                local args = {...}
                local payload = {code}
                for _, a in ipairs(args) do payload[#payload+1] = a end
                local ok2, raw = pcall(function() return hs:JSONEncode(payload) end)
                if ok2 and raw then
                    local enc = AK2_netEncode(raw, key)
                    pcall(function() remote:FireServer(enc) end)
                    return
                end
            end
        end
        -- Direct path: net.FireServer handles encoding internally
        local ok = pcall(net.FireServer, net, ...)
        if not ok then AK2._net = nil end
    end

    table.insert(Combat.connections, AimRunService.Heartbeat:Connect(function()
        if not AK2.enabled then return end
        local net = AK2_findNet()
        if not net then return end
        local svc = Combat.Service()
        local registry = svc and svc.Replicator and svc.Replicator.Actors
        if not registry then return end
        local now = tick(); local count = 0
        local myActor = svc and svc.Replicator and svc.Replicator.LocalActor
        local myPos = myActor and typeof(myActor.Position)=="Vector3" and myActor.Position
        for uid, a in pairs(registry) do
            if count >= AK2.maxPerCycle then break end
            if not Combat.IsAlive(a) then continue end
            local kind = Combat.Kind(a)
            if not kind then continue end
            local allow = false
            if kind == "Zombies" and AK2.killZombie then allow = true end
            if kind == "NPCs"    and AK2.killAI     then allow = true end
            if kind == "Players" and AK2.killPlayer then allow = true end
            if not allow then continue end
            if (now - (AK2._lastFire[uid] or 0)) < AK2.cooldown then continue end
            local pos = a.Position
            if typeof(pos) ~= "Vector3" then continue end
            if myPos and (pos - myPos).Magnitude > AK2.range then continue end
            AK2._lastFire[uid] = now
            local hitPos = { pos.X, pos.Y + AK2.headYOffset, pos.Z }
            local slashArg = math.random(1, 3)
            AK2_fire(net, "InventoryAction", "Slash", slashArg)
            -- MTC MeleeInventory._use: real client waits `_delay` (0.25-0.3s) after Slash
            -- before raycasting + firing Impact. Matching that timing, not same-frame.
            task.delay(AK2.impactDelay, function()
                if not AK2.enabled then return end
                local n = AK2_findNet(); if not n then return end
                AK2_fire(n, "InventoryAction", "Impact", hitPos, uid, AK2.hitPart)
            end)
            count = count + 1
        end
    end))

    local ak2l = mp:AddSection({Title="Aura Kill V2",Side="Left"})
    ak2l:AddToggle({Text="Enable",Flag="ak2_enabled",Default=false,
        Callback=function(v) AK2.enabled=v end})
    ak2l:AddToggle({Text="Kill NPCs",Flag="ak2_kill_ai",Default=true,
        Callback=function(v) AK2.killAI=v end})
    ak2l:AddToggle({Text="Kill Zombies",Flag="ak2_kill_zombie",Default=true,
        Callback=function(v) AK2.killZombie=v end})
    ak2l:AddToggle({Text="Kill Players",Flag="ak2_kill_player",Default=false,
        Callback=function(v) AK2.killPlayer=v end})
    ak2l:AddDropdown({Text="Hit Part",Flag="ak2_hitpart",
        Options={"Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"},
        Default="Head",
        Callback=function(v) AK2.hitPart=v end})
    ak2l:AddSlider({Text="Max Targets/Tick",Flag="ak2_max_targets",
        Min=1,Max=30,Default=12,Rounding=1,Suffix="",
        Callback=function(v) AK2.maxPerCycle=math.clamp(v,1,30) end})
    ak2l:AddSlider({Text="Hit Cooldown",Flag="ak2_cooldown",
        Min=0.05,Max=2.0,Default=0.15,Rounding=0.05,Suffix=" s",
        Callback=function(v) AK2.cooldown=math.clamp(v,0.05,2.0) end})
    ak2l:AddSlider({Text="Head Y Offset",Flag="ak2_head_y_offset",
        Min=0.5,Max=2.5,Default=1.5,Rounding=0.05,Suffix=" st",
        Callback=function(v) AK2.headYOffset=math.clamp(v,0.5,2.5) end})
    ak2l:AddSlider({Text="Range",Flag="ak2_range",
        Min=5,Max=30,Default=8,Rounding=1,Suffix=" st",
        Callback=function(v) AK2.range=math.clamp(v,5,30) end})
    ak2l:AddSlider({Text="Impact Delay",Flag="ak2_impact_delay",
        Min=0,Max=1,Default=0.3,Rounding=0.05,Suffix=" s",
        Callback=function(v) AK2.impactDelay=math.clamp(v,0,1) end})
    ak2l:AddButton({Text="Rescan Net",Callback=function()
        AK2._net=nil; AK2._remote=nil; AK2._netRetry=0
        task.spawn(function() AK2_findNet(); AK2_getRemote() end)
    end})

    -- ── Aura Kill V3 ──────────────────────────────────────────────────────────
    -- RINGRING position layer: ForceNextPosition + SimulatePosition +
    -- FireNextPosition + ServerPosition (impact vec) + CheckCharacterControllable
    -- Per-UID cooldown, multi-target sorted by distance.
    -- Reuses AK2_findNet / AK2_fire already defined above.
    local AK3: {[string]: any} = {
        enabled      = false,
        killAI       = true,
        killZombie   = true,
        killPlayer   = false,
        hitPart      = "Head",
        headYOffset  = 1.5,
        maxPerCycle  = 4,
        cooldown     = 0.55,
        range        = 50,
        rangeMargin  = 0.3,
        impactDelay  = 0.28,
        decoyEnabled = true,
        decoyOffset  = 3,
        _lastFire    = {},
    }
    Combat.AK3 = AK3

    local ak3DecoyConn = nil
    local ak3DecoyPos: Vector3? = nil

    local function ak3_rep()
        local svc = Combat.Service()
        return svc and svc.Replicator
    end

    -- Nhân vật đứng yên: "from" luôn là vị trí thật, không bao giờ lấy từ decoy —
    -- tránh việc frame sau đọc lại vị trí giả rồi tưởng mình đang đứng cạnh NPC vừa spoof.
    local function ak3_reportedPos()
        local rep = ak3_rep(); local a = rep and rep.LocalActor
        if a then
            local ok, pos = pcall(function() return a.Position end)
            if ok and typeof(pos) == "Vector3" then return pos end
        end
        local char = AimPlayers.LocalPlayer.Character  -- FIX: file này đặt tên AimPlayers, không phải Players
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
        if root then return root.Position end
        return nil
    end

    local function ak3_serverPos()
        local rep = ak3_rep(); local a = rep and rep.LocalActor
        if not a then return nil end
        local ok, sp = pcall(function() return a.ServerPosition end)
        if ok and typeof(sp) == "Vector3" then return sp end
        return nil
    end

    -- RINGRING: CheckCharacterControllable — guard before each fire tick
    local function ak3_isControllable()
        local rep = ak3_rep(); if not rep then return true end
        local a = rep.LocalActor; if not a then return false end
        local ok, v = pcall(function() return a:CheckCharacterControllable() end)
        if ok then return v ~= false end
        local ok2, v2 = pcall(function() return a.CharacterControllable end)
        if ok2 and v2 ~= nil then return v2 ~= false end
        return true
    end

    -- ĐÃ ĐỐI CHIẾU VỚI MTC game_tree DUMP THẬT (ReplicatorService.lua):
    -- ForceNextPosition và SimulatedPosition (có "d") là PROPERTY — set thẳng bằng "=".
    -- Không hề tồn tại hàm SimulatePosition()/FireNextPosition() nào trong game (grep 0 kết quả) —
    -- bản cũ gọi chúng như method, pcall nuốt lỗi âm thầm, không crash nhưng cũng không làm gì.
    -- ReplicatorService:Update() (chạy mỗi frame) tự đọc property này và gửi
    -- FireUnreliableServer("ReplicateMovement", ...) lên server — không cần tự "fire" gì cả.
    local function ak3_pushPos(pos)
        local rep = ak3_rep(); local a = rep and rep.LocalActor
        if not a then return end
        pcall(function() a.ForceNextPosition = pos end)
        pcall(function() a.SimulatedPosition = pos end)
    end

    local function ak3_tearDecoy()
        if ak3DecoyConn then ak3DecoyConn:Disconnect(); ak3DecoyConn = nil end
        ak3DecoyPos = nil
        local rep = ak3_rep(); local a = rep and rep.LocalActor
        if a then pcall(function() a.ForceNextPosition = nil end) end
    end

    -- Main aura loop
    table.insert(Combat.connections, AimRunService.Heartbeat:Connect(function()
        if not AK3.enabled then return end
        if not ak3_isControllable() then return end
        local net = AK2_findNet(); if not net then return end
        local rep = ak3_rep(); if not rep then return end
        local registry = rep.Actors; if not registry then return end
        local from = ak3_reportedPos(); if not from then return end
        local now = os.clock()

        local candidates = {}
        for uid, a in pairs(registry) do
            if not Combat.IsAlive(a) then continue end
            local kind = Combat.Kind(a); if not kind then continue end
            local allow = false
            if kind=="Zombies" and AK3.killZombie then allow=true end
            if kind=="NPCs"    and AK3.killAI     then allow=true end
            if kind=="Players" and AK3.killPlayer then allow=true end
            if not allow then continue end
            if (now-(AK3._lastFire[uid] or 0)) < AK3.cooldown then continue end
            local pos = a.Position
            if typeof(pos) ~= "Vector3" then continue end
            local dist = (pos - from).Magnitude
            if dist > AK3.range then continue end
            table.insert(candidates, {uid=uid, pos=pos, dist=dist})
        end
        table.sort(candidates, function(x, y) return x.dist < y.dist end)

        local fired = 0
        for _, entry in ipairs(candidates) do
            if fired >= AK3.maxPerCycle then break end
            AK3._lastFire[entry.uid] = now
            -- Push vị trí giả MỘT LẦN trước Slash — ForceNextPosition/SimulatedPosition
            -- tự bị ReplicatorService:Update() xóa sau khi gửi 1 lần lên server,
            -- không cần giữ liên tục → nhân vật không "đi theo" NPC, đứng yên tại chỗ.
            local spawnPos = entry.pos + Vector3.new(0, 0.5, 0)
            ak3_pushPos(spawnPos)
            AK2_fire(net, "InventoryAction", "Slash", math.random(1, 3))
            local uid2 = entry.uid
            local hitPos = {entry.pos.X, entry.pos.Y + AK3.headYOffset, entry.pos.Z}
            task.delay(AK3.impactDelay, function()
                if not AK3.enabled then return end
                local n2 = AK2_findNet(); if not n2 then return end
                -- Push lần 2 ngay trước Impact — đúng "Firmenexposition" xuất hiện 2 lần
                -- trong list RINGRING. Vẫn chỉ 1 lần, không lặp lại mỗi frame.
                ak3_pushPos(spawnPos)
                AK2_fire(n2, "InventoryAction", "Impact", hitPos, uid2, AK3.hitPart)
            end)
            fired += 1
        end
    end))

    -- Heartbeat RIÊNG chỉ cho decoy thủ công (nút "Drop Decoy") — không liên quan
    -- đến aura loop ở trên, vì điểm decoy thả tay cần giữ liên tục mới đứng yên được ở đó.
    table.insert(Combat.connections, AimRunService.Heartbeat:Connect(function()
        if not AK3.enabled or not AK3.decoyEnabled or not ak3DecoyPos then return end
        ak3_pushPos(ak3DecoyPos)
    end))

    -- AK3 lives on its own subtab: Mods → "Aura Kill V3"
    local ak3l = AKPage:AddSection({Title="Aura Kill V3",Side="Left"})
    local ak3r = AKPage:AddSection({Title="Decoy & Net",Side="Right"})

    ak3l:AddToggle({Text="Enable",Flag="ak3_enabled",Default=false,
        Callback=function(v) AK3.enabled=v end})
    ak3l:AddToggle({Text="Kill NPCs",Flag="ak3_kill_ai",Default=true,
        Callback=function(v) AK3.killAI=v end})
    ak3l:AddToggle({Text="Kill Zombies",Flag="ak3_kill_zombie",Default=true,
        Callback=function(v) AK3.killZombie=v end})
    ak3l:AddToggle({Text="Kill Players",Flag="ak3_kill_player",Default=false,
        Callback=function(v) AK3.killPlayer=v end})
    ak3l:AddDropdown({Text="Hit Part",Flag="ak3_hitpart",
        Options={"Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"},
        Default="Head",
        Callback=function(v) AK3.hitPart=v end})
    ak3l:AddSlider({Text="Max Targets/Tick",Flag="ak3_max_targets",
        Min=1,Max=20,Default=4,Rounding=1,Suffix="",
        Callback=function(v) AK3.maxPerCycle=math.clamp(v,1,20) end})
    ak3l:AddSlider({Text="Hit Cooldown",Flag="ak3_cooldown",
        Min=0.05,Max=2.0,Default=0.55,Rounding=0.05,Suffix=" s",
        Callback=function(v) AK3.cooldown=math.clamp(v,0.05,2.0) end})
    ak3l:AddSlider({Text="Range",Flag="ak3_range",
        Min=3,Max=100,Default=50,Rounding=1,Suffix=" st",
        Callback=function(v) AK3.range=math.clamp(v,3,100) end})
    ak3l:AddSlider({Text="Impact Delay",Flag="ak3_impact_delay",
        Min=0,Max=1,Default=0.28,Rounding=0.02,Suffix=" s",
        Callback=function(v) AK3.impactDelay=math.clamp(v,0,1) end})

    ak3r:AddToggle({Text="Decoy Position",Flag="ak3_decoy",Default=true,
        Callback=function(v) AK3.decoyEnabled=v; if not v then ak3_tearDecoy() end end})
    ak3r:AddSlider({Text="Decoy Offset",Flag="ak3_decoy_offset",
        Min=0,Max=10,Default=3,Rounding=0.5,Suffix=" st",
        Callback=function(v) AK3.decoyOffset=math.clamp(v,0,10) end})
    ak3r:AddButton({Text="Drop Decoy (Crosshair)",Callback=function()
        if not AK3.decoyEnabled then return end
        local cam = workspace.CurrentCamera
        local vp = cam.ViewportSize
        local ray = cam:ViewportPointToRay(vp.X/2, vp.Y/2)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ign = {cam}
        if Players.LocalPlayer.Character then table.insert(ign, Players.LocalPlayer.Character) end
        params.FilterDescendantsInstances = ign
        local r = workspace:Raycast(ray.Origin, ray.Direction*300, params)
        if r then ak3DecoyPos = r.Position + Vector3.new(0, AK3.decoyOffset, 0) end
    end})
    ak3r:AddButton({Text="Recall Decoy",Callback=function() ak3_tearDecoy() end})
    ak3r:AddButton({Text="Rescan Net",Callback=function()
        AK2._net=nil; AK2._remote=nil; AK2._netRetry=0
        task.spawn(function() AK2_findNet(); AK2_getRemote() end)
    end})

    local vp=VehiclePage
    local vl=vp:AddSection({Title="Driving",Side="Left"});local vr=vp:AddSection({Title="Flight",Side="Right"})
    toggle(vl,"Speed Mod",V,"Speed","vehicle_speed")
    slider(vl,"Speed",V,"SpeedValue","vehicle_speed_value",1,250,80,1," studs/s")
    toggle(vl,"Stability Assist",V,"Stability","vehicle_stability")
    toggle(vl,"Bounce Mode",V,"Bounce","vehicle_bounce")
    toggle(vl,"Heli Fast Startup",V,"FastStart","vehicle_heli_start")
    toggle(vr,"Vehicle Fly",V,"Fly","vehicle_fly")
    V.key=vr:AddKeyPicker({Text="Vehicle Fly Key",Flag="vehicle_fly_key",Default="None",Mode="Toggle",Callback=function() end})
    slider(vr,"Fly Speed",V,"FlySpeed","vehicle_fly_speed",1,2000,60,1," studs/s")
    toggle(vr,"Vehicle Noclip",V,"Noclip","vehicle_noclip")

    -- ── Vehicle Teleporter ─────────────────────────────────────────────────────
    local VTEL_PATH = "Tokaihub/BRM5/veh_coords.json"
    local vtel_coords = {}

    local function vtel_load()
        pcall(function()
            if isfile and isfile(VTEL_PATH) then
                local ok2, decoded = pcall(function()
                    return game:GetService("HttpService"):JSONDecode(readfile(VTEL_PATH))
                end)
                if ok2 and type(decoded) == "table" then vtel_coords = decoded end
            end
        end)
    end

    local function vtel_save()
        pcall(function()
            if not isfolder("Tokaihub") then makefolder("Tokaihub") end
            if not isfolder("Tokaihub/BRM5") then makefolder("Tokaihub/BRM5") end
            writefile(VTEL_PATH, game:GetService("HttpService"):JSONEncode(vtel_coords))
        end)
    end

    local function vtel_names()
        local names = {}
        for k in pairs(vtel_coords) do names[#names+1] = k end
        table.sort(names)
        return names
    end

    local function GetActiveVehicleController()
        local s = V.activeSolver
        if s and s._vehicle and s._vehicle.Controlling then return s end
        return nil
    end

    local function GetNetwork()
        if V._vtel_net then return V._vtel_net end
        local inspect = (debug and debug.getupvalues) or getupvalues
        if not inspect then return nil end
        local service = Combat.Service()
        local replicator = service and service.Replicator
        if replicator and type(replicator.Update) == "function" then
            local ok, values = pcall(inspect, replicator.Update)
            if ok then
                for _, value in pairs(values) do
                    if type(value) == "table" then
                        local ok2, fs = pcall(function() return value.FireServer end)
                        if ok2 and type(fs) == "function" then V._vtel_net = value; return value end
                    end
                end
            end
        end
        local vs = X.classes.VehicleSolver
        if vs then
            for _, mname in ipairs({"Update", "_integrate"}) do
                local fn = type(rawget(vs, mname)) == "function" and rawget(vs, mname)
                if fn then
                    local ok, vals = pcall(inspect, fn)
                    if ok then
                        for _, v in pairs(vals) do
                            if type(v) == "table" then
                                local ok2, fs = pcall(function() return v.FireServer end)
                                if ok2 and type(fs) == "function" then V._vtel_net = v; return v end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local function TeleportVehicle(targetPos, targetRotY)
        local net = GetNetwork()
        if not net then Library:Notify("Network Service not found!", 3); return end
        local controller = GetActiveVehicleController()
        if not controller or not controller._vehicle then Library:Notify("Get in a vehicle first!", 3); return end
        local vehicle = controller._vehicle
        local newCF
        if typeof and typeof(targetPos) == "CFrame" then
            newCF = targetPos
        elseif type(targetPos) == "userdata" and targetPos.IsA and targetPos:IsA("CFrame") then
            newCF = targetPos
        elseif type(targetPos) == "table" and targetPos.Position then
            newCF = targetPos
        else
            newCF = CFrame.new(targetPos)
            if targetRotY then newCF = newCF * CFrame.Angles(0, math.rad(targetRotY), 0) end
        end
        if vehicle.Hitbox then vehicle.Hitbox.CFrame = newCF end
        vehicle.CFrame = newCF
        local solver = controller._solver
        if solver and solver.SetState then
            solver:SetState(newCF, Vector3.new(0,0,0), Vector3.new(0,0,0), vehicle.ComponentReplicates)
        end
        local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = newCF:GetComponents()
        net:FireServer(
            "ReplicateVehicle", vehicle.UID,
            x,y,z, r00,r01,r02, r10,r11,r12, r20,r21,r22,
            vehicle.Steering or 0, vehicle.ComponentReplicates
        )
        Library:Notify("Vehicle Teleported!", 3)
    end

    vtel_load()

    local vtpSection = vp:AddSection({Title="Teleporter", Side="Left"})
    local vtpGroup = vp.Groups[#vp.Groups]  -- raw LinoriaLib groupbox (section wrapper has no AddButton)

    vtpGroup:AddDropdown("tp_saved_coords", {
        Text     = "Saved Coordinates",
        Values   = vtel_names(),
        AllowNull = true,
    })

    vtpGroup:AddButton("Get Coordinates", function()
        local controller = GetActiveVehicleController()
        if not controller or not controller._vehicle then
            Library:Notify("Get in a vehicle first!", 3)
            return
        end
        local cf = controller._vehicle.CFrame
        local idx = 1
        while vtel_coords["Coord "..idx] do idx = idx + 1 end
        local name = "Coord "..idx
        local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22 = cf:GetComponents()
        vtel_coords[name] = {x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22}
        vtel_save()
        local names = vtel_names()
        Options["tp_saved_coords"]:SetValues(names)
        Options["tp_saved_coords"]:SetValue(name)
        Library:Notify("Saved: "..name, 3)
    end)

    vtpGroup:AddButton("Teleport", function()
        local sel = Options["tp_saved_coords"].Value
        if not sel or sel == "" then
            Library:Notify("Select a coordinate first!", 3)
            return
        end
        local entry = vtel_coords[sel]
        if not entry or type(entry) ~= "table" or #entry < 12 then
            Library:Notify("Invalid coordinate data!", 3)
            return
        end
        TeleportVehicle(CFrame.new(
            entry[1],entry[2],entry[3],
            entry[4],entry[5],entry[6],
            entry[7],entry[8],entry[9],
            entry[10],entry[11],entry[12]
        ))
    end)

    vtpGroup:AddButton("Delete Coordinate", function()
        local sel = Options["tp_saved_coords"].Value
        if not sel or sel == "" then
            Library:Notify("Select a coordinate to delete!", 3)
            return
        end
        vtel_coords[sel] = nil
        vtel_save()
        local names = vtel_names()
        Options["tp_saved_coords"]:SetValues(names)
        Options["tp_saved_coords"]:SetValue(names[1])
        Library:Notify("Deleted: "..sel, 3)
    end)
    -- ───────────────────────────────────────────────────────────────────────────

    local tp=TurretPage
    local ts=tp:AddSection({Title="Turret",Side="Left"})
    toggle(ts,"Turret RPM Changer",T,"RPM","turret_rpm_enabled")
    slider(ts,"Turret RPM",T,"RPMValue","turret_rpm_value",60,3000,900,10," RPM")
    toggle(ts,"No Spread",T,"NoSpread","turret_no_spread")
    toggle(ts,"No Recoil",T,"NoRecoil","turret_no_recoil")
    local function applyGun(w)
        if localWeapon(w) then Gun.ApplyWeapon(w) end
    end
    local function applyTurret(ctrl)
        if not ctrl or type(ctrl._config)~="table" then return end
        if X.turret and X.turret~=ctrl then restore(X.turret._config) end
        X.turret=ctrl
        local c=ctrl._config
        field(c,"RPM",T.RPM,T.RPMValue);field(c,"Barrel_Spread",T.NoSpread,0)
        field(c,"Recoil_Base",T.NoRecoil,Vector2.zero);field(c,"Recoil_Range",T.NoRecoil,Vector2.zero)
    end
    local installers={}
    installers.FirearmInventory=function(c)
        Gun.firearmClass=c
        for _,method in ipairs({"_discharge","_switchFiremode"}) do
            Gun.Hook(c,method,function(original) return function(w,...)
                applyGun(w);return original(w,...)
            end end)
        end
        Gun.Hook(c,"Discharge",function(original) return function(w,...)
            if not localWeapon(w) then return original(w,...) end
            applyGun(w)
            return original(w,...)
        end end)
        Gun.Hook(c,"Equip",function(original) return function(w,...)
            applyGun(w);return original(w,...)
        end end)
    end
    installers.CharacterCamera=function(c)
        Gun.Hook(c,"Shake",function(original) return function(camera,preset,...)
            if X.active and T.NoRecoil and X.turretShot then return preset end
            return original(camera,preset,...)
        end end)
        Gun.Hook(c,"Render",function(original) return function(camera,...)
            local suppress=Gun.active and Gun.NoCameraShake
            if not suppress and not (Gun.active and Gun.SightZoom) then return original(camera,...) end
            local influences={}
            if suppress then
                for _,shake in ipairs(camera._shakes or {}) do
                    influences[#influences+1]={shake,shake.PositionInfluence,shake.RotationInfluence}
                    shake.PositionInfluence=Vector3.zero;shake.RotationInfluence=Vector3.zero
                end
            end
            local r=table.pack(pcall(original,camera,...))
            for _,v in ipairs(influences) do v[1].PositionInfluence=v[2];v[1].RotationInfluence=v[3] end
            if not r[1] then error(r[2],0) end
            local me=actor();local cam=workspace.CurrentCamera
            if Gun.active and Gun.SightZoom and me and me.ADS and cam then
                cam.FieldOfView=math.clamp(math.deg(2*math.atan(math.tan(math.rad(cam.FieldOfView)/2)/Gun.Zoom)),5,100)
            end
            return table.unpack(r,2,r.n)
        end end)
    end
    installers.TurretController=function(c)
        for _,key in ipairs({"Update","_discharge","Discharge"}) do
            Gun.Hook(c,key,function(original) return function(ctrl,...)
                applyTurret(ctrl)
                if key~="Discharge" then return original(ctrl,...) end
                local previous=X.turretShot;X.turretShot=true
                local r=table.pack(pcall(original,ctrl,...));X.turretShot=previous
                if not r[1] then error(r[2],0) end
                return table.unpack(r,2,r.n)
            end end)
        end
        Gun.Hook(c,"Destroy",function(original) return function(ctrl,...)
            restore(ctrl._config);if X.turret==ctrl then X.turret=nil end
            return original(ctrl,...)
        end end)
    end
    installers.MeleeInventory=function(c) A.class=c end
    local meleeRay=RaycastParams.new()
    meleeRay.FilterType=Enum.RaycastFilterType.Exclude
    meleeRay.IgnoreWater=false
    meleeRay.CollisionGroup="9"
    function A.Range(weapon)
        return A.Reach and A.Distance or (weapon and weapon._distance or 0)
    end
    function A.Allowed(target,me)
        local kind=Combat.Kind(target)
        return target~=me and kind and A.Targets[kind] and Combat.IsAlive(target)
            and target.Character and target.Character.Parent
            and not (kind=="Players" and Combat.IsTeammate(target))
    end
    function A.SelectTarget(me,weapon)
        if not me or not me.CFrame then return nil end
        local range=A.Range(weapon)
        if range<=0 then return nil end
        local origin=me.CFrame:PointToWorldSpace(Vector3.new(0,2.5,0))
        local camera=workspace.CurrentCamera
        local excluded={}
        if me.Character then excluded[#excluded+1]=me.Character end
        if camera then excluded[#excluded+1]=camera end
        meleeRay.FilterDescendantsInstances=excluded
        local replica=me._inventory and me._inventory[me._equipped]
        local params=replica and replica._params or meleeRay
        local service=Combat.Service()
        local replicator=service and service.Replicator
        local best,bestPart,nearest=nil,nil,range
        -- Read the actor registry directly so melee works without any firearm feature enabled.
        for _,target in pairs(replicator and replicator.Actors or {}) do
            if A.Allowed(target,me) then
                local head=target.Parts and target.Parts.Head
                if head and head.Parent then
                    local delta=Combat.PartPosition(target,head)-origin
                    local distance=delta.Magnitude
                    if distance>.001 and distance<=nearest then
                        local hit=workspace:Raycast(origin,delta,params)
                        local visible=not hit or hit.Instance:IsDescendantOf(target.Character)
                        if not visible and type(replicator.GetFromBodyPart)=="function" then
                            local uid=replicator:GetFromBodyPart(hit.Instance)
                            visible=uid==target.UID
                        end
                        if visible then best=target;bestPart=head;nearest=distance end
                    end
                end
            end
        end
        return best,bestPart
    end
    function A.PickReachDirection(self,origin,range)
        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
        local exclude={self._actor.Character}
        if workspace.CurrentCamera then exclude[#exclude+1]=workspace.CurrentCamera end
        params.FilterDescendantsInstances=exclude
        local candidates={};local known={}
        local function add(part,point,priority)
            if not part or known[part] or typeof(point)~="Vector3" then return end
            local delta=point-origin;local distance=delta.Magnitude
            if distance<.05 or distance>range then return end
            known[part]=true;candidates[#candidates+1]={part=part,delta=delta,distance=distance,priority=priority}
        end
        for _,target in ipairs(Combat.actors) do
            local kind=Combat.Kind(target)
            local friendly=kind=="Players" and target.Owner and target.Owner.Team~=nil and target.Owner.Team==AimLocalPlayer.Team
            if not friendly and Combat.IsAlive(target) then
                local part=target.Parts and target.Parts.Head
                if part and part.Parent then add(part,part.Position,0) end
            end
        end
        local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude;overlap.FilterDescendantsInstances=exclude
        for _,part in ipairs(workspace:GetPartBoundsInRadius(origin,range,overlap)) do
            if part.CanQuery and part.Transparency<1 then
                local uid,bodyActor=self.Replicator:GetFromBodyPart(part)
                if not uid and not bodyActor then
                    local half=part.Size*.5;local localPoint=part.CFrame:PointToObjectSpace(origin)
                    local nearest=part.CFrame:PointToWorldSpace(Vector3.new(math.clamp(localPoint.X,-half.X,half.X),math.clamp(localPoint.Y,-half.Y,half.Y),math.clamp(localPoint.Z,-half.Z,half.Z)))
                    -- Ignore the supporting floor; aim slightly inside the nearest surface.
                    if nearest.Y>=origin.Y-1.5 then
                        local towardCenter=part.Position-nearest
                        local inside=nearest+(towardCenter.Magnitude>.001 and towardCenter.Unit*math.min(.05,towardCenter.Magnitude) or Vector3.zero)
                        add(part,inside,1)
                    end
                end
            end
        end
        table.sort(candidates,function(a,b) if a.priority~=b.priority then return a.priority<b.priority end;return a.distance<b.distance end)
        for _,candidate in ipairs(candidates) do
            local hit=workspace:Raycast(origin,candidate.delta,params)
            if hit and hit.Instance==candidate.part then return candidate.delta end
            if hit then
                local _,wanted=self.Replicator:GetFromBodyPart(candidate.part)
                if wanted and wanted.Character and hit.Instance:IsDescendantOf(wanted.Character) then return candidate.delta end
            end
        end
        return nil
    end
    installers.MeleeInventoryReplicator=function(c)
        Gun.Hook(c,"Impact",function(original) return function(self,direction,...)
            if self._actor==actor() and A.auraActive then
                -- Recheck after the swing delay: targets can move, die or become occluded.
                local weapon=Combat.Weapon()
                if not weapon or weapon._firearm or X.meleeWeapon~=weapon then return end
                A.targetActor,A.target=A.SelectTarget(self._actor,weapon)
                if not A.target then return end
                local origin=self._actor.CFrame:PointToWorldSpace(Vector3.new(0,2.5,0))
                direction=Combat.PartPosition(A.targetActor,A.target)-origin
                local range=A.Range(weapon)
                if direction.Magnitude>range then return end
            end
            if self._actor==actor() and A.Reach and typeof(direction)=="Vector3" and direction.Magnitude>A.Distance then direction=direction.Unit*A.Distance end
            local r=table.pack(original(self,direction,...))
            if self._actor==actor() and A.auraActive then A.lastImpactUID=r[2];A.lastImpactAt=os.clock() end
            if self._actor==actor() and A.Headshot and r[2] then r[3]="Head" end
            return table.unpack(r,1,r.n)
        end end)
    end
    local function direction()
        local cam=workspace.CurrentCamera
        if not cam or Library:IsTyping() then return Vector3.zero end
        local function down(k) return AimUIS:IsKeyDown(k) and 1 or 0 end
        local d=cam.CFrame.LookVector*(down(Enum.KeyCode.W)-down(Enum.KeyCode.S))+cam.CFrame.RightVector*(down(Enum.KeyCode.D)-down(Enum.KeyCode.A))
            +Vector3.yAxis*(down(Enum.KeyCode.Space)-down(Enum.KeyCode.LeftControl))
        return d.Magnitude>1 and d.Unit or d
    end
    installers.VehicleSolver=function(c)
        Gun.Hook(c,"_integrate",function(original) return function(solver,state,dt)
            if X.active and V.flyActive and solver._vehicle and solver._vehicle.Controlling then
                local physics=solver._solver
                solver._state=state;solver:_applyState()
                physics:SetState(nil,direction()*V.FlySpeed,Vector3.zero)
                physics.Force=Vector3.zero;physics.Torque=Vector3.zero
                physics:Step(dt)
                return solver:_getState()
            end
            return original(solver,state,dt)
        end end)
        Gun.Hook(c,"Update",function(original) return function(solver,dt,inputs,...)
            local vehicle=solver._vehicle
            if not X.active or not vehicle or not vehicle.Controlling then return original(solver,dt,inputs,...) end
            V.activeSolver = solver
            local physics=solver._solver;local state=physics and physics.State
            if not state then return original(solver,dt,inputs,...) end
            local heli=vehicle.Rotors~=nil
            if heli and V.FastStart then
                for _,engine in pairs(solver.Engines or {}) do if engine:GetOn() and not engine:GetFullyOn() then engine:TimeSkip(120) end end
            end
            local cf=state.CFrame*physics.CenterOfMass:Inverse()
            local velocity=state.Velocity;local angular=state.AngularVelocity
            if V.flyActive then
                velocity=direction()*V.FlySpeed;angular=Vector3.zero
                physics:SetState(cf,velocity,angular)
            elseif V.Speed and inputs and math.abs(inputs.Throttle or 0)>.01 then
                local forward=cf.LookVector
                if not heli then forward=Vector3.new(forward.X,0,forward.Z) end
                if forward.Magnitude>.01 then
                    local desired=forward.Unit*V.SpeedValue*math.clamp(inputs.Throttle,-1,1)
                    if not heli then desired+=Vector3.yAxis*velocity.Y end
                    velocity=velocity:Lerp(desired,1-math.exp(-math.clamp(dt,0,.1)*4))
                    physics:SetState(nil,velocity,nil)
                end
            end
            if V.Stability and not heli and not V.flyActive then
                local localAV=cf:VectorToObjectSpace(angular)
                local decay=math.exp(-math.clamp(dt,0,.1)*8)
                local correction=cf.UpVector:Cross(Vector3.yAxis)*math.clamp(dt*4,0,.4)
                physics:SetState(nil,velocity,cf:VectorToWorldSpace(Vector3.new(localAV.X*decay,localAV.Y,localAV.Z*decay))+correction)
            end
            local bounce=V.bounceStates[solver]
            if V.Bounce and not bounce then
                bounce={phase=0,blend=0,wheels=setmetatable({},{__mode="k"})}
                V.bounceStates[solver]=bounce
            end
            local bounceApplied=false
            if bounce then
                local grounded=0
                for _,suspension in pairs(solver._suspensions or {}) do
                    if suspension:IsOnGround() then grounded+=1 end
                end
                local eligible=not heli and vehicle.Wheels and not V.flyActive and not V.Noclip
                    and grounded>=2 and cf.UpVector.Y>.85 and math.abs(velocity.Y)<4
                local step=math.clamp(dt,0,.1)
                bounce.phase=(bounce.phase+step*math.pi*2/1.9)%(math.pi*2)
                local target=(V.Bounce and eligible) and 1 or 0
                bounce.blend+=(target-bounce.blend)*(1-math.exp(-step*3))
                -- Vary compression and rebound timing while the native springs move the body.
                local wave=math.sin(bounce.phase+.22*math.sin(bounce.phase))
                if eligible and bounce.blend>.001 then
                    for _,suspension in pairs(solver._suspensions or {}) do
                        local params=suspension.Params
                        if params and type(params.Length)=="number" and params.Length>0 then
                            local entry=bounce.wheels[suspension]
                            if not entry or entry.original~=params then
                                entry={original=params,adjusted=setmetatable({},{__index=params})}
                                bounce.wheels[suspension]=entry
                            end
                            entry.adjusted.Length=params.Length+wave*math.min(.20,params.Length*.135)*bounce.blend
                            suspension.Params=entry.adjusted
                            bounceApplied=true
                        end
                    end
                end
                if not V.Bounce and bounce.blend<=.001 then V.bounceStates[solver]=nil end
            end
            local old=physics.CollisionCastParams
            if V.Noclip then
                if not X.emptyCast then X.emptyCast=RaycastParams.new();X.emptyCast.FilterType=Enum.RaycastFilterType.Include;X.emptyCast.FilterDescendantsInstances={} end
                physics.CollisionCastParams=X.emptyCast
            end
            local r=table.pack(pcall(original,solver,dt,inputs,...));physics.CollisionCastParams=old
            if bounceApplied then
                for suspension,entry in pairs(bounce.wheels) do
                    if suspension.Params==entry.adjusted then suspension.Params=entry.original end
                end
            end
            if not r[1] then error(r[2],0) end
            return table.unpack(r,2,r.n)
        end end)
    end
    local baseUpdate=Gun.UpdateTune
    Gun.UpdateTune=function() baseUpdate();local me=actor();applyGun(Combat.Weapon()) end
    function X.Frame()
        if not X.modulesResolved and os.clock()>=X.nextScan then
            X.nextScan=os.clock()+3
            for _,module in ipairs(getloadedmodules()) do
                local install=installers[module.Name]
                if install and not X.classes[module.Name] then
                    local ok,c=pcall(require,module)
                    if ok and type(c)=="table" then install(c);X.classes[module.Name]=c end
                end
            end
            X.modulesResolved=true
            for name in pairs(installers) do if not X.classes[name] then X.modulesResolved=false;break end end
        end
        V.flyActive=V.Fly and Combat.KeyActive(V.key,V.keyState)
        A.auraActive=A.Aura and Combat.KeyActive(A.key,A.keyState)
        local me=actor();local w=Combat.Weapon()
        if X.meleeWeapon~=w then
            if X.meleeWeapon then restore(X.meleeWeapon);if X.autoSwing then X.meleeWeapon._swinging=false end end
            X.meleeWeapon=w;X.autoSwing=false;A.target=nil;A.targetActor=nil;A.nextTargetScan=0
        end
        if w and not w._firearm and type(w._distance)=="number" then
            field(w,"_distance",A.Reach,A.Distance)
            if A.auraActive and A.class and me and not me.Locked and not me.Sprinting then
                if os.clock()>=A.nextTargetScan then
                    A.nextTargetScan=os.clock()+.05
                    A.targetActor,A.target=A.SelectTarget(me,w)
                end
                if A.targetActor and not A.Allowed(A.targetActor,me) then A.target=nil;A.targetActor=nil end
            else A.target=nil;A.targetActor=nil;A.nextTargetScan=0 end
            if A.target and not w._looping and not A.swingPending and os.clock()>=A.nextSwing then
                A.nextSwing=os.clock()+math.max(w._timer or .5,.1);X.autoSwing=true
                A.swingPending=true
                task.spawn(function()
                    local ok,err=pcall(function()
                        if X.active and A.auraActive and A.target and Combat.Weapon()==w then A.class._use(w,true) end
                    end)
                    A.swingPending=false
                    if not ok then X.error=tostring(err);w._swinging=false;w._looping=false end
                end)
            elseif not A.target and X.autoSwing then w._swinging=false;X.autoSwing=false end
        else A.target=nil;A.targetActor=nil end
        if Gun.Debug then
            if not X.hud then
                local gui=Instance.new("ScreenGui");gui.Name="LeanGunDebug";gui.ResetOnSpawn=false;gui.Parent=AimLocalPlayer:WaitForChild("PlayerGui")
                local label=Instance.new("TextLabel");label.Size=UDim2.fromOffset(340,112);label.Position=UDim2.new(0,16,1,-140)
                label.BackgroundColor3=Color3.fromRGB(15,15,15);label.BackgroundTransparency=.2;label.TextColor3=Color3.new(1,1,1)
                label.TextSize=14;label.Font=Enum.Font.Code;label.TextXAlignment=Enum.TextXAlignment.Left;label.Parent=gui
                X.hud=gui;X.label=label
            end
            X.hud.Enabled=true
            local tune=w and w._firearm and w._firearm.Tune
            X.label.Text=string.format(" Gun: %s\n RPM: %s | Spread: %s\n Ammo: %s | Reloading: %s\n %s",tostring(w and w.Name or "none"),tostring(tune and tune.RPM or "-"),tostring(tune and tune.Barrel_Spread or "-"),tostring(w and w._mag and w._mag.Capacity or "-"),tostring(w and w._reloading or false),tostring(Gun.reloadError or X.error or "ready"))
        elseif X.hud then X.hud.Enabled=false end
    end
    local oldDestroy=Combat.Destroy
    Combat.Destroy=function()
        X.active=false
        if X.autoSwing and X.meleeWeapon then X.meleeWeapon._swinging=false end
        for object in pairs(X.saved) do restore(object) end
        if X.hud then X.hud:Destroy() end
        oldDestroy()
    end
    table.insert(Combat.connections,AimRunService.RenderStepped:Connect(function()
        if X.active then local ok,err=pcall(X.Frame);if not ok then X.error=tostring(err) end end
    end))
end

table.insert(Combat.connections,AimRunService.RenderStepped:Connect(function()
    if Gun.active then Gun.Resolve();Gun.UpdateTune();Gun.UpdateVisuals() end
end))


do
local WMLighting = game:GetService("Lighting")
local VisualsPage = legacyPage(Tabs.Mods, modPages, 'World Mods')
-- Track the Linoria rows belonging to each conditional control.
-- group.Container is a LinoriaLib-internal Frame reference gen3's groupboxes
-- don't expose, so this row-diffing enhancement only wires up when it's
-- present; without it, World Mods sections still build and work fully, just
-- without the preset-driven per-control show/hide (wm_setVisible below
-- already no-ops safely when control.SetVisible was never set).
local addWorldSection = VisualsPage.AddSection
VisualsPage.AddSection = function(self, info)
    local section = addWorldSection(self, info)
    local group = self.Groups[#self.Groups]
    if not group.Container then return section end
    for _, method in ipairs({ 'AddSlider', 'AddDropdown' }) do
        local addControl = section[method]
        section[method] = function(_, data)
            local previous = {}
            for _, child in ipairs(group.Container:GetChildren()) do previous[child] = true end
            local control = addControl(section, data)
            local rows = {}
            for _, child in ipairs(group.Container:GetChildren()) do
                if not previous[child] and child:IsA('GuiObject') then table.insert(rows, child) end
            end
            control.SetVisible = function(visible)
                if not visible and control.CloseDropdown then control:CloseDropdown() end
                for _, row in ipairs(rows) do row.Visible = visible end
                group:Resize()
            end
            return control
        end
    end
    return section
end

local function wm_setVisible(control, visible)
    if not control then return end
    if control.SetVisible then control.SetVisible(visible)
    elseif control.DisplayFrame then control.DisplayFrame.Visible = visible end
end

-- Snapshot the game's original lighting so each toggle can restore on disable.
local WMBackup = {
    Ambient = WMLighting.Ambient, OutdoorAmbient = WMLighting.OutdoorAmbient,
    ColorShift_Top = WMLighting.ColorShift_Top, ColorShift_Bottom = WMLighting.ColorShift_Bottom,
    ClockTime = WMLighting.ClockTime,
    FogStart = WMLighting.FogStart, FogEnd = WMLighting.FogEnd, FogColor = WMLighting.FogColor,
    Brightness = WMLighting.Brightness, ExposureCompensation = WMLighting.ExposureCompensation,
    EnvironmentDiffuseScale = WMLighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = WMLighting.EnvironmentSpecularScale,
    GlobalShadows = WMLighting.GlobalShadows, ShadowSoftness = WMLighting.ShadowSoftness,
}

local WM: {[string]: any} = {
    ambient    = { enabled = false, a = WMLighting.Ambient, b = WMLighting.OutdoorAmbient },
    colorShift = { enabled = false, top = WMLighting.ColorShift_Top, bottom = WMLighting.ColorShift_Bottom },
    time       = { enabled = false, value = WMLighting.ClockTime },
    fog        = { enabled = false, s = WMLighting.FogStart, e = WMLighting.FogEnd, color = WMLighting.FogColor },
    light      = { enabled = false, brightness = WMLighting.Brightness, exposure = WMLighting.ExposureCompensation,
                   diffuse = WMLighting.EnvironmentDiffuseScale, specular = WMLighting.EnvironmentSpecularScale },
    shadows    = { enabled = false, softness = WMLighting.ShadowSoftness, tech = "ShadowMap" },
    fullbright = { enabled = false, saved = nil },
}


local Booster={enabled=false,records={},seen={},queue={},cursor=1,restoring=false}
WM.Booster=Booster
function Booster.Save(object,property,value,hidden)
    if hidden and (type(gethiddenproperty)~="function" or type(sethiddenproperty)~="function") then return end
    local ok,old=pcall(function()
        if hidden then return gethiddenproperty(object,property) end
        return object[property]
    end)
    if not ok or old==value or (hidden and old==nil) then return end
    local written,changed=pcall(function()
        if hidden then return sethiddenproperty(object,property,value)~=nil end
        object[property]=value
        return true
    end)
    if not written or not changed then return end
    -- Keep restoration data only for properties that were actually changed.
    local record=Booster.seen[object]
    if not record then
        record={object=object,values={}}
        Booster.seen[object]=record
        table.insert(Booster.records,record)
    end
    if record.values[property]==nil then
        record.values[property]=old
        if hidden then
            record.hidden=record.hidden or {}
            record.hidden[property]=true
        end
    end
end
function Booster.Process(object)
    if object:IsA("Terrain") then return end
    if object:IsA("BasePart") then
        Booster.Save(object,"Material",Enum.Material.SmoothPlastic)
        Booster.Save(object,"MaterialVariant","")
        Booster.Save(object,"Reflectance",0)
        Booster.Save(object,"CastShadow",false)
        if object:IsA("MeshPart") then
            Booster.Save(object,"TextureID","")
            Booster.Save(object,"RenderFidelity",Enum.RenderFidelity.Performance)
        end
    elseif object:IsA("Decal") or object:IsA("Texture") then
        Booster.Save(object,"Transparency",1)
    elseif object:IsA("SpecialMesh") then
        Booster.Save(object,"TextureId","")
    elseif object:IsA("SurfaceAppearance") then
        Booster.Save(object,"Parent",nil)
    elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
        or object:IsA("Smoke") or object:IsA("Fire") or object:IsA("Sparkles") or object:IsA("PostEffect") then
        Booster.Save(object,"Enabled",false)
    elseif object:IsA("Light") then
        Booster.Save(object,"Shadows",false)
    end
end
function Booster.Scan()
    Booster.queue=workspace:GetDescendants()
    for _,object in ipairs(WMLighting:GetDescendants()) do table.insert(Booster.queue,object) end
    Booster.cursor=1
    -- Terrain decoration controls the procedural grass, including streamed terrain.
    Booster.Save(workspace.Terrain,"Decoration",false,true)
    Booster.Save(workspace.Terrain,"WaterWaveSize",0)
    Booster.Save(workspace.Terrain,"WaterWaveSpeed",0)
    Booster.Save(workspace.Terrain,"WaterReflectance",0)
    Booster.Save(workspace.Terrain,"WaterTransparency",1)
end
function Booster.SetEnabled(enabled)
    if enabled==Booster.enabled then return end
    Booster.enabled=enabled
    if not enabled then
        Booster.restoring=true
        WMLighting.GlobalShadows=WMBackup.GlobalShadows
        WMLighting.FogStart=WMBackup.FogStart;WMLighting.FogEnd=WMBackup.FogEnd
        table.clear(Booster.queue);Booster.cursor=1
    elseif not Booster.restoring then Booster.Scan() end
    WM.SyncAtmosphere()
    WM.Apply()
end
function Booster.RestoreOne()
    local record=table.remove(Booster.records)
    if not record then return false end
    for property,value in pairs(record.values) do
        pcall(function()
            if record.hidden and record.hidden[property] then sethiddenproperty(record.object,property,value)
            else record.object[property]=value end
        end)
    end
    Booster.seen[record.object]=nil
    return true
end
function Booster.Step()
    if not Booster.restoring and (not Booster.enabled or #Booster.queue==0) then return end
    local deadline=os.clock()+.002
    for _=1,120 do
        if Booster.restoring then
            if not Booster.RestoreOne() then
                Booster.restoring=false
                if Booster.enabled then Booster.Scan() end
                break
            end
        elseif Booster.enabled then
            local object=Booster.queue[Booster.cursor]
            if not object then table.clear(Booster.queue);Booster.cursor=1;break end
            Booster.queue[Booster.cursor]=false;Booster.cursor+=1
            if object.Parent then Booster.Process(object) end
        else break end
        if os.clock()>=deadline then break end
    end
end
local function queueVisual(object)
    if Booster.enabled and not Booster.restoring then table.insert(Booster.queue,object) end
end
table.insert(Combat.connections,workspace.DescendantAdded:Connect(queueVisual))
table.insert(Combat.connections,WMLighting.DescendantAdded:Connect(queueVisual))
table.insert(Combat.connections,AimRunService.Heartbeat:Connect(Booster.Step))
WM.atmospheres={}
function WM.SyncAtmosphere()
    if WM.fog.enabled or Booster.enabled then
        for _,object in ipairs(WMLighting:GetChildren()) do
            if object:IsA("Atmosphere") then
                WM.atmospheres[object]=WMLighting
                object.Parent=nil
            end
        end
    else
        for object,parent in pairs(WM.atmospheres) do
            pcall(function() if object.Parent==nil then object.Parent=parent end end)
            WM.atmospheres[object]=nil
        end
    end
end
table.insert(Combat.connections,WMLighting.ChildAdded:Connect(function(object)
    if object:IsA("Atmosphere") and (WM.fog.enabled or Booster.enabled) then
        task.defer(function()
            if Combat.active then WM.SyncAtmosphere() end
        end)
    end
end))

local fullbrightValues = {
    Ambient = Color3.new(1, 1, 1), OutdoorAmbient = Color3.new(1, 1, 1),
    Brightness = 2, ExposureCompensation = 0, GlobalShadows = false,
}
function WM.RestoreFullbright()
    if not WM.fullbright.saved then return end
    for property, value in pairs(WM.fullbright.saved) do WMLighting[property] = value end
    WM.fullbright.saved = nil
end

-- Reapply enabled groups every frame so the game can't overwrite them.
function WM.Apply()
    if WM.ambient.enabled then
        WMLighting.Ambient = WM.ambient.a
        WMLighting.OutdoorAmbient = WM.ambient.b
    end
    if WM.colorShift.enabled then
        WMLighting.ColorShift_Top = WM.colorShift.top
        WMLighting.ColorShift_Bottom = WM.colorShift.bottom
    end
    if WM.time.enabled then
        WMLighting.ClockTime = WM.time.value
    end
    if WM.fog.enabled then
        WMLighting.FogStart = math.max(0,math.min(WM.fog.s,WM.fog.e-1))
        WMLighting.FogEnd = math.max(1,WM.fog.e)
        WMLighting.FogColor = WM.fog.color
    end
    if WM.light.enabled then
        WMLighting.Brightness = WM.light.brightness
        WMLighting.ExposureCompensation = WM.light.exposure
        WMLighting.EnvironmentDiffuseScale = WM.light.diffuse
        WMLighting.EnvironmentSpecularScale = WM.light.specular
    end
    if WM.shadows.enabled then
        WMLighting.GlobalShadows = true
        WMLighting.ShadowSoftness = WM.shadows.softness
    end
    if WM.fullbright.enabled then
        for property, value in pairs(fullbrightValues) do
            if WMLighting[property] ~= value then WMLighting[property] = value end
        end
    end
    if Booster.enabled then
        WMLighting.GlobalShadows=false
        WMLighting.FogStart=1000000
        WMLighting.FogEnd=1000000
    end
end
table.insert(Combat.connections, AimRunService.RenderStepped:Connect(WM.Apply))

-- ── World ─────────────────────────────────────────────────────
local WMWorld = VisualsPage:AddSection({ Title = "World", Side = "Left" })
WMWorld:AddToggle({Text="FPS Booster",Flag="wm_fps_booster",Default=false,Callback=Booster.SetEnabled})

WMWorld:AddToggle({
    Text = "Custom Ambient",
    Flag = "wm_ambient",
    Default = false,
    Callback = function(v)
        WM.ambient.enabled = v
        if not v then
            WMLighting.Ambient = WMBackup.Ambient
            WMLighting.OutdoorAmbient = WMBackup.OutdoorAmbient
        end
    end
})
WMWorld:AddColorPicker({
    Text = "Ambient",
    Flag = "wm_ambient_a",
    Default = WM.ambient.a,
    Callback = function(c) WM.ambient.a = c end
})
WMWorld:AddColorPicker({
    Text = "Outdoor Ambient",
    Flag = "wm_ambient_b",
    Default = WM.ambient.b,
    Callback = function(c) WM.ambient.b = c end
})

WMWorld:AddToggle({
    Text = "Custom Color Shift",
    Flag = "wm_colorshift",
    Default = false,
    Callback = function(v)
        WM.colorShift.enabled = v
        if not v then
            WMLighting.ColorShift_Top = WMBackup.ColorShift_Top
            WMLighting.ColorShift_Bottom = WMBackup.ColorShift_Bottom
        end
    end
})
WMWorld:AddColorPicker({
    Text = "Color Shift Top",
    Flag = "wm_colorshift_top",
    Default = WM.colorShift.top,
    Callback = function(c) WM.colorShift.top = c end
})
WMWorld:AddColorPicker({
    Text = "Color Shift Bottom",
    Flag = "wm_colorshift_bottom",
    Default = WM.colorShift.bottom,
    Callback = function(c) WM.colorShift.bottom = c end
})

local wmTimeSlider
WMWorld:AddToggle({
    Text = "Custom World Time",
    Flag = "wm_time",
    Default = false,
    Callback = function(v)
        WM.time.enabled = v
        wm_setVisible(wmTimeSlider, v)
        if not v then WMLighting.ClockTime = WMBackup.ClockTime end
    end
})
wmTimeSlider = WMWorld:AddSlider({
    Text = "World Time",
    Flag = "wm_time_value",
    Min = 0, Max = 24, Rounding = 1, Default = 14,
    Callback = function(v) WM.time.value = v end
})
wm_setVisible(wmTimeSlider, false)

local wmFogStart, wmFogEnd, wmFogColor
WMWorld:AddToggle({
    Text = "Custom Fog",
    Flag = "wm_fog",
    Default = false,
    Callback = function(v)
        WM.fog.enabled = v
        WM.SyncAtmosphere()
        wm_setVisible(wmFogStart, v)
        wm_setVisible(wmFogEnd, v)
        wm_setVisible(wmFogColor, v)
        if not v then
            WMLighting.FogStart = WMBackup.FogStart
            WMLighting.FogEnd = WMBackup.FogEnd
            WMLighting.FogColor = WMBackup.FogColor
        end
    end
})
wmFogStart = WMWorld:AddSlider({
    Text = "Fog Start",
    Flag = "wm_fog_start",
    Min = 0, Max = 5000, Rounding = 1, Default = 0,
    Callback = function(v) WM.fog.s = v;WM.Apply() end
})
wmFogEnd = WMWorld:AddSlider({
    Text = "Fog End",
    Flag = "wm_fog_end",
    Min = 0, Max = 10000, Rounding = 1, Default = 1000,
    Callback = function(v) WM.fog.e = v;WM.Apply() end
})
wmFogColor = WMWorld:AddColorPicker({
    Text = "Fog Color",
    Flag = "wm_fog_color",
    Default = WM.fog.color,
    Callback = function(c) WM.fog.color = c end
})
wm_setVisible(wmFogStart, false)
wm_setVisible(wmFogEnd, false)
wm_setVisible(wmFogColor, false)

-- ── Lighting ──────────────────────────────────────────────────
local WMLight = VisualsPage:AddSection({ Title = "Lighting", Side = "Right" })

WMLight:AddToggle({
    Text = "Fullbright", Flag = "wm_fullbright", Default = false,
    Callback = function(enabled)
        if WM.fullbright.enabled == enabled then return end
        if enabled then
            local saved = {}
            for property in pairs(fullbrightValues) do saved[property] = WMLighting[property] end
            WM.fullbright.saved = saved
        else
            WM.RestoreFullbright()
        end
        WM.fullbright.enabled = enabled
        WM.Apply()
    end,
})

local wmBrightness, wmExposure, wmDiffuse, wmSpecular
WMLight:AddToggle({
    Text = "Custom Lighting",
    Flag = "wm_light",
    Default = false,
    Callback = function(v)
        WM.light.enabled = v
        wm_setVisible(wmBrightness, v)
        wm_setVisible(wmExposure, v)
        wm_setVisible(wmDiffuse, v)
        wm_setVisible(wmSpecular, v)
        if not v then
            WMLighting.Brightness = WMBackup.Brightness
            WMLighting.ExposureCompensation = WMBackup.ExposureCompensation
            WMLighting.EnvironmentDiffuseScale = WMBackup.EnvironmentDiffuseScale
            WMLighting.EnvironmentSpecularScale = WMBackup.EnvironmentSpecularScale
        end
    end
})
wmBrightness = WMLight:AddSlider({
    Text = "World Brightness",
    Flag = "wm_brightness",
    Min = 0, Max = 10, Rounding = .01, Default = WM.light.brightness,
    Callback = function(v) WM.light.brightness = v end
})
wmExposure = WMLight:AddSlider({
    Text = "Exposure Compensation",
    Flag = "wm_exposure",
    Min = -5, Max = 5, Rounding = .01, Default = WM.light.exposure,
    Callback = function(v) WM.light.exposure = v end
})
wmDiffuse = WMLight:AddSlider({
    Text = "Environment Diffuse",
    Flag = "wm_diffuse",
    Min = 0, Max = 1, Rounding = .01, Default = WM.light.diffuse,
    Callback = function(v) WM.light.diffuse = v end
})
wmSpecular = WMLight:AddSlider({
    Text = "Environment Specular",
    Flag = "wm_specular",
    Min = 0, Max = 1, Rounding = .01, Default = WM.light.specular,
    Callback = function(v) WM.light.specular = v end
})
wm_setVisible(wmBrightness, false)
wm_setVisible(wmExposure, false)
wm_setVisible(wmDiffuse, false)
wm_setVisible(wmSpecular, false)

-- ── Graphics ──────────────────────────────────────────────────
local WMGraphics = VisualsPage:AddSection({ Title = "Graphics", Side = "Right" })

local wmShadowSoftness, wmTechDropdown
WMGraphics:AddToggle({
    Text = "Global Shadows",
    Flag = "wm_shadows",
    Default = false,
    Callback = function(v)
        WM.shadows.enabled = v
        wm_setVisible(wmShadowSoftness, v)
        wm_setVisible(wmTechDropdown, v)
        if v then
            WMLighting.GlobalShadows = true
            WMLighting.ShadowSoftness = WM.shadows.softness
            pcall(function() WMLighting.Technology = Enum.Technology[WM.shadows.tech] end)
        else
            WMLighting.GlobalShadows = WMBackup.GlobalShadows
            WMLighting.ShadowSoftness = WMBackup.ShadowSoftness
        end
    end
})
wmShadowSoftness = WMGraphics:AddSlider({
    Text = "Shadow Softness",
    Flag = "wm_shadow_softness",
    Min = 0, Max = 1, Rounding = .01, Default = WM.shadows.softness,
    Callback = function(v)
        WM.shadows.softness = v
        if WM.shadows.enabled then WMLighting.ShadowSoftness = v end
    end
})
wmTechDropdown = WMGraphics:AddDropdown({
    Text = "Graphics Technology",
    Flag = "wm_tech",
    Options = {"ShadowMap", "Unified", "Future", "Voxel", "Compatibility"},
    Default = "ShadowMap",
    Callback = function(v)
        WM.shadows.tech = v
        if WM.shadows.enabled then
            pcall(function() WMLighting.Technology = Enum.Technology[v] end)
        end
    end
})
wm_setVisible(wmShadowSoftness, false)
wm_setVisible(wmTechDropdown, false)


Combat.World = WM
local destroyBeforeWorld = Combat.Destroy
Combat.Destroy = function()
    Booster.enabled=false
    while Booster.RestoreOne() do end
    Booster.restoring=false
    WM.fog.enabled=false
    WM.SyncAtmosphere()
    WMLighting.FogStart=WMBackup.FogStart
    WMLighting.FogEnd=WMBackup.FogEnd
    WM.fullbright.enabled = false
    WM.RestoreFullbright()
    WMLighting.GlobalShadows=WMBackup.GlobalShadows
    local groups = {
        ambient = { 'Ambient', 'OutdoorAmbient' },
        colorShift = { 'ColorShift_Top', 'ColorShift_Bottom' },
        time = { 'ClockTime' },
        fog = { 'FogStart', 'FogEnd', 'FogColor' },
        light = { 'Brightness', 'ExposureCompensation', 'EnvironmentDiffuseScale', 'EnvironmentSpecularScale' },
        shadows = { 'GlobalShadows', 'ShadowSoftness' },
    }
    for name, properties in pairs(groups) do
        if WM[name].enabled then
            WM[name].enabled = false
            for _, property in ipairs(properties) do WMLighting[property] = WMBackup[property] end
        end
    end
    destroyBeforeWorld()
end

end

do
    -- Third Person Unlock — right side of the existing Movement page
    local CharSec=movementPages[1]:AddSection({Title="Character",Side="Right"})
    local tpEnabled=false
    CharSec:AddToggle({Text="Third Person Unlock",Flag="thirdperson_enabled",Default=false,
        Callback=function(v)
            tpEnabled=v
            if v then
                task.spawn(function()
                    while tpEnabled do
                        pcall(function()
                            for _,t in ipairs(getgc(true)) do
                                if type(t)=="table" and rawget(t,"FIRST_PERSON")~=nil then
                                    t.FIRST_PERSON=false
                                end
                            end
                        end)
                        task.wait(0.8)
                    end
                end)
            end
        end})
end

addSubtabs('Movement', movementPages)
addSubtabs('Mods', modPages)
end

table.insert(Combat.connections, AimRunService.RenderStepped:Connect(Combat.Frame))

-- Keep overlay visibility independent from text and performance updates.
local OverlaySettings={Watermark=true,Keybinds=true}
local watermark,label=Library.Watermark,Library.WatermarkText
local function refineOverlay(frame)
    frame.BorderSizePixel=0
    frame.BackgroundColor3=Library.MainColor
    Library:AddToRegistry(frame,{BackgroundColor3="MainColor"},true)
    local corner=frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,3);corner.Parent=frame
    local stroke=frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Color=Library.OutlineColor;stroke.Thickness=1;stroke.Transparency=.1;stroke.Parent=frame
    Library:AddToRegistry(stroke,{Color="OutlineColor"},true)
    for _,child in ipairs(frame:GetChildren()) do
        if child:IsA("Frame") then
            child.BorderSizePixel=0
            child.BackgroundColor3=Library.MainColor
            Library:AddToRegistry(child,{BackgroundColor3="MainColor"},true)
            local innerCorner=child:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
            innerCorner.CornerRadius=UDim.new(0,2);innerCorner.Parent=child
        end
    end
end
refineOverlay(watermark)
watermark.Size=UDim2.fromOffset(220,28)
label.Position=UDim2.fromOffset(12,0)
label.Size=UDim2.new(1,-24,1,0)
label.TextSize=15
label.TextScaled=false
label.TextWrapped=false
label.TextStrokeTransparency=1
label.TextYAlignment=Enum.TextYAlignment.Center
for _,child in ipairs(watermark:GetDescendants()) do
    if child:IsA("UIGradient") then
        child.Enabled=false
        local background=child.Parent
        if background:IsA("Frame") then
            background.BackgroundColor3=Library.MainColor
            Library:AddToRegistry(background,{BackgroundColor3="MainColor"})
        end
    end
end
local watermarkAccent=Library:Create("Frame",{Name="WatermarkAccent",BorderSizePixel=0,
    Position=UDim2.fromOffset(12,0),Size=UDim2.fromOffset(24,2),
    BackgroundColor3=Library.AccentColor,ZIndex=label.ZIndex+1,Parent=watermark})
Library:AddToRegistry(watermarkAccent,{BackgroundColor3="AccentColor"},true)
local function resizeWatermark()
    watermark.Size=UDim2.fromOffset(math.max(120,math.ceil(label.TextBounds.X)+28),28)
end
Library:SetWatermarkVisibility(true)
Library.KeybindFrame.Visible=true
Library.SetWatermark=function(_,text)
    if label.Text~=text then label.Text=text end
    resizeWatermark()
end
table.insert(Combat.connections,label:GetPropertyChangedSignal("TextBounds"):Connect(resizeWatermark))
local elapsed,frames=0,0
local stats: any=game:GetService("Stats")
Library:SetWatermark("Tokaihub | -- fps | -- ms")
local WatermarkConnection=AimRunService.RenderStepped:Connect(function(dt)
    elapsed+=dt;frames+=1
    if elapsed<.5 then return end
    local fps=math.floor(frames/math.max(elapsed,.001)+.5)
    elapsed=0;frames=0
    local ok,ping=pcall(function() return stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    local pingText=ok and type(ping)=="number" and string.format("%d",math.floor(ping+.5)) or "--"
    Library:SetWatermark(string.format("Tokaihub | %d fps | %s ms",fps,pingText))
end)

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    Combat.Destroy()

    print('Unloaded!')
    Library.Unloaded = true
end)

-- UI Settings
local FontGroup = Tabs['UI Settings']:AddLeftGroupbox('Fonts')
FontGroup:AddDropdown('ui_font', { Text = 'UI Font', Values = Fonts.Names, Default = 'Code' }):OnChanged(function(name)
    local ok, err = pcall(Fonts.SetUI, name)
    if not ok then
        Library:Notify('Font could not be loaded: ' .. tostring(name))
        warn('[Fonts] ' .. tostring(err))
        if Options.ui_font.Value ~= Fonts.UIName then Options.ui_font:SetValue(Fonts.UIName) end
    end
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddToggle('ui_keybinds_visible',{Text='Keybinds',Default=true}):OnChanged(function(v)
    OverlaySettings.Keybinds=v
    Library.KeybindFrame.Visible=v
end)
MenuGroup:AddToggle('ui_watermark_visible',{Text='Watermark',Default=true}):OnChanged(function(v)
    OverlaySettings.Watermark=v
    Library:SetWatermarkVisibility(v)
end)

-- I set NoUI so it does not show up in the keybinds menu
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'None', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder('Tokaihub')
SaveManager:SetFolder('Tokaihub/BRM5')

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs['UI Settings'])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- Retain Linoria's keybind rows while giving the overlay consistent padding.
local keybindFrame,keybindContainer=Library.KeybindFrame,Library.KeybindContainer
refineOverlay(keybindFrame)
local keybindInner=keybindContainer.Parent
for _,child in ipairs(keybindInner:GetChildren()) do
    if child:IsA("TextLabel") then
        child.Position=UDim2.fromOffset(10,3)
        child.Size=UDim2.new(1,-20,0,22)
        child.TextSize=14;child.TextStrokeTransparency=1
        child.TextYAlignment=Enum.TextYAlignment.Center
    elseif child:IsA("Frame") and child~=keybindContainer and child.Size.Y.Offset==2 then
        child.Position=UDim2.fromOffset(10,0)
        child.Size=UDim2.fromOffset(24,2)
    end
end
keybindContainer.Position=UDim2.fromOffset(0,29)
keybindContainer.Size=UDim2.new(1,0,1,-35)
local keybindPadding=keybindContainer:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
keybindPadding.PaddingLeft=UDim.new(0,10);keybindPadding.PaddingRight=UDim.new(0,10)
keybindPadding.Parent=keybindContainer
local function resizeKeybinds()
    local height,width=0,190
    for _,row in ipairs(keybindContainer:GetChildren()) do
        if row:IsA("TextLabel") and row.Visible then
            height+=20;width=math.max(width,math.ceil(row.TextBounds.X)+24)
        end
    end
    keybindFrame.Size=UDim2.fromOffset(width,math.max(36,height+35))
end
local function styleKeybindRow(row)
    if not row:IsA("TextLabel") then return end
    row.Size=UDim2.new(1,0,0,20);row.TextSize=13
    row.TextWrapped=false;row.TextScaled=false;row.TextStrokeTransparency=1
    row.TextYAlignment=Enum.TextYAlignment.Center
    Library:GiveSignal(row:GetPropertyChangedSignal("TextBounds"):Connect(resizeKeybinds))
    Library:GiveSignal(row:GetPropertyChangedSignal("Visible"):Connect(resizeKeybinds))
end
for _,row in ipairs(keybindContainer:GetChildren()) do styleKeybindRow(row) end
Library:GiveSignal(keybindContainer.ChildAdded:Connect(function(row)
    styleKeybindRow(row);resizeKeybinds()
end))
for _,picker in pairs(Options) do
    if picker.Type=="KeyPicker" then
        local update=picker.Update
        picker.Update=function(self,...)
            local result=table.pack(update(self,...))
            resizeKeybinds()
            return table.unpack(result,1,result.n)
        end
    end
end
resizeKeybinds()

-- You can use SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
for _,picker in pairs(Options) do
    if picker.Type=="KeyPicker" then
        local getState=picker.GetState
        picker.GetState=function(self)
            return not Library:IsTyping() and getState(self)
        end
        if picker.DoClick then
            local click=picker.DoClick
            picker.DoClick=function(self,...)
                if Library:IsTyping() then self.Toggled=not self.Toggled;return end
                return click(self,...)
            end
        end
    end
end
SaveManager:LoadAutoloadConfig()
-- Migrate the previous mouse defaults when loading an older configuration.
for _, id in ipairs({ 'silent_key', 'trigger_key', 'rage_key' }) do
    local picker = Options[id]
    if picker.Value == 'MB2' then picker:SetValue({ 'None', picker.Mode }) end
end
Combat.ESP.Load()
