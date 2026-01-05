class_name Serializer

# TODO: !IMPORTANT! all of this needs validation
# TODO: !IMPORTANT! all of this needs validation
# TODO: !IMPORTANT! all of this needs validation

# -------------------------------------------------------------------------------------------------
const BRUSH_STROKE = preload("res://BrushStroke/BrushStroke.tscn")
const COMPRESSION_METHOD = FileAccess.COMPRESSION_DEFLATE
const POINT_ELEM_SIZE := 3

const VERSION_NUMBER := 1
const TYPE_BRUSH_STROKE := 0
const TYPE_ERASER_STROKE_DEPRECATED := 1 # Deprecated since v0; will be ignored when read; structually the same as normal brush stroke

# -------------------------------------------------------------------------------------------------
static func save_project(project: Project) -> void:
	var start_time := Time.get_ticks_msec()
	
	# Open file
	var file := FileAccess.open_compressed(project.filepath, FileAccess.WRITE, COMPRESSION_METHOD)
	if file == null:
		print_debug("Failed to open file for writing: %s" % project.filepath)
		return
	
	# Meta data
	file.store_32(VERSION_NUMBER)
	file.store_pascal_string(_dict_to_metadata_str(project.meta_data))
	
	# Stroke data
	for stroke: BrushStroke in project.strokes:
		# Type
		file.store_8(TYPE_BRUSH_STROKE)
		
		# Color
		file.store_8(stroke.color.r8)
		file.store_8(stroke.color.g8)
		file.store_8(stroke.color.b8)
		
		# Brush size
		file.store_16(int(stroke.size))
		
		# Number of points
		file.store_16(stroke.points.size())
		
		# Points
		var p_idx := 0
		for p in stroke.points:
			# Add global_position offset which is != 0 when moved by move tool; but mostly it should just add 0
			file.store_float(p.x + stroke.global_position.x)
			file.store_float(p.y + stroke.global_position.y)
			var pressure: int = clamp(int(stroke.pressures[p_idx] * 255), 0, 255)
			file.store_8(pressure)
			p_idx += 1

	# Done
	file.close()
	print("Saved %s in %d ms" % [project.filepath, (Time.get_ticks_msec() - start_time)])

# -------------------------------------------------------------------------------------------------
static func load_project(project: Project) -> void:
	var start_time := Time.get_ticks_msec()

	# Check if this is a DXF file
	if project.filepath.get_extension().to_lower() == ".dxf":
		_load_project_from_dxf(project)
		return
	
	# Open file (original GOCAD format)
	var file := FileAccess.open_compressed(project.filepath, FileAccess.READ, COMPRESSION_METHOD)
	if file == null:
		print_debug("Failed to load file: %s" % project.filepath)
		return
	
	# Clear potential previous data
	project.strokes.clear()
	project.meta_data.clear()
	
	# Meta data
	var _version_number := file.get_32()
	var meta_data_str := file.get_pascal_string()
	project.meta_data = _metadata_str_to_dict(meta_data_str)
	
	# Brush strokes
	while true:
		# Type
		var type := file.get_8()
		
		match type:
			TYPE_BRUSH_STROKE, TYPE_ERASER_STROKE_DEPRECATED:
				var brush_stroke: BrushStroke = BRUSH_STROKE.instantiate()
				
				# Color
				var r := file.get_8()
				var g := file.get_8()
				var b := file.get_8()
				brush_stroke.color = Color(r/255.0, g/255.0, b/255.0, 1.0)
				
				# Brush size
				brush_stroke.size = file.get_16()
					
				# Number of points
				var point_count := file.get_16()

				# Points
				for i: int in point_count:
					var x := file.get_float()
					var y := file.get_float()
					var pressure := float(file.get_8()) / 255.0
					brush_stroke.points.append(Vector2(x, y))
					brush_stroke.pressures.append(pressure)
				
				if type == TYPE_ERASER_STROKE_DEPRECATED:
					print("Skipped deprecated eraser stroke: %d points" % point_count)
				else:
					project.strokes.append(brush_stroke)
			_:
				printerr("Invalid type")
		
		# are we done yet?
		if file.get_position() >= file.get_length()-1 || file.eof_reached():
			break
	
	# Done
	file.close()
	print("Loaded %s in %d ms" % [project.filepath, (Time.get_ticks_msec() - start_time)])

# -------------------------------------------------------------------------------------------------
static func _load_project_from_dxf(project: Project) -> void:
	var start_time := Time.get_ticks_msec()
	
	var DXFReader = load("res://ProjectManager/DXFReader.gd")
	if not DXFReader:
		print("无法加载 DXFReader 类")
		return
	
	var reader = DXFReader.new()
	var dxf_doc = reader.import_from_dxf(project.filepath)
	
	if not dxf_doc:
		print("无法导入 DXF 文件: %s" % project.filepath)
		return
	
	# Clear potential previous data
	project.strokes.clear()
	
	# 打印 DXF 文件简略信息
	print("DXF 文件信息:")
	print("  版本: %s" % dxf_doc.version)
	print("  实体数量: %d" % dxf_doc.entities.size())
	
	# 统计不同类型的实体
	var entity_counts: Dictionary = {}
	for entity in dxf_doc.entities:
		var entity_type_name = "未知"
		if entity.has_method("_get_entity_type_name"):
			entity_type_name = entity._get_entity_type_name()
		elif entity.has("type"):
			# 尝试从 type 属性获取类型名称
			var type_value = entity.type
			if type_value == 0:
				entity_type_name = "LINE"
			elif type_value == 1:
				entity_type_name = "CIRCLE"
			elif type_value == 2:
				entity_type_name = "ARC"
			elif type_value == 3:
				entity_type_name = "LWPOLYLINE"
			else:
				entity_type_name = "其他"
		
		if entity_counts.has(entity_type_name):
			entity_counts[entity_type_name] += 1
		else:
			entity_counts[entity_type_name] = 1
	
	# 打印实体统计信息
	print("  实体类型统计:")
	for entity_type in entity_counts.keys():
		print("    %s: %d" % [entity_type, entity_counts[entity_type]])
	
	# 将 DXF 实体转换为笔画
	var EntityConverter = load("res://ProjectManager/EntityConverter.gd")
	if EntityConverter:
		var converter = EntityConverter.new()
		
		for entity in dxf_doc.entities:
			var stroke = converter.entity_to_stroke(entity)
			if stroke:
				project.strokes.append(stroke)
	else:
		print("无法加载 EntityConverter 类")
	
	print("从 DXF 文件加载完成，用时 %d ms" % (Time.get_ticks_msec() - start_time))

# -------------------------------------------------------------------------------------------------
static func _dict_to_metadata_str(d: Dictionary) -> String:
	var meta_str := ""
	for k: Variant in d.keys():
		var v: Variant = d[k]
		if k is String && v is String:
			meta_str += "%s=%s," % [k, v]
		else:
			print_debug("Metadata should be String key-value pairs only!")
	return meta_str

# -------------------------------------------------------------------------------------------------
static func _metadata_str_to_dict(s: String) -> Dictionary:
	var meta_dict := {}
	for kv: String in s.split(",", false):
		var kv_split: PackedStringArray = kv.split("=", false)
		if kv_split.size() != 2:
			print_debug("Invalid metadata key-value pair: %s" % kv)
		else:
			meta_dict[kv_split[0]] = kv_split[1]
	return meta_dict
