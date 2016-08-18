class 'Paint'

function Paint:__init()

	self.paintings = {}

	Network:Subscribe("SyncPainting", self, self.SyncPainting)
	Events:Subscribe("ModuleUnload", self, self.Unload)

end

function Paint:Unload()

	for _, obj in pairs(self.paintings) do
		obj:Remove()
	end
	
end

function Paint:SyncPainting(args, player)

	local obj = StaticObject.Create({
		position = args.vertices[2],
		angle = Angle(),
		model = " ",
		collision = " ",
		world = player:GetWorld(),
		fixed = true
	})
	
	obj:SetNetworkValue("vertices", args.vertices)
	obj:SetNetworkValue("color", args.color)
	obj:SetNetworkValue("IsPainting", true)
		
	table.insert(self.paintings, obj)
	
end

Paint = Paint()