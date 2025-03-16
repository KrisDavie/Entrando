extends Control
onready var selected_port = $PortNum

onready var start_button = $Start
onready var close_button = $Close
onready var copy_button = $Copy

onready var shadow = $"/root/Tracker/GUILayer/GUI/CoopServerContainer/CoopServerSettings/Shadow"
var server_address = ""

func _ready() -> void:
    Events.connect('set_discovered_devices', self, '_on_devices_discovered')
    Events.connect('set_connected_device', self, '_on_set_connected_device')
    Events.connect('coop_server_started', self, '_on_server_started')
    close_button.connect('pressed', self, '_on_close_pressed')
    start_button.connect('pressed', self, '_on_start_pressed')
    copy_button.connect('pressed', self, '_on_copy_pressed')

func _on_server_started(ip) -> void:
    server_address = ip
    copy_button.show()

func _on_copy_pressed() -> void:
    OS.set_clipboard(server_address)

func _on_start_pressed() -> void:
    Events.emit_signal('start_coop_server', int(selected_port.get_line_edit().text))

func _on_close_pressed() -> void:
    shadow.hide()