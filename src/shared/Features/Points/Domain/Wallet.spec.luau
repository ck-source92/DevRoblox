--!strict
-- Domain/Wallet.spec.luau
-- Unit tests for Wallet domain logic.

local Wallet = require(script.Parent.Wallet)

return function()
	describe("Wallet", function()
		it("should start with 0 or initial balance", function()
			local w1 = Wallet.new()
			expect(w1:Get()).to.equal(0)

			local w2 = Wallet.new(100)
			expect(w2:Get()).to.equal(100)
		end)

		it("should add points correctly", function()
			local w = Wallet.new(10)
			local newBal = w:Add(5)
			expect(newBal).to.equal(15)
			expect(w:Get()).to.equal(15)
		end)

		it("should remove points if sufficient", function()
			local w = Wallet.new(10)
			local success = w:Remove(5)
			expect(success).to.equal(true)
			expect(w:Get()).to.equal(5)
		end)

		it("should fail to remove if insufficient", function()
			local w = Wallet.new(5)
			local success = w:Remove(10)
			expect(success).to.equal(false)
			expect(w:Get()).to.equal(5)
		end)
	end)
end
