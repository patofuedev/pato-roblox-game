--!strict
--[[
	CoinVisualController

	Efecto puramente visual: hace girar las monedas en el cliente.
	El giro es local (no se replica) y no afecta a la lógica de recogida,
	que se resuelve en el servidor según la posición de la moneda.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local CoinVisualController = {}

function CoinVisualController:Start()
	local spinRadiansPerSecond = math.rad(Config.CoinSpinSpeed)

	RunService.RenderStepped:Connect(function(deltaTime: number)
		local rotation = CFrame.Angles(0, spinRadiansPerSecond * deltaTime, 0)
		for _, coin in CollectionService:GetTagged(Config.CoinTag) do
			if coin:IsA("BasePart") then
				-- Rota sobre el eje Y del mundo manteniendo la posición.
				coin.CFrame = CFrame.new(coin.Position) * rotation * coin.CFrame.Rotation
			end
		end
	end)
end

return CoinVisualController
