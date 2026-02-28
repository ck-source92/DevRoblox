--!strict
-- Domain/Deliverable.spec.luau

local Deliverable = require(script.Parent.Deliverable)

return function()
	describe("Deliverable", function()
		it("should start with no owner and not scored", function()
			local d = Deliverable.new()
			expect(d.State.Owner).to.equal(nil)
			expect(d.State.IsScored).to.equal(false)
		end)

		it("should assign owner correctly", function()
			local d = Deliverable.new()
			local player = { Name = "TestPlayer" }
			local ok = d:AssignOwner(player :: Player)
			expect(ok).to.equal(true)
			expect(d.State.Owner).to.equal(player)
		end)

		it("should not allow assigning owner if already owned", function()
			local d = Deliverable.new()
			local p1 = { Name = "P1" }
			local p2 = { Name = "P2" }

			d:AssignOwner(p1 :: Player)
			local ok = d:AssignOwner(p2 :: Player)
			expect(ok).to.equal(false)
			expect(d.State.Owner).to.equal(p1)
		end)

		it("should clear owner on MarkAsScored", function()
			local d = Deliverable.new()
			local p1 = { Name = "P1" }

			d:AssignOwner(p1 :: Player)
			d:MarkAsScored()
			expect(d.State.IsScored).to.equal(true)
			expect(d.State.Owner).to.equal(nil)
		end)
	end)
end
