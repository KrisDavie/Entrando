extends Node

var _server = WebSocketServer.new()
var _clients = {}
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY
var _use_multiplayer = true

onready var server_status = $"/root/Tracker/GUILayer/GUI/CoopServerContainer/CoopServerSettings/Shadow/Container/BG/Control/StatusText"
onready var gui_status = $"/root/Tracker/GUILayer/GUI/Container/Margin/HSplitContainer/Entrances/Dungeons/MarginContainer/VBoxContainer/HBoxContainer2/CoopStatus"
onready var gui_status_container = $"/root/Tracker/GUILayer/GUI/Container/Margin/HSplitContainer/Entrances/Dungeons/MarginContainer/VBoxContainer/HBoxContainer2"
onready var gui_label_container = $"/root/Tracker/GUILayer/GUI/Container/Margin/HSplitContainer/Entrances/Dungeons/MarginContainer/VBoxContainer/HBoxContainer"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    _server.connect("client_connected", self, "_connected")
    _server.connect("client_disconnected", self, "_disconnected")
    _server.connect("client_close_request", self, "_close_request")
    _server.connect("data_received", self, "_on_data")
    Events.connect("start_coop_server", self, "_on_start_coop_server")
    Events.connect("stop_coop_server", self, "_on_stop_coop_server")


func _on_start_coop_server(port: int) -> void:
    server_status.text = "Starting server..."
    var ip_address = Util.get_external_ip_address()
    var err = _server.listen(port)
    if err != OK:
        return
    server_status.text = "Server started on " + ip_address + ":" + str(port)
    Events.emit_signal('connect_to_coop_server', "ws://127.0.0.1:" + str(port))
    Events.emit_signal('coop_server_started', ip_address + ":" + str(port))
    gui_status.text = "Server Running"
    Util.coop_server = true
    gui_status_container.show()
    gui_label_container.show()

func _on_stop_coop_server() -> void:
    server_status.text = "Stopping server..."
    _server.stop()
    gui_status_container.hide()
    gui_label_container.hide()
    Events.emit_signal('coop_server_stopped')
    Util.coop_server = false
    server_status.text = "Server Stopped"
    _clients.clear()

    
func _connected(id, _proto):
    _clients[id] = true
    if (len(_clients) > 1):
        gui_status.text = "Server Running [" + str(len(_clients)-1) + " clients]"

func _close_request(id, _code, _reason):
    _clients.erase(id)

func _disconnected(id, _was_clean = false):
    _clients.erase(id)

func _on_data(id):
    var pkt = _server.get_peer(id).get_packet()
    # Broadcast the packet to all clients except the one that sent it.
    for client_id in _clients.keys():
        if client_id != id:
            _server.get_peer(client_id).put_packet(pkt)

func _process(delta):
    _server.poll()
