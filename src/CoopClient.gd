extends Node

# The URL we will connect to

# Our WebSocketClient instance
var _client = WebSocketClient.new()
var connected_to = ""
onready var connect_status = $"/root/Tracker/GUILayer/GUI/CoopClientContainer/CoopClientConnect/Shadow/Container/BG/Control/StatusText"
onready var gui_status = $"/root/Tracker/GUILayer/GUI/Container/Margin/HSplitContainer/Entrances/Dungeons/MarginContainer/VBoxContainer/HBoxContainer2/CoopStatus"
onready var gui_status_container = $"/root/Tracker/GUILayer/GUI/Container/Margin/HSplitContainer/Entrances/Dungeons/MarginContainer/VBoxContainer/HBoxContainer2"
onready var gui_label_container = $"/root/Tracker/GUILayer/GUI/Container/Margin/HSplitContainer/Entrances/Dungeons/MarginContainer/VBoxContainer/HBoxContainer"
const TODO_TEXTURE = preload("res://assets/icons/todo.png");
const CHECKED_GREY = Color("282626")

func _ready():
    # Connect base signals to get notified of connection open, close, and errors.
    _client.connect("connection_closed", self, "_closed")
    _client.connect("connection_error", self, "_closed")
    _client.connect("connection_established", self, "_connected")
    _client.connect("data_received", self, "_on_data")
    Events.connect("coop_send_update", self, "_send_update")
    Events.connect("connect_to_coop_server", self, "_on_connect_to_server")

func _on_connect_to_server(websocket_url) -> void:
    # Initiate connection to the given URL.
    var err = _client.connect_to_url(websocket_url, [])
    if err != OK:
        connect_status.text = "Unable to connect"
    connected_to = websocket_url

func _closed(_was_clean = false):
    connect_status.text = "Connection closed"
    gui_status.text = "Disconnected"

func _connected(_proto = ""):
    connect_status.text = "Connected to " + connected_to
    gui_status_container.show()
    gui_label_container.show()
    if (!Util.coop_server):
        gui_status.text = "Connected"

func _send_update(data: Dictionary) -> void:
    if _client.get_connected_host() == "":
        return
    _client.get_peer(1).put_packet(JSON.print(data).to_utf8())

func _on_data():
    var pkt = parse_json(_client.get_peer(1).get_packet().get_string_from_utf8())
    if typeof(pkt) != TYPE_DICTIONARY:
        return
    if pkt['event'] == "update_marker":
        Events.emit_signal("coop_update_marker", pkt)

    elif pkt['event'] == "remove_marker":
        Events.emit_signal("coop_remove_marker", pkt.uuid)

    elif pkt['event'] == "toggle_todo":
        var icon = get_node(pkt['node_path'])
        if (icon.get_pressed_texture() != TODO_TEXTURE):
            icon.set_pressed_texture(TODO_TEXTURE)
        if (icon.get_parent().self_modulate != CHECKED_GREY) and !icon.is_pressed():
            icon.set_pressed(pkt['is_pressed'])

    elif pkt['event'] == "toggle_button":
        var button = get_node(pkt['node_path'])
        button.set_pressed(false)
        if button.get_parent().self_modulate != CHECKED_GREY && pkt['checked']:
            button.get_parent().self_modulate = CHECKED_GREY
        elif button.get_parent().self_modulate == CHECKED_GREY && !pkt['checked']:
            button.get_parent().self_modulate = Color.white

    elif pkt['event'] == "add_location":
        var location = get_node(pkt['node_path'])
        location.show()
        Util.remove_hidden(location)

    elif pkt['event'] == "remove_location":
        var location = get_node(pkt['node_path'])
        location.hide()
        Util.add_hidden(location)

func _process(delta):
    _client.poll()
