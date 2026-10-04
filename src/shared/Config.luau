--!strict
--[[
	Config

	Valores de ajuste del juego compartidos entre servidor y cliente.
	Cambia aquí los números del gameplay; ningún otro módulo debe tener
	"números mágicos" equivalentes.

	La tabla está congelada (table.freeze) para que ningún script pueda
	modificarla en tiempo de ejecución por accidente.
]]

local Config = {
	-- Monedas ---------------------------------------------------------------
	-- Segundos que tarda una moneda recogida en volver a aparecer.
	CoinRespawnTime = 5,
	-- Monedas que recibe el jugador por cada moneda recogida.
	CoinValue = 1,
	-- Tag de CollectionService que identifica a las monedas en Workspace.
	CoinTag = "Coin",
	-- Distancia máxima (studs) entre el personaje y la moneda para aceptar
	-- la recogida. Protege contra clientes que reporten toques lejanos.
	CoinPickupMaxDistance = 15,
	-- Velocidad de giro visual de las monedas en el cliente (grados/segundo).
	CoinSpinSpeed = 90,

	-- Jugador ---------------------------------------------------------------
	-- Monedas con las que empieza cada jugador (sin DataStore por ahora).
	StartingCoins = 0,
}

return table.freeze(Config)
