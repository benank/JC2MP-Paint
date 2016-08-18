class 'Painting'

function Painting:__init(vertices, color)

	self.model = Model.Create(vertices)
	self.model:SetColor(color)
	self.model:SetTopology(Topology.TriangleList)
	
end

function Painting:Draw(args)

	self.model:Draw()
	
end

function Painting:Remove()

	self.model = nil
	self = nil
	
end