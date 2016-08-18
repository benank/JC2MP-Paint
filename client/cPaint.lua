class 'Paint'

function Paint:__init()

	self.paint_key = VirtualKey.LButton

	self.painting = false
	
	self.colorpick_key = "P"
	
	self.colorpicker = HSVColorPicker.Create()
	self.colorpicker:SetSize(Render.Size / 2)
	self.colorpicker:SetPosition(Render.Size / 2 - self.colorpicker:GetSize() / 2)
	self.colorpicker:Hide()
	self.colorpicker:SetColor(Color.Red)
	
	self.slider = HorizontalSlider.Create()
	self.slider:SetSize(Vector2(Render.Size.x * 0.5, Render.Size.y * 0.015))
	self.slider:SetPosition(Vector2(Render.Size.x / 2 - self.slider:GetSize().x / 2, Render.Size.y * 0.2))
	self.slider:SetClampToNotches(false)
	self.slider:SetMaximum(5)
	self.slider:SetMinimum(0.05)
	self.slider:SetRange(0.05, 5)
	self.slider:SetValue(0.5)
	self.slider:Hide()
	
	self.activebutton = Button.Create()
	self.activebutton:SetSize(Render.Size * 0.05)
	self.activebutton:SetPosition(Render.Size / 2 - Vector2(self.activebutton:GetSize().x / 2,Render.Size.y * 0.375))
	self.activebutton:SetText("Disabled")
	self.activebutton:SetTextSize(self.activebutton:GetSize().x * 0.2)
	self.activebutton:SetTextNormalColor(Color.Red)
	self.activebutton:SetTextHoveredColor(Color.Red)
	self.activebutton:SetTextPressedColor(Color.Red)
	self.activebutton:SetTextDisabledColor(Color.Red)
	self.activebutton:SetToggleState(false)
	self.activebutton:SetToggleable(true)
	self.activebutton:Subscribe("Toggle", self, self.Toggle)
	self.activebutton:Hide()
	
	self.layersbox = ComboBox.Create()
	self.layer1 = self.layersbox:AddItem("Layer 1")
	self.layersbox:AddItem("Layer 2")
	self.layersbox:AddItem("Layer 3")
	self.layersbox:SelectItem(self.layer1)
	self.layersbox:SetSize(Vector2(Render.Size.x * 0.06, Render.Size.y * 0.035))
	self.layersbox:SetTextSize(self.layersbox:GetSize().x * 0.25)
	self.layersbox:SetPosition(Render.Size / 2 + Vector2(self.layersbox:GetSize().x * 2, -Render.Size.y * 0.375))
	self.layersbox:Hide()
	
	self.brush_size = 0.5
	self.brush_range = 10
	self.brush_color = self.colorpicker:GetColor()
	
	self.cur_vertices = {}
	self.cur_pos = {}
	self.cur_painting = nil

	self.models = {}
	
	Timer.SetTimeout(1000, function()
		self:SyncPainting()
	end)

	Events:Subscribe("GameRender", self, self.GameRender)
	Events:Subscribe("KeyUp", self, self.KeyUp)
	Events:Subscribe("LocalPlayerInput", self, self.LPI)

end

function Paint:Toggle()

	if self.activebutton:GetToggleState() then
	
		self.activebutton:SetText("Enabled")
		self.activebutton:SetTextNormalColor(Color(0,255,0))
		self.activebutton:SetTextHoveredColor(Color(0,255,0))
		self.activebutton:SetTextPressedColor(Color(0,255,0))
		self.activebutton:SetTextDisabledColor(Color(0,255,0))
		
	else
	
		self.activebutton:SetText("Disabled")
		self.activebutton:SetTextNormalColor(Color.Red)
		self.activebutton:SetTextHoveredColor(Color.Red)
		self.activebutton:SetTextPressedColor(Color.Red)
		self.activebutton:SetTextDisabledColor(Color.Red)
		
	end
	
end

function Paint:LPI(args)

	if self.colorpicker:GetVisible() then
		return false
	end
	
	if self.activebutton:GetToggleState() and 
	(args.input == Action.Fire 
	or args.input == Action.FireLeft 
	or args.input == Action.FireRight 
	or args.input == Action.VehicleFire) then
		return false
	end
	
