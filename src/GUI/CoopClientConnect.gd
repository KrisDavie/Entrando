extends Control
onready var server_info = $ServerInfo

onready var connect_button = $Connect 
onready var close_button = $Close

onready var shadow = $"/root/Tracker/GUILayer/GUI/CoopClientContainer/CoopClientConnect/Shadow"
onready var connect_status = $"/root/Tracker/GUILayer/GUI/CoopClientContainer/CoopClientConnect/Shadow/Container/BG/Control/StatusText"

var regex = RegEx.new()


func _ready() -> void:
    Events.connect('set_discovered_devices', self, '_on_devices_discovered')
    Events.connect('set_connected_device', self, '_on_set_connected_device')
    close_button.connect('pressed', self, '_on_close_pressed')
    connect_button.connect('pressed', self, '_on_start_pressed')


func _on_start_pressed() -> void:
    var server_address = server_info.text
    if server_address == "":
        server_address = server_info.placeholder_text
    regex.compile("^wss?://[a-zA-Z0-9.-]+:[0-9]+$")
    if not regex.search(server_address):
        connect_status.text = "Invalid server address"
        return
    connect_status.text = "Connecting to server..."
    Events.emit_signal('connect_to_coop_server', server_address)

func _on_close_pressed() -> void:
    shadow.hide()