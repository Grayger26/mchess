extends Control

@onready var hp_num_label: Label = $HpNumLabel
@onready var ap_num_label: Label = $ApNumLabel

@onready var player := get_tree().get_first_node_in_group("player") as Player
@onready var under_hp_bar: TextureProgressBar = $ProgressBars/HpProgressBar/UnderHpBar
@onready var hp_bar: TextureProgressBar = $ProgressBars/HpProgressBar/HpBar
@onready var under_mana_bar: TextureProgressBar = $ProgressBars/ManaProgressBar/UnderManaBar
@onready var mana_bar: TextureProgressBar = $ProgressBars/ManaProgressBar/ManaBar

var hp_tween: Tween
var ap_tween: Tween

const UNDER_BAR_DELAY := 1
const UNDER_BAR_TIME := 2


func _ready() -> void:
	if not player:
		push_error("Player not found")
		return

	player.ap_changed.connect(_on_player_ap_changed)
	player.hp_changed.connect(_on_player_hp_changed)

	# initial values
	_on_player_ap_changed(player.ap, player.max_ap)
	_on_player_hp_changed(player.hp, player.max_hp)
	
	set_progress_bars()


func _on_player_ap_changed(current_ap: int, _max_ap: int) -> void:
	set_ap(current_ap)


func _on_player_hp_changed(current_hp: int, _max_hp: int) -> void:
	hp_num_label.text = str(current_hp) + " / " + str(player.max_hp)
	hp_bar.value = current_hp

	_animate_under_hp(current_hp)


func set_ap(value: int) -> void: 
	if not ap_num_label: 
		push_error("ap_num_label is NULL — check node path") 
		return 
	ap_num_label.text = str(value) + " / " + str(player.max_ap)
	mana_bar.value = player.ap
	_animate_under_mana(value)
	

func set_progress_bars():
	hp_bar.max_value = player.max_hp
	under_hp_bar.max_value = player.max_hp
	under_hp_bar.value = player.hp
	hp_bar.value = player.hp
	mana_bar.max_value = player.max_ap
	under_mana_bar.max_value = player.max_ap
	under_mana_bar.value = player.ap
	mana_bar.value = player.ap

func _animate_under_hp(target_value: int) -> void:
	if hp_tween:
		hp_tween.kill()

	var current := under_hp_bar.value
	var is_damage := target_value < current

	hp_tween = create_tween()
	hp_tween.set_trans(Tween.TRANS_CUBIC)
	hp_tween.set_ease(Tween.EASE_IN_OUT)

	var track := hp_tween.tween_property(
		under_hp_bar,
		"value",
		target_value,
		UNDER_BAR_TIME
	)

	if is_damage:
		track.set_delay(UNDER_BAR_DELAY)


func _animate_under_mana(target_value: int) -> void:
	if ap_tween:
		ap_tween.kill()

	var current := under_mana_bar.value
	var is_spend := target_value < current

	ap_tween = create_tween()
	ap_tween.set_trans(Tween.TRANS_CUBIC)
	ap_tween.set_ease(Tween.EASE_IN_OUT)

	var track := ap_tween.tween_property(
		under_mana_bar,
		"value",
		target_value,
		UNDER_BAR_TIME
	)

	if is_spend:
		track.set_delay(UNDER_BAR_DELAY)