end

function Paint:KeyUp(args)

	if args.key == string.byte(self.colorpick_key) then
	
		if self.colorpicker:GetVisible() then
			self.colorpicker:Hide()
			self.slider:Hide()
			self.activebutton:Hide()
			self.layersbox:Hide()
			self.brush_color = self.colorpicker:GetColor()
			self.brush_size = self.slider:GetValue()
		else
			self.colorpicker:Show()
			self.slider:Show()
			self.activebutton:Show()
			self.layersbox:Show()
		end
		Mouse:SetVisible(self.colorpicker:GetVisible())
		
	end
	
end

function Paint:SyncPainting()

	if not self.painting then

		if table.count(self.cur_pos) > 5 then
			Network:Send("SyncPainting", {vertices = self.cur_pos, color = self.brush_color})
		end
		
		self.cur_pos = {}
		self.cur_vertices = {}
		self.cur_painting = nil
		
	end

	for obj in Client:GetStaticObjects() do
	
		if not self.models[obj:GetId()] and obj:GetValue("IsPainting") and obj:GetValue("vertices") and obj:GetValue("color") then
		
			local points = obj:GetValue("vertices")
			local color = obj:GetValue("color") or Color.White
			local vertices = {}
			for _, pos in ipairs(points) do
				table.insert(vertices, Vertex(pos))
			end
	
			self.models[obj:GetId()] = Painting(vertices, color)
			
		end
		
	end


	Timer.SetTimeout(1000, function()
		self:SyncPainting()
	end)
	
end


function Paint:GameRender(args)

	if Key:IsDown(self.paint_key) and not self.colorpicker:GetVisible() and self.activebutton:GetToggleState() then
		self.painting = true
		
		local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.brush_range)
		
		if not ray.entity and ray.distance < self.brush_range then
		
			local height = 0
			if self.layersbox:GetText() == "Layer 2" then
				height = 0.02
			elseif self.layersbox:GetText() == "Layer 3" then
				height = 0.04
			end
		
			local angle = Angle.FromVectors(Vector3.Forward, ray.normal) * Angle(0,math.pi / 2,0)
			local pos = ray.position + angle * Vector3.Down * (0.05 + 0.035 + height)
			
			
			table.insert(self.cur_vertices, Vertex(pos + angle * Vector3(-self.brush_size / 2, 0, -self.brush_size / 2)))
			table.insert(self.cur_vertices, Vertex(pos + angle * Vector3(self.brush_size / 2, 0, self.brush_size / 2)))
			table.insert(self.cur_vertices, Vertex(pos + angle * Vector3(-self.brush_size / 2, 0, self.brush_size / 2)))
			
			table.insert(self.cur_vertices, Vertex(pos + angle * Vector3(-self.brush_size / 2, 0, -self.brush_size / 2)))
			table.insert(self.cur_vertices, Vertex(pos + angle * Vector3(self.brush_size / 2, 0, self.brush_size / 2)))
			table.insert(self.cur_vertices, Vertex(pos + angle * Vector3(self.brush_size / 2, 0, -self.brush_size / 2)))
			
			self.cur_painting = Painting(self.cur_vertices, self.brush_color)
			
			table.insert(self.cur_pos, pos + angle * Vector3(-self.brush_size / 2, 0, -self.brush_size / 2))
			table.insert(self.cur_pos, pos + angle * Vector3(self.brush_size / 2, 0, self.brush_size / 2))
			table.insert(self.cur_pos, pos + angle * Vector3(-self.brush_size / 2, 0, self.brush_size / 2))
			
			table.insert(self.cur_pos, pos + angle * Vector3(-self.brush_size / 2, 0, -self.brush_size / 2))
			table.insert(self.cur_pos, pos + angle * Vector3(self.brush_size / 2, 0, self.brush_size / 2))
			table.insert(self.cur_pos, pos + angle * Vector3(self.brush_size / 2, 0, -self.brush_size / 2))
			
			
		end
		
	else
		self.painting = false
	end
	
	if self.cur_painting then
		self.cur_painting:Draw()
	end
	
	for _, painting in pairs(self.models) do
		painting:Draw()
	end
	
	
end

Paint = Paint()