class_name ItemData
extends Resource

enum Kelas {MAIN, CONSUMABLE, MISC,}
@export var type: Kelas
@export var item_name: String
@export var health: int
@export var mana: int
@export var stackable: bool
@export var count: int
@export_multiline var item_description: String
@export var item_texture: Texture2D
