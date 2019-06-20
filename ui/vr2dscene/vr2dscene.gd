extends Control

var dim_timer

func _ready() -> void:
	SignalManager.connect("render_targetsize", self, "_on_render_targetsize_changed")
	SignalManager.connect("redraw_overlay", self, "_on_redraw_overlay")
	SignalManager.connect("secrets_loaded", self, "_on_redraw_overlay")
	SignalManager.connect("event_happened", self, "_on_event_happened")
	SignalManager.connect("settings_changed", self, "_on_settings_changed")

	dim_timer = get_node("DimTimer")
	dim_timer.wait_time = SettingsManager.get_value("user", "overlay/dimdownafter", DefaultSettings.get_default_setting("overlay/dimdownafter"))
	
	if SettingsManager.get_value("user", "overlay/dimundim", DefaultSettings.get_default_setting("overlay/dimundim")):
		dim_timer.start()
	
	$VRBackground.color = SettingsManager.get_value("user", "overlay/color", DefaultSettings.get_default_setting("overlay/color"))
	$VRBackground.modulate.a = SettingsManager.get_value("user", "overlay/opacity", DefaultSettings.get_default_setting("overlay/opacity"))

func _on_render_targetsize_changed(size : Vector2) -> void:
	rect_size = size
	$VRBackground.rect_size = size
	$WidgetsContainer.rect_size = size	

func _on_settings_changed() -> void:
	$WidgetsContainer.modulate.a = 255
	$VRBackground.color = SettingsManager.get_value("user", "overlay/color", DefaultSettings.get_default_setting("overlay/color"))
	$VRBackground.modulate.a = SettingsManager.get_value("user", "overlay/opacity", DefaultSettings.get_default_setting("overlay/opacity"))

	dim_timer.stop()
	dim_timer.wait_time = SettingsManager.get_value("user", "overlay/dimdownafter", DefaultSettings.get_default_setting("overlay/dimdownafter"))

	if SettingsManager.get_value("user", "overlay/dimundim", DefaultSettings.get_default_setting("overlay/dimundim")):
		dim_timer.start()
	
func _on_redraw_overlay() -> void:
	# Remove all widgets
	for i in $WidgetsContainer.get_children():
    	i.queue_free()
	
	# Somehow we need to wait two frames for Godot...
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	# Create fresh widgets
	var arrayWidgets : Array = SettingsManager.get_value("user", "widgets/configuration", DefaultSettings.get_default_setting("widgets/configuration"))
	
	for i in range(0, arrayWidgets.size()):
		var metadata = arrayWidgets[i]
		
		var widget_data : Node = load(metadata["data"]["widget"]).new()
		var widget : Node = load(widget_data.get_widget_render_scene()).instance()
		widget.apply_config(metadata["id"], metadata["data"]["config"])
		widget.set_meta("widget_id", metadata["id"])
		
		if metadata["data"]["parent"]:
			var parentitem : Node = _walk_nodes($WidgetsContainer, metadata["data"]["parent"])
			parentitem.add_child(widget)
		else:
			$WidgetsContainer.add_child(widget)

func _walk_nodes(node, widget_id) -> Node:
	if node.get_meta("widget_id") == widget_id:
		return node
	else:
		var founditem : Node
	
		for i in node.get_children():				
			founditem = _walk_nodes(i, widget_id)
			if founditem: return founditem
		
		return node
	
func _on_DimTimer_timeout():
	$WidgetsContainer.modulate.a = SettingsManager.get_value("user", "overlay/dimdownopacity", DefaultSettings.get_default_setting("overlay/dimdownopacity"))
	$VRBackground.modulate.a = SettingsManager.get_value("user", "overlay/dimdownopacity", DefaultSettings.get_default_setting("overlay/dimdownopacity"))

func _on_event_happened():
	if SettingsManager.get_value("user", "overlay/undimchime", DefaultSettings.get_default_setting("overlay/undimchime")):
		$AudioStreamPlayer.play(0.0)
	
	$WidgetsContainer.modulate.a = 255
	$VRBackground.modulate.a = SettingsManager.get_value("user", "overlay/opacity", DefaultSettings.get_default_setting("overlay/opacity"))
	
	$DimTimer.stop()
	
	if SettingsManager.get_value("user", "overlay/dimundim", DefaultSettings.get_default_setting("overlay/dimundim")):
		$DimTimer.start()
