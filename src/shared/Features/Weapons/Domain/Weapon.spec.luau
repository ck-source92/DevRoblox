--!strict
-- Domain/Weapon.spec.luau

local Weapon = require(script.Parent.Weapon)

return function()
	describe("Weapon", function()
		it("should start unequipped and not attacking", function()
			local w = Weapon.new()
			expect(w.State.IsEquipped).to.equal(false)
			expect(w.State.IsAttacking).to.equal(false)
		end)

		it("should not be able to attack if unequipped", function()
			local w = Weapon.new()
			expect(w:CanAttack(100, 1)).to.equal(false)
		end)

		it("should be able to attack when equipped and off cooldown", function()
			local w = Weapon.new()
			w.State.IsEquipped = true
			expect(w:CanAttack(1, 1)).to.equal(true)
		end)

		it("should handle cooldowns correctly", function()
			local w = Weapon.new()
			w.State.IsEquipped = true
			w:StartAttack(100)
			w:StopAttack()

			expect(w:CanAttack(100.5, 1)).to.equal(false)
			expect(w:CanAttack(101, 1)).to.equal(true)
		end)
	end)
end
