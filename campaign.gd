extends RefCounted

const SEASON_DAYS := 5
const SEASONS := ["春季", "夏季", "秋季", "冬季"]
const DAILY_NAMES := ["运回 %d 木头", "运回 %d 食物", "运回 %d 水", "勘探 %d 格新地", "完成 %d 项工程"]
const QUEST_XP := 3
const QUEST_WOOD := 2
enum Spell { FARMING, ROAD, SATCHEL, FORESTRY, HUSBANDRY, CARPENTRY, WAREHOUSING, COTTAGE, TOWNHOUSE, ROAD_ARRAY }
const RESEARCH := [
	["农业研习", "开放基础农田，安排居民耕作可持续收获食物。", "journal", -1, 0],
	["绘路符", "允许建造木桥。可以在一块已探明陆地上绘符，使居民在该格的移动耗时减少 35%。同一时间可维持一枚符。", "talisman", -1, 0],
	["缩物袋", "每名取货员的单趟载量增加 6。", "chest", Spell.ROAD, 0],
	["林业研习", "开放树场，安排居民管理可持续收获木头。", "wood", Spell.FARMING, 1],
	["畜养研习", "开放牧场，安排居民照料可持续收获食物。", "meat", Spell.FARMING, 1],
	["工匠研习", "开放木工作坊。完工后，建造和升级少花 4 木头。", "wood", -1, 1],
	["扩仓符", "开放大型仓库。每座仓库完工后新增 120 库位。", "chest", Spell.CARPENTRY, 2],
	["固梁符", "开放二级住房。升级后，每栋住房可多住一位居民。", "talisman", Spell.CARPENTRY, 1],
	["石基符", "开放三级住房。升级后，每栋住房可再多住一位居民。", "stone", Spell.COTTAGE, 2],
	["连路符阵", "可同时维持三枚道路符。符阵已满时，布置新符会移走最早绘制的一枚。", "talisman", Spell.ROAD, 1],
]
var level := 1
var experience := 0
var points := 0
var learned := []
var claimed := [false, false, false]
var targets: Array[int] = [6, 1, 1]
var daily_resource := 0
var explored := 0
var built := 0


func _init() -> void:
	learned.resize(RESEARCH.size())
	learned.fill(false)


func next_day(day: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 9187 + 513
	daily_resource = (day - 1) % 3 if day <= 3 else rng.randi_range(0, 2)
	targets = [(6 if daily_resource == 0 else 3) * rng.randi_range(1, 2), rng.randi_range(1, 2), 1]
	explored = 0
	built = 0
	claimed.fill(false)


func threshold() -> int:
	return 6 + (level - 1) * 2


func earn(amount: int) -> void:
	experience += amount
	while experience >= threshold():
		experience -= threshold()
		level += 1
		points += 1


func task_totals(received: Array[int]) -> Array:
	var delivered := received[daily_resource]
	if daily_resource == 1 and received.size() > 7:
		delivered += received[6] + received[7]
	return [delivered, explored, built]


func pending_tasks(received: Array[int]) -> int:
	var counts := task_totals(received)
	var result := 0
	for index in targets.size():
		result += int(counts[index] >= targets[index] and not claimed[index])
	return result


func revealed(index: int) -> bool:
	var prerequisite: int = RESEARCH[index][3]
	return prerequisite < 0 or learned[prerequisite]


func can_learn(index: int, stage: int) -> bool:
	return index >= 0 and index < learned.size() and points > 0 and not learned[index] and revealed(index) and stage >= RESEARCH[index][4]


func season(day: int) -> String:
	return SEASONS[((day - 1) / SEASON_DAYS) % SEASONS.size()]


func deadline(day: int) -> int:
	return SEASON_DAYS if day <= SEASON_DAYS else SEASON_DAYS * 2
