extends Node

var _server = WebSocketServer.new()
var _clients = {}
var _write_mode = WebSocketPeer.WRITE_MODE_BINARY
var _use_multiplayer = true
var last_connected_client = 0

onready var server_status = $"/root/Tracker/GUILayer/GUI/CoopServerContainer/CoopServerSettings/Shadow/Container/BG/Control/StatusText"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    _server.connect("client_connected", self, "_connected")
    _server.connect("client_disconnected", self, "_disconnected")
    _server.connect("client_close_request", self, "_close_request")
    _server.connect("data_received", self, "_on_data")
    Events.connect("start_coop_server", self, "_on_start_coop_server")


func _on_start_coop_server(port: int) -> void:
    print("Starting Co-op server on port", port)
    server_status.text = "Starting server..."
    var ip_address = Util.get_external_ip_address()
    var err = _server.listen(port)
    if err != OK:
        print("Unable to start server")
        set_process(false)
    server_status.text = "Server started on " + ip_address + ":" + str(port)
    Events.emit_signal('connect_to_coop_server', "ws://127.0.0.1:" + str(port))

    
func _connected(id, proto):
    _clients[id] = true
    print("Client %d connected with protocol: %s" % [id, proto])

func _close_request(id, code, reason):
    _clients.erase(id)
    print("Client %d disconnecting with code: %d, reason: %s" % [id, code, reason])

func _disconnected(id, was_clean = false):
    _clients.erase(id)
    print("Client %d disconnected, clean: %s" % [id, str(was_clean)])

func _on_data(id):
    var pkt = _server.get_peer(id).get_packet()
    # Broadcast the packet to all clients except the one that sent it.
    for client_id in _clients.keys():
        if client_id != id:
            _server.get_peer(client_id).put_packet(pkt)

func _process(delta):
    _server.poll()