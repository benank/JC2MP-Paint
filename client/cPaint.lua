local insert, remove = table.insert, table.remove
local Vector3, Painting, Physics, Angle = Vector3, Painting, Physics, Angle

local heights = {
	['Layer 1'] = 0.01,
	['Layer 2'] = 0.02,
	['Layer 3'] = 0.04,
}

local blacklist = {
	[Action.Fire] = true,
	[Action.FireLeft] = true,
	[Action.FireRight] = true,
	[Action.VehicleFireLeft] = true,
	[Action.VehicleFireRight] = true,
	[Action.McFire] = true,
}

class 'Paint'

function Paint:__init()

	self.paint_key = VirtualKey.LButton
	self.colorpick_key = "P"
	self.brush_size = 0.5
	self.brush_range = 10
	self.brush_color = Color.Red

	self.colorpicker = HSVColorPicker.Create()
	self.colorpicker:SetSize(Render.Size / 2)
	self.colorpicker:SetPosition(Render.Size / 2 - self.colorpicker:GetSize() / 2)
	self.colorpicker:Hide()
	self.colorpicker:SetColor(self.brush_color)

	self.slider = HorizontalSlider.Create()
	self.slider:SetSize(Vector2(Render.Size.x * 0.5, Render.Size.y * 0.015))
	self.slider:SetPosition(Vector2(Render.Size.x / 2 - self.slider:GetSize().x / 2, Render.Size.y * 0.2))
	self.slider:SetRange(0.05, 5)
	self.slider:SetValue(self.brush_size)
	self.slider:Hide()

	self.activebutton = Button.Create()
	self.activebutton:SetSize(Render.Size * 0.05)
	self.activebutton:SetPosition(Render.Size / 2 - Vector2(self.activebutton:GetSize().x / 2, Render.Size.y * 0.375))
	self.activebutton:SetText("Disabled")
	self.activebutton:SetTextSize(self.activebutton:GetSize().x * 0.21)
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
	self.layersbox:SetTextSize(self.layersbox:GetSize().x * 0.18)
	self.layersbox:SetPosition(Render.Size / 2 + Vector2(self.layersbox:GetSize().x * 2, -Render.Size.y * 0.375))
	self.layersbox:Hide()

	self.client_paintings = {}
	self.network_paintings = {}
	self.model_queue = {}

	Timer.SetInterval(1000, function()
		self:SyncPainting()
	end)

	Events:Subscribe("GameRender", self, self.GameRender)
	Events:Subscribe("KeyUp", self, self.KeyUp)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("WorldNetworkObjectCreate", self, self.PaintingCreate)

end

function Paint:Toggle()

	local button = self.activebutton

	if button:GetToggleState() then
		local color = Color.Lime
		button:SetText("Enabled")
		button:SetTextNormalColor(color)
		button:SetTextHoveredColor(color)
		button:SetTextPressedColor(color)
		button:SetTextDisabledColor(color)
	else
		local color = Color.Red
		button:SetText("Disabled")
		button:SetTextNormalColor(color)
		button:SetTextHoveredColor(color)
		button:SetTextPressedColor(color)
		button:SetTextDisabledColor(color)
	end

end

function Paint:LocalPlayerInput(args)
	if self.colorpicker:GetVisible() or (self.activebutton:GetToggleState() and blacklist[args.input]) then
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
	if not self.client_paintings[1] then return end
	local painting = remove(self.client_paintings, 1)
	self.intermediate = painting
	painting:Sync()
end

function Paint:PaintingCreate(args)

	local values = args.object:GetValues()
	if not values.is_painting then return end

	insert(self.model_queue, function()
		local painting = Painting(values.radius, values.color, true)
		painting:SetStrokes(values.positions, values.angles)
		insert(self.network_paintings, painting)
		self.intermediate = nil
	end)

end

function Paint:GameRender(args)

	if not self.colorpicker:GetVisible() and self.activebutton:GetToggleState() then

		if Key:IsDown(self.paint_key) then

			local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.brush_range)

			if not ray.entity and ray.distance < self.brush_range and (not self.last_position or self.last_position:Distance(ray.position) > 0.2 * self.brush_size) then

				self.last_position = ray.position

				self.painting = self.painting or Painting(self.brush_size / 2, self.brush_color)

				local angle = Angle.FromVectors(ray.normal, Vector3.Up)
				local position = ray.position + angle * Vector3.Up * heights[self.layersbox:GetText()]

				self.painting:AddStroke(position, angle)

			end

		elseif self.painting then

			insert(self.client_paintings, self.painting)
			self.painting = nil

		end

	end

	if self.model_queue[1] then table.remove(self.model_queue, 1)() end

	if self.painting then self.painting:Draw() end
	if self.intermediate then self.intermediate:Draw() end

	for _, painting in pairs(self.client_paintings) do
		painting:Draw()
	end

	for _, painting in pairs(self.network_paintings) do
		painting:Draw()
	end

end

Paint = Paint()
