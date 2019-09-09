Line = Object:extend()

function Line:new(node_1_id, node_2_id)
    self.node_1_id, self.node_2_id = node_1_id, node_2_id
    self.node_1, self.node_2 = tree[node_1_id], tree[node_2_id]
end

function Line:update(dt)
    if M.any(GameData.bought_node_indexes, self.node_1_id) and 
       M.any(GameData.bought_node_indexes, self.node_2_id) then 
      	self.active = true 
    else self.active = false end
end

function Line:draw()
    local r, g, b = unpack(default_color)
    if self.active then love.graphics.setColor(r, g, b, 255/255)
    else love.graphics.setColor(r, g, b, 32/255) end
    love.graphics.line(self.node_1.x, self.node_1.y, self.node_2.x, self.node_2.y)
    love.graphics.setColor(r, g, b, 255)
end