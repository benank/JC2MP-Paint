local insert = table.insert
local Vertex, Vector3, Model, Network = Vertex, Vector3, Model, Network
local zero_angle = Angle()

class 'Painting'

function Painting:__init(radius, color, is_synced)
	self.radius = radius
	self.color = color
	if not is_synced then
		self.vertices = {}
		self.positions = {}
		self.angles = {}
	end
end

function Painting:AddStroke(position, angle)

	local old_count = #self.positions
	local new_count = old_count + 1

	insert(self.positions, position)
	self.angles[new_count] = angle ~= zero_angle and angle or nil

	self.position = self.position and (position + old_count * self.position) / new_count or position

	local radius, vertices = self.radius, self.vertices
	insert(vertices, Vertex(position + angle * Vector3(-radius, 0, -radius)))
	insert(vertices, Vertex(position + angle * Vector3( radius, 0, -radius)))
	insert(vertices, Vertex(position + angle * Vector3(-radius, 0,  radius)))
	insert(vertices, Vertex(position + angle * Vector3( radius, 0,  radius)))

	local model = Model.Create(vertices)
	model:SetColor(self.color)
	model:SetTopology(Topology.TriangleStrip)
	self.model = model

end

function Painting:SetStrokes(positions, angles)

	local radius, vertices = self.radius, {}

	for i, position in ipairs(positions) do
		local angle = angles[i] or zero_angle
		insert(vertices, Vertex(position + angle * Vector3(-radius, 0, -radius)))
		insert(vertices, Vertex(position + angle * Vector3( radius, 0, -radius)))
		insert(vertices, Vertex(position + angle * Vector3(-radius, 0,  radius)))
		insert(vertices, Vertex(position + angle * Vector3( radius, 0,  radius)))
	end

	local model = Model.Create(vertices)
	model:SetColor(self.color)
	model:SetTopology(Topology.TriangleStrip)
	self.model = model

end

function Painting:Sync()

	Network:Send("SyncPainting", {
		position = self.position,
		positions = self.positions,
		angles = self.angles,
		radius = self.radius,
		color = self.color,
	})

	self.vertices = nil
	self.position = nil
	self.positions = nil
	self.angles = nil

end

function Painting:Draw(args)
	self.model:Draw()
end

function Painting:Remove()
	self.model = nil
end
