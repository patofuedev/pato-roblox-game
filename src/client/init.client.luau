--!strict
--[[
	Punto de entrada del cliente.

	Arranca los controladores del cliente. Los controladores solo se ocupan
	de presentación (efectos visuales, UI, sonido) y de enviar intenciones
	al servidor; nunca deciden resultados de gameplay.

	Para añadir un controlador nuevo (ShopController, InventoryController...):
	  1. Crea src/client/Controllers/<Nombre>Controller.luau con Start().
	  2. Añádelo a la lista CONTROLLERS.
]]

local Controllers = script.Controllers

type Controller = {
	Start: ((self: any) -> ())?,
}

local CONTROLLERS: { Controller } = {
	require(Controllers.CoinVisualController) :: any,
}

for _, controller in CONTROLLERS do
	if controller.Start then
		task.spawn(controller.Start, controller)
	end
end
