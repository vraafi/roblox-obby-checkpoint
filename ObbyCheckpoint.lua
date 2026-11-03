--!strict
-- Obby Checkpoint System
-- ModuleScript returns table with .new(config)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

type Config = {
	checkpointTag: string?,
	respawnDelay: number?,
	antiSkip: boolean?,
	spawnPartName: string?,
	debug: boolean?,
}

type PlayerData = {
	checkpointNumber: number,
	spawnCFrame: CFrame?,
	connections: {RBXScriptConnection},
}

local ObbyCheckpoint = {}
ObbyCheckpoint.__index = ObbyCheckpoint

local DEFAULT_CONFIG: Config = {
	checkpointTag = "Checkpoint",
	respawnDelay = 0.5,
	antiSkip = true,
	spawnPartName = "SpawnLocation",
	debug = false,
}

function ObbyCheckpoint.new(config: Config?)
	local self = setmetatable({}, ObbyCheckpoint)
	self._config = table.clone(DEFAULT_CONFIG)
	if config then
		for k, v in pairs(config) do
			self._config[k] = v
		end
	end
	self._playerData = {}
	self._connections = {}
	self._destroyed = false

	self:_setupPlayerAdded()
	self:_setupCharacterAdded()

	-- Handle players already in game
	for _, player in ipairs(Players:GetPlayers()) do
		self:_onPlayerAdded(player)
	end

	return self
end

function ObbyCheckpoint:_debugPrint(...)
	if self._config.debug then
		print("[ObbyCheckpoint]", ...)
	end
end

function ObbyCheckpoint:_setupPlayerAdded()
	table.insert(self._connections, Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end))
	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end))
end

function ObbyCheckpoint:_setupCharacterAdded()
	-- CharacterAdded is handled per-player in _onPlayerAdded
end

function ObbyCheckpoint:_onPlayerAdded(player: Player)
	if self._destroyed then return end
	if self._playerData[player] then return end

	local data: PlayerData = {
		checkpointNumber = 0,
		spawnCFrame = nil,
		connections = {},
	}
	self._playerData[player] = data

	local charConn = player.CharacterAdded:Connect(function(character)
		self:_onCharacterAdded(player, character)
	end)
	table.insert(data.connections, charConn)

	-- If character already exists
	if player.Character then
		self:_onCharacterAdded(player, player.Character)
	end

	self:_debugPrint("Player added:", player.Name)
end

function ObbyCheckpoint:_onPlayerRemoving(player: Player)
	local data = self._playerData[player]
	if not data then return end
	for _, conn in ipairs(data.connections) do
		conn:Disconnect()
	end
	data.connections = {}
	self._playerData[player] = nil
	self:_debugPrint("Player removed:", player.Name)
end

function ObbyCheckpoint:_onCharacterAdded(player: Player, character: Model)
	if self._destroyed then return end
	local data = self._playerData[player]
	if not data then return end

	-- Wait for humanoid and root part
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if not humanoid or self._destroyed then return end
		local rootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if not rootPart or self._destroyed then return end

		-- Move player to saved checkpoint if any
		if data.spawnCFrame then
			rootPart.CFrame = data.spawnCFrame + Vector3.new(0, 3, 0)
		end

		humanoid.Died:Connect(function()
			self:_onHumanoidDied(player)
		end)

		-- Detect touching checkpoints
		self:_setupCheckpointDetection(player, character)
	end)
end

function ObbyCheckpoint:_setupCheckpointDetection(player: Player, character: Model)
	local tag = self._config.checkpointTag
	if not tag then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local conn = rootPart.Touched:Connect(function(hit: BasePart)
		self:_onTouched(player, hit)
	end)
	local data = self._playerData[player]
	if data then
		table.insert(data.connections, conn)
	end
end

function ObbyCheckpoint:_onTouched(player: Player, hit: BasePart)
	if self._destroyed then return end
	local data = self._playerData[player]
	if not data then return end

	-- Check if hit part has checkpoint attribute or tag
	local checkpointNum = hit:GetAttribute("CheckpointNumber")
	if typeof(checkpointNum) ~= "number" then return end

	-- Anti-skip: must be next checkpoint in sequence
	if self._config.antiSkip then
		if checkpointNum ~= data.checkpointNumber + 1 then
			self:_debugPrint(player.Name, "skipped checkpoint", checkpointNum, "expected", data.checkpointNumber + 1)
			return
		end
	end

	-- Only accept higher checkpoint numbers
	if checkpointNum <= data.checkpointNumber then return end

	data.checkpointNumber = checkpointNum
	data.spawnCFrame = hit.CFrame
	self:_debugPrint(player.Name, "reached checkpoint", checkpointNum)
end

function ObbyCheckpoint:_onHumanoidDied(player: Player)
	if self._destroyed then return end
	local data = self._playerData[player]
	if not data then return end

	task.wait(self._config.respawnDelay or 0.5)
	if self._destroyed then return end

	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid:TakeDamage(0) -- no-op, just for safety
end

function ObbyCheckpoint:GetPlayerCheckpoint(player: Player): number
	local data = self._playerData[player]
	return data and data.checkpointNumber or 0
end

function ObbyCheckpoint:SetPlayerCheckpoint(player: Player, checkpointNumber: number)
	local data = self._playerData[player]
	if data then
		data.checkpointNumber = checkpointNumber
	end
end

function ObbyCheckpoint:Destroy()
	if self._destroyed then return end
	self._destroyed = true

	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}

	for _, data in pairs(self._playerData) do
		for _, conn in ipairs(data.connections) do
			conn:Disconnect()
		end
		data.connections = {}
	end
	self._playerData = {}

	self:_debugPrint("Destroyed")
end

return ObbyCheckpoint
