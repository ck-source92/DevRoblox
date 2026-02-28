local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEz = require(ReplicatedStorage.Packages.TestEZ)
local PlayerEntity = require(ReplicatedStorage.Shared.Classes.Core.Domain.Entities.PlayerEntity)

return function()
	describe("PlayerEntity", function()
		it("awokwoawaowaok", function()
			local playerEntity = PlayerEntity.new(1, "TestPlayer")
			expect(playerEntity).to.be.ok()
			expect(playerEntity.Id).to.equal(1)
			expect(playerEntity.Username).to.equal("TestPlayer")
			expect(playerEntity.Health).to.equal(100)
			expect(playerEntity.MaxHealth).to.equal(200)
			expect(playerEntity.Level).to.equal(1)
		end)

		it("should take damage and reduce health", function()
			local playerEntity = PlayerEntity.new(1, "TestPlayer")
			local isDead = playerEntity:TakeDamage(30)
			expect(playerEntity.Health).to.equal(70)
			expect(isDead).to.equal(false)
		end)

		it("should not go below 0 health", function()
			local playerEntity = PlayerEntity.new(1, "TestPlayer")
			local isDead = playerEntity:TakeDamage(150)
			expect(playerEntity.Health).to.equal(0)
			expect(isDead).to.equal(true)
		end)

		it("should heal and increase health", function()
			local playerEntity = PlayerEntity.new(1, "TestPlayer")
			playerEntity:TakeDamage(30) -- Health = 70
			playerEntity:Heal(20)
			expect(playerEntity.Health).to.equal(90)
		end)

		it("should not exceed max health when healing", function()
			local playerEntity = PlayerEntity.new(1, "TestPlayer")
			playerEntity:Heal(150) -- Try to heal beyond max
			expect(playerEntity.Health).to.equal(200) -- Should cap at MaxHealth
		end)
	end)
end
