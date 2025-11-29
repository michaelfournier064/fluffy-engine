# res://scripts/utilities/custom_button.gd
extends Button
class_name CustomButton

signal pressed_confirmed

@export var hover_scale: float = 1.03
@export var press_scale: float = 0.98
@export var anim_duration: float = 0.08
@export var play_hover_sound: bool = true  # toggle if you only want click sounds

var _tween: Tween
var _base_scale: Vector2
var _hovered := false
var _pressed := false

func _ready() -> void:
	_base_scale = scale
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_mouse_entered() -> void:
	_hovered = true
	_animate_scale(_base_scale * hover_scale)
	if play_hover_sound:
		UserInterfaceAudio.play_hover()

func _on_mouse_exited() -> void:
	_hovered = false
	if not _pressed:
		_animate_scale(_base_scale)

func _on_button_down() -> void:
	_pressed = true
	_animate_scale(_base_scale * press_scale)

func _on_button_up() -> void:
	var is_click := _pressed and (_hovered or has_focus())
	_pressed = false
	if is_click:
		UserInterfaceAudio.play_click()
		pressed_confirmed.emit()
	_animate_scale(_base_scale * (hover_scale if _hovered else 1.0))

func _animate_scale(target: Vector2) -> void:
	if not is_inside_tree():
		return
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.tween_property(self, "scale", target, anim_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
