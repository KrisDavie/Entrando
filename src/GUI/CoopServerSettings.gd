extends Control
onready var selected_port = $PortNum

onready var start_button = $Start
onready var close_button = $Close
onready var copy_button = $Copy

var upnp = null
var upnp_port = null
var server_status = null
var hint_text = ""

onready var shadow = $"/root/Tracker/GUILayer/GUI/CoopServerContainer/CoopServerSettings/Shadow"

var server_address = ""

func _ready() -> void:
    Events.connect('set_discovered_devices', self, '_on_devices_discovered')
    Events.connect('set_connected_device', self, '_on_set_connected_device')
    Events.connect('coop_server_started', self, '_on_server_started')
    Events.connect('coop_server_stopped', self, '_on_server_stopped')
    close_button.connect('pressed', self, '_on_close_pressed')
    start_button.connect('pressed', self, '_on_start_pressed')
    copy_button.connect('pressed', self, '_on_copy_pressed')

func _on_server_started(ip) -> void:
    server_address = "ws://" + ip
    server_status = "Running"
    start_button.text = "Stop Co-op Server"
    hint_text = start_button.hint_tooltip
    start_button.hint_tooltip = ""
    copy_button.show()

func _on_server_stopped() -> void:
    server_status = "Stopped"
    start_button.text = "Start Co-op Server"
    start_button.hint_tooltip = hint_text
    copy_button.hide()

func _on_copy_pressed() -> void:
    OS.set_clipboard(server_address)

func _on_start_pressed() -> void:
    if server_status == "Running":
        Events.emit_signal('stop_coop_server')
        return
    else:
        _upnp_setup(int(selected_port.get_line_edit().text))
    

func _on_close_pressed() -> void:
    shadow.hide()

func _on_upnp_completed(_err):
    Events.emit_signal('start_coop_server', int(selected_port.get_line_edit().text))

func _upnp_setup(server_port):
    # UPNP queries take some time.
    upnp = UPNP.new()
    var err = upnp.discover()

    if err != OK:
        push_error(str(err))
        _on_upnp_completed(err)
        return

    if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
        upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "UDP")
        upnp.add_port_mapping(server_port, server_port, ProjectSettings.get_setting("application/config/name"), "TCP")
        upnp_port = server_port
        _on_upnp_completed(OK)
    else:
        _on_upnp_completed(ERR_CANT_CONNECT)


func _exit_tree():
    if (upnp != null and upnp_port != null):
        upnp.delete_port_mapping(upnp_port, "UDP")
        upnp.delete_port_mapping(upnp_port, "TCP")
