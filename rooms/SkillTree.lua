SkillTree = Object:extend()

function SkillTree:new()
	self.timer = Timer()
	self.main_canvas = love.graphics.newCanvas(gw, gh)
    camera:lookAt(32, 96)
	camera.smoother = Camera.smooth.damped(5)
	self.font = fonts.m5x7_16

	selected_sp = 0
	selected_node_indexes = {}

	self.active_nodes = 0
	self.tree = table.copy(tree)
	for id, node in ipairs(self.tree) do
		--[[
			A note if you're on this section:
			The author adds the id's of the linked nodes directly to the node's table.
			I've elected to add the id's of the linked nodes to the links list just for clarity.
		]]--
		for _, linked_node_id in ipairs(node.links or {}) do
			table.insert(self.tree[linked_node_id].links, id)
		end
	end

	for id, node in ipairs(self.tree) do
		if node.links then
			node.links = M.unique(node.links)
		end
	end

	self.nodes = {}
	self.lines = {}

	local apply_points_txt = "Apply Points"
	local button_x, button_y = gw/2 - (16 + self.font:getWidth(apply_points_txt)) - 16, gh - self.font:getHeight() - 10
	local button_w, button_h = 16 + self.font:getWidth(apply_points_txt), self.font:getHeight() + 4
	local apply_points_button = Button(button_x, button_y, {w = button_w, h = button_h, text = apply_points_txt, font = self.font, center_justified = true, click = SkillTree.buySelectedNodes, click_args = self})
	local cancel_points_txt = "Cancel"
	button_x = gw/2 + 16
	local cancel_points_button = Button(button_x, button_y, {w = button_w, h = button_h, text = cancel_points_txt, font = self.font, center_justified = true, click = SkillTree.cancelSelectedNodes, click_args = self})
	self.select_nodes_buttons = {apply_points_button, cancel_points_button}

	for id, node in pairs(self.tree) do table.insert(self.nodes, Node(id, node.x, node.y, node.cost, {no_description = node.no_description, size = node.size})) end
	for id, node in pairs(self.tree) do 
		for _, linked_node_id in ipairs(node.links or {}) do
			table.insert(self.lines, Line(id, linked_node_id))
		end
	end

	-- Bug when clicking on the skill trees button, previous_mx not initialized (we don't want to drag our camera anywhere when creating this room)
	self.disable_input = true
	self.timer:after(0.2, function()
			self.disable_input = false
		end)
end

function SkillTree:update(dt)
	--[[
		Important note to make if you're on this section:
		LOVE 11.0 changed the way that love.keyboard.isDown() and love.mouse.isDown() work, which causes the boipushy input library to break if you try and bind
		mouse1 to left_click. It'll complain that mouse1 isn't a valid key constant, because the way the input library works is that it checks for a boolean value
		from love.keyboard.isDown() and love.mouse.isDown() in order to determine whether or not the input is down. Since mouse1 isn't a valid key constant for the keyboard,
		this throws an exception instead.
		
		You can modify your boipushy source code to use this commit: https://github.com/adnzzzzZ/boipushy/pull/29/commits/f7da44d6063ef2ffab6dde93051c9c958d67a00f
		since it doesn't seem like the author hasn't noticed yet and thus has not yet merged it in.
	]]--
	self.timer:update(dt)

	for _, node in ipairs(self.nodes) do
		node:update()
	end

	for _, line in ipairs(self.lines) do
		line:update()
	end

	if #selected_node_indexes > 0 then
		for _, select_node_button in ipairs(self.select_nodes_buttons) do
			select_node_button:update()
		end
	end

	self.active_nodes = #GameData.bought_node_indexes - 1 

	if self.disable_input then return end

	if input:down('left_click') then
		-- Holding down left click can immediately hit this case when entering the SkillTree. Alternative solution: update the previous_mx and previous_my first before running this.
		if self.previous_mx == nil or self.previous_my == nil then return end
		local mx, my = camera:getMousePosition(sx, sy, xTranslationRequiredToCenter, yTranslationRequiredToCenter, sx*gw, sy*gh)
		local dx, dy = mx - self.previous_mx, my - self.previous_my
		camera:move(-dx, -dy)
	end
	self.previous_mx, self.previous_my = camera:getMousePosition(sx, sy, xTranslationRequiredToCenter, yTranslationRequiredToCenter, sx*gw, sy*gh)

	-- Added some simple limits for the zooming in/out.
	if input:pressed('zoom_in') then 
		local new_scale = camera.scale + 0.4
		if new_scale > 3 then new_scale = 3 end
		self.timer:tween('zoom', 0.2, camera, {scale = new_scale}, 'in-out-cubic') 
	end
	if input:pressed('zoom_out') then 
		local new_scale = camera.scale - 0.4
		if new_scale < 0.5 then new_scale = 0.5 end
		self.timer:tween('zoom', 0.2, camera, {scale = new_scale}, 'in-out-cubic') 
	end

end

function SkillTree:draw()
	love.graphics.setCanvas(self.main_canvas)
	love.graphics.clear()
	camera:attach(0, 0, gw, gh)
	for _, line in ipairs(self.lines) do
		line:draw()
	end
	for _, node in ipairs(self.nodes) do
		node:draw()
	end

	camera:detach()
	love.graphics.setBackgroundColor(0.04, 0.04, 0.04)
	-- Stats rectangle
	for _, node in ipairs(self.nodes) do
		if node.hot then
			local stats = self.tree[node.id].stats or {}
			-- Figure out max_text_width to be able to set the proper rectangle width
			local max_text_width = 0
			for i = 1, #stats, 3 do
				if self.font:getWidth(stats[i]) > max_text_width then
					max_text_width = self.font:getWidth(stats[i])
				end
			end
			max_text_width = max_text_width + 24

			-- Draw rectangle
			local mx, my = love.mouse.getPosition() 
			mx, my = mx/sx, my/sy
			love.graphics.setColor(0, 0, 0, 222/255)
			love.graphics.rectangle('fill', mx, my, 16 + max_text_width, 
				self.font:getHeight() + (#stats/3)*self.font:getHeight() - 6)  

			-- Draw text
			love.graphics.setColor(default_color)
			for i = 1, #stats, 3 do
				love.graphics.print(stats[i], math.floor(mx + 8), 
					math.floor(my + self.font:getHeight()/2 + (math.floor(i/3))*self.font:getHeight()) - 4)
			end
			love.graphics.setColor(skill_point_color)
			local sp_cost_txt = (cost[tree[node.id].size] or 0) .. "SP"
			love.graphics.print(sp_cost_txt, math.floor(mx + 8 + max_text_width - self.font:getWidth(sp_cost_txt)),  math.floor(my + self.font:getHeight()/2) - 4)
		end
	end

	-- Player's SP
	love.graphics.setColor(skill_point_color)
	love.graphics.print(GameData.sp .. " SKILL POINTS", 12, self.font:getHeight() / 2)

	-- Player's Active Nodes
	local active_nodes_txt = self.active_nodes .. " / " .. max_nodes .. " ACTIVE NODES"
	love.graphics.print(active_nodes_txt, gw - self.font:getWidth(active_nodes_txt) - 12, self.font:getHeight() / 2)

	-- If player has selected any nodes, display Apply Points and Cancel button
	if #selected_node_indexes > 0 then
		for _, select_node_button in ipairs(self.select_nodes_buttons) do
			select_node_button:draw()
		end
	end

	if self.display_error_message then
		local w, h =  self.font:getWidth(self.display_error_message)*2, self.font:getHeight() + 4
		local x, y = gw/2 - w/2, gh/2 - h/2
		setColor(0, 0, 0, 1)
		love.graphics.rectangle('fill', x, y, w, h)
		local r, g, b = unpack(hp_color)
		setColor(r, g, b, 1)
		love.graphics.rectangle('line', x, y, w, h)
		love.graphics.print(self.display_error_message, x + w/2 - self.font:getWidth(self.display_error_message)/2, y + h/2 - self.font:getHeight()/1.6)
		love.graphics.setColor(default_color)
	end
	love.graphics.setCanvas()

	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setBlendMode('alpha', 'premultiplied')
    love.graphics.draw(self.main_canvas, xTranslationRequiredToCenter, yTranslationRequiredToCenter, 0, sx, sy)
	love.graphics.setBlendMode('alpha')

	love.graphics.setFont(self.font)
end

function SkillTree:finish()
	timer:after(1, function()
			gotoRoom('SkillTree')
		end)
end

function SkillTree:canNodeBeBought(id)
	-- You'll need to access the linked_node_id's from the node's links table if you've been adding id's to the links table.
	
	for _, linked_node_id in ipairs(self.tree[id].links or {}) do
		local enoughSP = GameData.sp - cost[self.tree[id].size] >= 0
		local notMaxNodes = self.active_nodes < max_nodes
		if not enoughSP then self.display_error_message = "Not enough SP." end
		if not notMaxNodes then self.display_error_message = "Max nodes reached." end
		if not enoughSP or not notMaxNodes then self.timer:after('error_message', 1, function() self.display_error_message = false end) playMenuError() return end
		if (M.any(GameData.bought_node_indexes, linked_node_id) or M.any(selected_node_indexes, linked_node_id)) and enoughSP and notMaxNodes then return true end
	end
end

function SkillTree:buySelectedNodes()
	playMenuSelect()
	GameData.bought_node_indexes = M.interleave(GameData.bought_node_indexes, selected_node_indexes)
	saveGameData()
	selected_sp = 0
	selected_node_indexes = {}
end

function SkillTree:cancelSelectedNodes()
	playMenuBack()
	local selected_nodes = M.select(self.nodes, function(node, _)
			return node.selected
		end)
	M.invoke(selected_nodes, function(node, _)
			node.selected = false
		end)
	GameData.sp = GameData.sp + selected_sp
	selected_sp = 0
	selected_node_indexes = {}
end

function SkillTree:destroy()
end

function SkillTree:onBack()
	self:cancelSelectedNodes()
end