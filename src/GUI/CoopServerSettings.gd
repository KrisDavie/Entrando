extends Control
onready var selected_port = $PortNum

onready var start_button = $Start 
onready var close_button = $Close

onready var shadow = $"/root/Tracker/GUILayer/GUI/CoopServerContainer/CoopServerSettings/Shadow"
onready var server_status = $"/root/Tracker/GUILayer/GUI/CoopServerContainer/CoopServerSettings/Shadow/Container/BG/Control/StatusText"

func _ready() -> void:
    Events.connect('set_discovered_devices', self, '_on_devices_discovered')
    Events.connect('set_connected_device', self, '_on_set_connected_device')
    close_button.connect('pressed', self, '_on_close_pressed')
    start_button.connect('pressed', self, '_on_start_pressed')


func _on_start_pressed() -> void:
    Events.emit_signal('start_coop_server', int(selected_port.get_line_edit().text))

func _on_close_pressed() -> void:
    shadow.hide()