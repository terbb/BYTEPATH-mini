require "objects/GameObject"

Player = GameObject:extend()

function Player:new(area, x, y, opts)
    Player.super.new(self, area, x, y, opts)
    self.x, self.y = x, y
    self.w, self.h = 12, 12
    self.r = -math.pi/2
    self.rv = 1.66*math.pi
    self.v = 0
    self.max_v = 100
    self.a = 100
    self.collider = self.area.world:newCircleCollider(self.x, self.y, self.w)
    self.collider:setObject(self)
    self.timer:every(0.24, function()
        self:shoot()
    end)
end

function Player:update(dt)
    Player.super.update(self, dt)
    if input:down('left') then self.r = self.r - self.rv*dt end
    if input:down('right') then self.r = self.r + self.rv*dt end

    self.v = math.min(self.v + self.a*dt, self.max_v)
    self.collider:setLinearVelocity(self.v*math.cos(self.r), self.v*math.sin(self.r))
end

function Player:draw()
    love.graphics.circle('line', self.x, self.y, self.w)
    --[[
        Exercise 82:
            One thing to be aware of in this exercise is that you should be rotating by math.pi, not math.pi + self.r.
            We want the final rotation to be math.pi + self.r, not math.pi + 2*self.r.
    ]]--
    pushRotate(self.x, self.y, math.pi)
    love.graphics.line(self.x, self.y, self.x + 2*self.w*math.cos(self.r), self.y + 2*self.w*math.sin(self.r))
    love.graphics.pop()

end

function Player:shoot()
    local d = 1.2*self.w
    self.area:addGameObject('ShootEffect', self.x + 1.2*self.w*math.cos(self.r), self.y + 1.2*self.w*math.sin(self.r), {player = self, d = d})
end