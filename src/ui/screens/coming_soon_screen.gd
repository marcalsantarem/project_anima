class_name ComingSoonScreen
extends Control
## Placeholder "Em breve" para destinos do hangar ainda sem tela (T-200, BRF-144). Sem arte: o visual
## final é do T-201. Recebe o título por `setup_title(text)` e emite `back_requested` no "Voltar".

signal back_requested

const TXT_SOON := "Em breve"
const TXT_BACK := "Voltar"

var title_text := ""
@onready var _title: Label = %Title
@onready var _back: Button = %Back


func setup_title(text: String) -> void:
	title_text = text
	if is_node_ready():
		_title.text = text


func _ready() -> void:
	_title.text = title_text
	%Soon.text = TXT_SOON
	_back.text = TXT_BACK
	_back.pressed.connect(back_requested.emit)
