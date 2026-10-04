--!strict
--[[
	LeaderstatsService

	Crea la carpeta `leaderstats` de cada jugador y es el ÚNICO punto que
	modifica sus estadísticas. El resto de servicios llama a AddCoins/GetCoins
	en vez de tocar los IntValue directamente.

	Estructura creada:
	  Player
	  └── leaderstats (Folder)
	      └── Coins (IntValue)

	Futuro: cuando se añada DataStore, la carga/guardado vivirá en un
	PlayerDataService y este servicio solo reflejará los valores en pantalla.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local LEADERSTATS_NAME = "leaderstats" -- Nombre exigido por Roblox para el leaderboard.
local COINS_NAME = "Coins"

local LeaderstatsService = {}

local function getCoinsValue(player: Player): IntValue?
	local leaderstats = player:FindFirstChild(LEADERSTATS_NAME)
	if not leaderstats then
		return nil
	end
	local coins = leaderstats:FindFirstChild(COINS_NAME)
	if coins and coins:IsA("IntValue") then
		return coins
	end
	return nil
end

local function createLeaderstats(player: Player)
	if player:FindFirstChild(LEADERSTATS_NAME) then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = LEADERSTATS_NAME

	local coins = Instance.new("IntValue")
	coins.Name = COINS_NAME
	coins.Value = Config.StartingCoins
	coins.Parent = leaderstats

	-- Se asigna el Parent al final para que el cliente reciba la estructura completa.
	leaderstats.Parent = player
end

--[[
	Suma `amount` monedas al jugador. Solo debe llamarse desde el servidor.
	Devuelve true si se aplicó.
]]
function LeaderstatsService:AddCoins(player: Player, amount: number): boolean
	local coins = getCoinsValue(player)
	if not coins then
		return false
	end
	coins.Value += amount
	return true
end

function LeaderstatsService:GetCoins(player: Player): number
	local coins = getCoinsValue(player)
	return if coins then coins.Value else 0
end

function LeaderstatsService:Start()
	Players.PlayerAdded:Connect(createLeaderstats)

	-- Cubre a jugadores que entraron antes de que este servicio arrancara
	-- (habitual en Play Solo dentro de Studio).
	for _, player in Players:GetPlayers() do
		createLeaderstats(player)
	end
end

return LeaderstatsService
