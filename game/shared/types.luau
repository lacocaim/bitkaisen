local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jecs = require(ReplicatedStorage.Packages.Jecs)
local Planck = require(ReplicatedStorage.Packages.Planck)

export type World = typeof(Jecs.world())
export type Entity<T = any> = { __T: T }
export type Id<T = any> = { __T: T }

export type System = {
	system: (world: Jecs.World) -> any?,
	phase: Planck.Phase,
}

export type HealthData = {
	current: number,
	max: number,
}

export type AttackStatsData = {
	damage: number,
	cooldown: number,
	lastAttackTime: number,
}

export type PathFollowerData = {
	pathId: number,
	distance: number,
}

export type EnemyStatsData = {
	health: number,
	speed: number,
	reward: number,
	enemyType: string,
}

export type DisplayInfoData = {
	name: string,
	typeId: string,
}

export type PathData = {
	waypoints: { Vector3 },
	totalLength: number,
}

export type TowerMetadata = {
	DisplayName: string,
	Damage: number,
	Range: number,
	AttackCooldown: number,
	Cost: number,
	CanTargetFlying: boolean,
	IsAreaOfEffect: boolean,
}

export type EnemyMetadata = {
	DisplayName: string,
	Health: number,
	Speed: number,
	Reward: number,
	Flying: boolean,
	Boss: boolean,
}

export type SpawnEntry = {
	enemyType: string,
	delay: number,
	pathName: string,
}

export type WaveMetadata = {
	spawns: { SpawnEntry },
	reward: number,
}

export type WaveStateData = {
	currentWave: number,
	waveStartTime: number,
	isActive: boolean,
	allSpawnsEmitted: boolean,
	spawnedIndices: { [number]: boolean },
	activeEnemies: { [number]: boolean },
	gameStartTime: number,
}

return {}
