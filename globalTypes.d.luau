-- globalTypes.d.luau
-- TestEZ global type definitions for Luau LSP

type Expectation = {
	to: {
		equal: (expected: any) -> (),
		be: {
			ok: () -> (),
			a: (typeName: string) -> (),
			an: (typeName: string) -> (),
			near: (expected: number, limit: number?) -> (),
		},
		never: {
			equal: (expected: any) -> (),
			be: {
				ok: () -> (),
				a: (typeName: string) -> (),
				an: (typeName: string) -> (),
				near: (expected: number, limit: number?) -> (),
			},
		},
		throw: (message: string?) -> (),
	},
}

return {
	describe = (nil :: any) :: (name: string, callback: () -> ()) -> (),
	it = (nil :: any) :: (name: string, callback: () -> ()) -> (),
	expect = (nil :: any) :: (value: any) -> Expectation,
	beforeEach = (nil :: any) :: (callback: () -> ()) -> (),
	afterEach = (nil :: any) :: (callback: () -> ()) -> (),
	beforeAll = (nil :: any) :: (callback: () -> ()) -> (),
	afterAll = (nil :: any) :: (callback: () -> ()) -> (),
	FIXME = (nil :: any) :: (name: string, callback: () -> ()) -> (),
	FOCUS = (nil :: any) :: (name: string, callback: () -> ()) -> (),
	SKIP = (nil :: any) :: (name: string, callback: () -> ()) -> (),
}
