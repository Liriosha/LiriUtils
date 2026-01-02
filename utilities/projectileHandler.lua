--[[
projectileHandler.lua

Use newProjectile(instance, direction, hitbox, func, onHit) to spawn projectiles.

PARAMETERS:
- instance: Roblox Instance (Part, MeshPart, etc.) representing the projectile.
- direction: Vector3 direction for movement.
- hitbox: Vector3 size for collision detection.
- func (optional): function(self, dt) called every Heartbeat. Use for movement/effects.
- onHit (optional): function(self, hitParts) called when hitbox overlaps parts. Handle damage/effects and set self.running = false.

RETURN:
- projectile table: {instance, direction, hitbox, func, onHit, running}

EXAMPLE:

newProjectile(
	orb,
	direction,
	Vector3.new(2,2,2),
	function(self, dt)
		if not self.instance.Parent then self.running = false return end
		self.instance.CFrame += self.direction * (dt * 60)
	end,
	function(self, hitParts)
		self.instance:Destroy()
		self.running = false
		-- add effects/damage here
	end
).exclude({owner.Character})

NOTES:
- Hitboxes are visualized if config.showHitboxes == true
- Collision ignores descendants of this script
- Multiple projectiles are supported
- Stops when self.running = false
]]

local projectiles = {}
local config = {
    showHitboxes = true
}
local hitboxWm = Instance.new("WorldModel")
hitboxWm.Parent=script
function exclude(self,instances)
    for _, inst in ipairs(instances) do
        table.insert(self.exclusions, inst)
    end
    return self
end
function newProjectile(instance : Instance,direction : Vector3, hitbox : Vector3, func, onHit)
	local projectile = {
		instance = instance,
		direction = direction,
		func=func or nil,
		onHit=onHit or nil,
		hitbox = hitbox,
        exclusions = {},
		running = true,
        exclude = exclude
	}
	table.insert(projectiles,projectile)
	return projectile
end
function defaultMovement(self,dt)
    if self.instance.Parent==nil then self.running=false;return end
	self.instance.CFrame = (self.instance.CFrame+self.direction * (dt * 60))
end
game:GetService("RunService").Heartbeat:Connect(function(dt)
    for i,projectile in pairs(projectiles) do
		if not projectile.running then
			table.remove(projectiles,table.find(projectiles,projectile))
			continue
		end
		if projectile.func then projectile:func(dt) else
            defaultMovement(projectile, dt)
        end
		if config.showHitboxes then
			local hb = Instance.new("Part")
			hb.Parent=hitboxWm
			hb.Size=projectile.hitbox
			hb.CanQuery=false
			hb.CanTouch=false
			hb.CanCollide=false
			hb.Material=Enum.Material.Neon
			hb.Transparency=0.8
			hb.Position=projectile.instance.Position
			hb.Color=Color3.fromRGB(255,0,0)
			game:GetService("Debris"):AddItem(hb,0.1)
		end
		local overlap = OverlapParams.new()
		overlap.FilterType=Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances=projectile.exclusions
		local hitbox = workspace:GetPartBoundsInBox(projectile.instance.CFrame,projectile.hitbox,overlap)
		if #hitbox>0 then
			projectile.onHit(projectile,hitbox)
		end
	end
end)
return newProjectile
