local insert = table.insert
local WorldNetworkObject = WorldNetworkObject
local zero_angle = Angle()

class 'Paint'

function Paint:__init()
	self.objects = {}
	Network:Subscribe("SyncPainting", self, self.SyncPainting)
	Events:Subscribe("ModuleUnload", self, self.Unload)
end

function Paint:Unload()
	for _, obj in ipairs(self.objects) do
		obj:Remove()
	end
end

function Paint:SyncPainting(args, player)

	local obj = WorldNetworkObject.Create({
		position = args.position,
		angle = zero_angle,
		values = {
			radius = args.radius,
			color = args.color,
			positions = args.positions,
			angles = args.angles,
			is_painting = true,
		},
		world = player:GetWorld()
	})

	insert(self.objects, obj)

end

Paint = Paint()
