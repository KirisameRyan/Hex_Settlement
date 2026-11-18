extends TextureRect

const ART := {
	"talisman": preload("res://assets/ui/icons/talisman.png"),
	"chest": preload("res://assets/ui/icons/chest.png"),
	"spyglass": preload("res://assets/ui/icons/spyglass.png"),
	"wood": preload("res://assets/ui/icons/wood.png"),
	"meat": preload("res://assets/ui/icons/meat.png"),
	"water": preload("res://assets/ui/icons/water.png"),
	"stone": preload("res://assets/ui/icons/stone.png"),
	"journal": preload("res://assets/ui/icons/journal.png"),
	"crops": preload("res://assets/ui/icons/crops.png"),
	"iron-ore": preload("res://assets/ui/icons/iron-ore.png"),
	"iron-parts": preload("res://assets/ui/icons/iron-parts.png"),
	"fish": preload("res://assets/ui/icons/fish.png"),
	"repair-fittings": preload("res://assets/ui/icons/repair-fittings.png"),
	"coin": preload("res://assets/ui/icons/coin.png"),
}
const RESOURCES := ["wood", "meat", "water", "stone", "iron-ore", "iron-parts", "crops", "fish", "repair-fittings"]
const COLORS := [Color("#efc290"), Color("#f7ad97"), Color("#9fe4fa"), Color("#c6ccc7"), Color("#c89576"),
	Color("#bdcfe4"), Color("#c4db89"), Color("#8ccddd"), Color("#cbb1e7")]


func _init(kind: int = 0, length := 27.0) -> void:
	setup(self, ART[RESOURCES[kind]], length)


static func prop(name: String, length := 34.0) -> TextureRect:
	var icon := TextureRect.new()
	setup(icon, ART[name], length)
	return icon


static func setup(icon: TextureRect, art: Texture2D, length: float) -> void:
	icon.texture = art
	icon.custom_minimum_size = Vector2(length, length)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
