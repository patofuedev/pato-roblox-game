--!strict
--[[
	Punto de entrada del servidor.

	Carga los servicios en orden y los arranca en dos fases:
	  1. Init()  -> preparación interna, sin depender de otros servicios.
	  2. Start() -> conecta eventos y empieza a funcionar; aquí ya puede
	               usar cualquier otro servicio porque todos están inicializados.

	Para añadir un servicio nuevo (ShopService, InventoryService, QuestService...):
	  1. Crea src/server/Services/<Nombre>Service.luau con Init/Start.
	  2. Añádelo a la lista SERVICES en el orden adecuado.
]]

local Services = script.Services

type Service = {
	Init: ((self: any) -> ())?,
	Start: ((self: any) -> ())?,
}

-- El orden importa: un servicio debe ir después de los que usa.
local SERVICES: { Service } = {
	require(Services.LeaderstatsService) :: any,
	require(Services.CoinService) :: any,
}

for _, service in SERVICES do
	if service.Init then
		service:Init()
	end
end

for _, service in SERVICES do
	if service.Start then
		-- task.spawn evita que un Start que ceda (yield) bloquee a los demás.
		task.spawn(service.Start, service)
	end
end

print("[Server] Servicios iniciados")
