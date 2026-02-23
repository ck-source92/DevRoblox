-- NPC System Configuration
return table.freeze({
	-- Debug
	DEBUG = false,

	ISNPC = "NPC",

	-- Behavior State Durations (in seconds)
	WALK_DURATION_MIN = 10,
	WALK_DURATION_MAX = 15,
	OBSERVE_DURATION_MIN = 1,
	OBSERVE_DURATION_MAX = 2,
	IDLE_DURATION_MIN = 2,
	IDLE_DURATION_MAX = 3,
	RUN_DURATION_MIN = 8,
	RUN_DURATION_MAX = 12,

	-- Movement
	WALK_SPEED = 7,
	RUN_SPEED = 14,
	WANDER_RADIUS = 50,
	PATHFINDING_TIMEOUT = 10,

	-- Health
	DEFAULT_HEALTH = 100,
	DEFAULT_MAX_HEALTH = 100,

	-- Spawning
	MAX_NPCS_PER_ZONE = 20,
	SPAWN_BATCH_DELAY = 0.1,
	RESPAWN_DELAY = 30,

	-- Interaction
	INTERACTION_RANGE = 8,
	INTERACTION_COOLDOWN = 5,

	-- NPC-to-NPC Interaction
	NPC_INTERACTION_DETECTION_RADIUS_MIN = 8,
	NPC_INTERACTION_DETECTION_RADIUS_MAX = 15,
	NPC_INTERACTION_DURATION_MIN = 2,
	NPC_INTERACTION_DURATION_MAX = 3,
	NPC_INTERACTION_COOLDOWN_MIN = 10,
	NPC_INTERACTION_COOLDOWN_MAX = 25,

	-- States
	States = {
		IDLE = "Idle",
		WALKING = "Walking",
		OBSERVING = "Observing",
		INTERACTING = "Interacting",
		DEAD = "Dead",
		RUNNING = "Running",
	},

	-- NPC Name Pool (for random names)
	NPC_NAMES = {
		"Alex",
		"Jordan",
		"Taylor",
		"Morgan",
		"Casey",
		"Riley",
		"Avery",
		"Quinn",
		"Skyler",
		"Dakota",
		"Peyton",
		"Cameron",
		"Blake",
		"Parker",
		"Hayden",
	},
})
