--!strict
--[[
	CoinService

	Gestiona las monedas físicas del mapa. Toda la lógica es autoritativa
	del servidor: el cliente nunca indica cuántas monedas recibe.

	Ciclo de vida de una moneda:
	  disponible --(toque válido)--> recogida (invisible, sin toque)
	             <--(CoinRespawnTime s)--

	Las monedas se detectan por el tag de CollectionService `Config.CoinTag`,
	así que basta con etiquetar cualquier Part como "Coin" (en el mapa o creada
	en tiempo de ejecución) para que funcione.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local LeaderstatsService = require(script.Parent.LeaderstatsService)

local CoinService = {}

-- Monedas actualmente recogidas (pendientes de reaparecer).
-- Actúa como cerrojo: impide que varios toques simultáneos (varias partes
-- del cuerpo o varios jugadores) entreguen la misma moneda más de una vez.
local collectedCoins: { [BasePart]: boolean } = {}

-- Transparencia original de cada moneda, para restaurarla al reaparecer.
local originalTransparency: { [BasePart]: number } = {}

local function getPlayerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return player
end

-- Comprobación de cordura: el personaje debe estar realmente cerca de la moneda.
local function isWithinPickupRange(player: Player, coin: BasePart): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - coin.Position).Magnitude <= Config.CoinPickupMaxDistance
end

local function setCoinAvailable(coin: BasePart, available: boolean)
	coin.Transparency = if available then (originalTransparency[coin] or 0) else 1
	coin.CanTouch = available
end

local function respawnCoin(coin: BasePart)
	-- La moneda pudo eliminarse del juego mientras esperaba.
	if coin.Parent == nil then
		return
	end
	setCoinAvailable(coin, true)
	collectedCoins[coin] = nil
end

local function onCoinTouched(coin: BasePart, hit: BasePart)
	if collectedCoins[coin] then
		return
	end

	local player = getPlayerFromHit(hit)
	if not player or not isWithinPickupRange(player, coin) then
		return
	end

	-- Bloquear ANTES de cualquier otra operación para evitar dobles entregas.
	collectedCoins[coin] = true
	setCoinAvailable(coin, false)

	LeaderstatsService:AddCoins(player, Config.CoinValue)

	task.delay(Config.CoinRespawnTime, respawnCoin, coin)
end

local function registerCoin(instance: Instance)
	if not instance:IsA("BasePart") then
		warn(`[CoinService] "{instance:GetFullName()}" tiene el tag "{Config.CoinTag}" pero no es una BasePart`)
		return
	end

	local coin = instance
	originalTransparency[coin] = coin.Transparency
	coin.Touched:Connect(function(hit)
		onCoinTouched(coin, hit)
	end)
end

local function unregisterCoin(instance: Instance)
	if instance:IsA("BasePart") then
		collectedCoins[instance] = nil
		originalTransparency[instance] = nil
	end
end

function CoinService:Start()
	CollectionService:GetInstanceAddedSignal(Config.CoinTag):Connect(registerCoin)
	CollectionService:GetInstanceRemovedSignal(Config.CoinTag):Connect(unregisterCoin)

	for _, coin in CollectionService:GetTagged(Config.CoinTag) do
		registerCoin(coin)
	end
end

return CoinService
