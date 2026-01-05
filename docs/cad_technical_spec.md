# GOCAD - 技术规格

## 1. 图层系统

### 1.1 数据模型

```gdscript
# Layer.gd
class_name Layer

enum LayerType {
    NORMAL,
    GUIDE,
    DIMENSION,
    REFERENCE
}

var id: int
var name: String = "Unnamed Layer"
var type: LayerType = LayerType.NORMAL
var visible: bool = true
var locked: bool = false
var opacity: float = 1.0
var color: Color = Color(1, 1, 1, 1)
var objects: Array[CADObject] = []

func add_object(obj: CADObject) -> void:
    objects.append(obj)
    obj.layer_id = id

func remove_object(obj: CADObject) -> void:
    objects.erase(obj)
    obj.layer_id = -1

func clear() -> void:
    for obj in objects:
        obj.queue_free()
    objects.clear()
```

### 1.2 图层管理器

```gdscript
# LayerManager.gd
class_name LayerManager extends Node

signal layer_added(layer: Layer)
signal layer_removed(layer_id: int)
signal layer_changed(layer: Layer)
signal active_layer_changed(layer: Layer)

var layers: Array[Layer] = []
var active_layer: Layer

func _init():
    # 创建默认图层
    active_layer = Layer.new()
    active_layer.name = "Layer 1"
    active_layer.id = 0
    layers.append(active_layer)

func create_layer(name: String = "Unnamed Layer", type: Layer.LayerType = Layer.LayerType.NORMAL) -> Layer:
    var new_layer = Layer.new()
    new_layer.id = layers.size()
    new_layer.name = name
    new_layer.type = type
    layers.append(new_layer)
    layer_added.emit(new_layer)
    return new_layer

func remove_layer(layer_id: int) -> void:
    if layer_id == active_layer.id:
        # 不能删除活动图层
        return
    
    for i in range(layers.size()):
        if layers[i].id == layer_id:
            var layer = layers[i]
            layer.clear()
            layers.remove_at(i)
            layer_removed.emit(layer_id)
            break

func set_active_layer(layer_id: int) -> void:
    for layer in layers:
        if layer.id == layer_id:
            active_layer = layer
            active_layer_changed.emit(layer)
            break

func get_layer_by_id(layer_id: int) -> Layer:
    for layer in layers:
        if layer.id == layer_id:
            return layer
    return null

func move_layer_up(layer_id: int) -> void:
    # 实现图层重新排序
    pass

func move_layer_down(layer_id: int) -> void:
    # 实现图层重新排序
    pass
```

### 1.3 与画布集成

```gdscript
# 修改InfiniteCanvas.gd
var layer_manager: LayerManager

func _ready():
    layer_manager = LayerManager.new()
    add_child(layer_manager)
    
    # 连接信号
    layer_manager.layer_added.connect(_on_layer_added)
    layer_manager.layer_removed.connect(_on_layer_removed)
    layer_manager.active_layer_changed.connect(_on_active_layer_changed)

func _on_layer_added(layer: Layer):
    # 更新UI
    pass

func _on_layer_removed(layer_id: int):
    # 清理资源
    pass

func _on_active_layer_changed(layer: Layer):
    # 更新工具以使用新的活动图层
    pass

# 修改add_stroke以支持图层
func add_stroke(stroke: BrushStroke) -> void:
    if _current_project != null:
        layer_manager.active_layer.add_object(stroke)
        _strokes_parent.add_child(stroke)
        info.point_count += stroke.points.size()
        info.stroke_count += 1
```

## 2. 约束系统

### 2.1 约束基类

```gdscript
# Constraint.gd
class_name Constraint extends Resource

enum ConstraintType {
    HORIZONTAL,
    VERTICAL,
    PARALLEL,
    PERPENDICULAR,
    TANGENT,
    FIXED_DISTANCE,
    FIXED_ANGLE,
    COINCIDENT,
    CONCENTRIC
}

var type: ConstraintType
var targets: Array = []  # Array of NodePaths or Object references
var is_satisfied: bool = false
var priority: int = 0

func solve(delta: float) -> bool:
    # 由子类实现
    return false

func visualize() -> void:
    # 由子类实现 - 绘制约束可视化
    pass

func check_satisfied() -> bool:
    # 检查约束是否满足
    return false
```

### 2.2 几何约束实现

```gdscript
# GeometricConstraint.gd
class_name GeometricConstraint extends Constraint

func solve(delta: float) -> bool:
    match type:
        ConstraintType.HORIZONTAL:
            return _solve_horizontal()
        ConstraintType.VERTICAL:
            return _solve_vertical()
        ConstraintType.PARALLEL:
            return _solve_parallel()
        ConstraintType.PERPENDICULAR:
            return _solve_perpendicular()
        ConstraintType.TANGENT:
            return _solve_tangent()
        ConstraintType.COINCIDENT:
            return _solve_coincident()
        ConstraintType.CONCENTRIC:
            return _solve_concentric()
    return false

func _solve_horizontal() -> bool:
    if targets.size() < 2:
        return false
    
    var obj1 = targets[0]
    var obj2 = targets[1]
    
    # 实现水平约束逻辑
    # 这需要复杂的几何计算
    
    return true

# 其他约束解决方法...
```

### 2.3 尺寸约束

```gdscript
# DimensionalConstraint.gd
class_name DimensionalConstraint extends Constraint

var value: float
var dimension_line: Node2D  # 可视化尺寸线

func solve(delta: float) -> bool:
    match type:
        ConstraintType.FIXED_DISTANCE:
            return _solve_fixed_distance()
        ConstraintType.FIXED_ANGLE:
            return _solve_fixed_angle()
    return false

func _solve_fixed_distance() -> bool:
    if targets.size() < 2:
        return false
    
    var obj1 = targets[0]
    var obj2 = targets[1]
    
    # 计算当前距离
    var current_distance = obj1.global_position.distance_to(obj2.global_position)
    
    # 如果距离不匹配，调整对象
    if not is_zero_approx(current_distance - value):
        # 实现距离约束逻辑
        # 这需要考虑对象类型和约束方向
        
        return true
    
    return false

func update_visualization():
    if dimension_line:
        # 更新尺寸线位置和文本
        pass
```

### 2.4 约束管理器

```gdscript
# ConstraintManager.gd
class_name ConstraintManager extends Node

signal constraint_added(constraint: Constraint)
signal constraint_removed(constraint: Constraint)
signal constraint_satisfied(constraint: Constraint)
signal constraint_violated(constraint: Constraint)

var constraints: Array[Constraint] = []
var is_solving: bool = false
var max_iterations: int = 100
var tolerance: float = 0.001

func add_constraint(constraint: Constraint) -> void:
    constraints.append(constraint)
    constraint_added.emit(constraint)
    _queue_solve()

func remove_constraint(constraint: Constraint) -> void:
    constraints.erase(constraint)
    constraint_removed.emit(constraint)
    _queue_solve()

func _queue_solve():
    if is_solving:
        return
    
    is_solving = true
    var iterations = 0
    var all_satisfied = false
    
    while iterations < max_iterations and not all_satisfied:
        all_satisfied = true
        
        # 按优先级排序约束
        constraints.sort_custom(_compare_constraint_priority)
        
        # 尝试解决每个约束
        for constraint in constraints:
            if not constraint.solve(1.0 / (iterations + 1)):
                all_satisfied = false
                constraint_violated.emit(constraint)
            else:
                constraint_satisfied.emit(constraint)
        
        iterations += 1
    
    is_solving = false

func _compare_constraint_priority(a: Constraint, b: Constraint) -> int:
    # 更高优先级的约束先解决
    return b.priority - a.priority

func clear_constraints():
    constraints.clear()

func get_constraints_for_object(obj) -> Array:
    var result = []
    for constraint in constraints:
        if obj in constraint.targets:
            result.append(constraint)
    return result
```

## 3. CAD对象系统

### 3.1 基础CAD对象

```gdscript
# CADObject.gd
class_name CADObject extends Node2D

enum ObjectType {
    LINE,
    RECTANGLE,
    CIRCLE,
    ARC,
    POLYGON,
    TEXT,
    DIMENSION,
    GROUP
}

var object_type: ObjectType
var layer_id: int = 0
var properties: Dictionary = {}
var constraints: Array = []  # Array of Constraint references
var is_selected: bool = false
var is_locked: bool = false
var creation_time: float = 0.0
var modification_time: float = 0.0

signal property_changed(key: String, value: Variant)
signal selected_changed(selected: bool)
signal object_changed()

func _init():
    creation_time = Time.get_unix_time_from_system()
    modification_time = creation_time

func add_constraint(constraint: Constraint):
    constraints.append(constraint)
    constraint.targets.append(self)

func remove_constraint(constraint: Constraint):
    constraints.erase(constraint)
    if self in constraint.targets:
        constraint.targets.erase(self)

func set_property(key: String, value: Variant):
    properties[key] = value
    modification_time = Time.get_unix_time_from_system()
    property_changed.emit(key, value)
    object_changed.emit()

func get_property(key: String, default_value = null):
    return properties.get(key, default_value)

func select():
    is_selected = true
    update()  # 触发视觉更新
    selected_changed.emit(true)

func deselect():
    is_selected = false
    update()  # 触发视觉更新
    selected_changed.emit(false)

func toggle_select():
    is_selected = !is_selected
    update()  # 触发视觉更新
    selected_changed.emit(is_selected)

func lock():
    is_locked = true

func unlock():
    is_locked = false

func duplicate() -> CADObject:
    var new_obj = self.duplicate()
    new_obj.creation_time = Time.get_unix_time_from_system()
    new_obj.modification_time = new_obj.creation_time
    return new_obj

func to_dict() -> Dictionary:
    return {
        "type": object_type,
        "layer_id": layer_id,
        "properties": properties,
        "constraints": [c.type for c in constraints],
        "locked": is_locked,
        "creation_time": creation_time,
        "modification_time": modification_time
    }

func from_dict(data: Dictionary):
    object_type = data.get("type", ObjectType.LINE)
    layer_id = data.get("layer_id", 0)
    properties = data.get("properties", {})
    is_locked = data.get("locked", false)
    # 注意：约束需要单独处理
```

### 3.2 具体CAD对象实现

```gdscript
# CADLine.gd
class_name CADLine extends CADObject

var start_point: Vector2 = Vector2.ZERO
var end_point: Vector2 = Vector2.RIGHT * 100
var line_width: float = 1.0
var line_color: Color = Color.BLACK
var line_style: String = "solid"

func _init():
    .object_type = ObjectType.LINE
    _update_visual()

func set_start_point(point: Vector2):
    start_point = point
    _update_visual()
    modification_time = Time.get_unix_time_from_system()
    object_changed.emit()

func set_end_point(point: Vector2):
    end_point = point
    _update_visual()
    modification_time = Time.get_unix_time_from_system()
    object_changed.emit()

func get_length() -> float:
    return start_point.distance_to(end_point)

func get_angle() -> float:
    return start_point.angle_to_point(end_point)

func _update_visual():
    # 更新可视表示
    queue_redraw()

func _draw():
    var color = line_color if not is_selected else Color.RED
    
    match line_style:
        "solid":
            draw_line(start_point, end_point, color, line_width)
        "dashed":
            _draw_dashed_line(start_point, end_point, color, line_width)
        "dotted":
            _draw_dotted_line(start_point, end_point, color, line_width)

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float):
    var direction = to - from
    var length = direction.length()
    direction = direction.normalized()
    
    var dash_length = 5.0
    var gap_length = 3.0
    var pattern_length = dash_length + gap_length
    
    var current_pos = from
    var remaining = length
    
    while remaining > 0:
        var segment_length = min(dash_length, remaining)
        if segment_length > 0:
            var segment_end = current_pos + direction * segment_length
            draw_line(current_pos, segment_end, color, width)
        
        current_pos += direction * pattern_length
        remaining -= pattern_length
```

## 4. 智能捕捉系统

### 4.1 捕捉点类型

```gdscript
# SnapPoint.gd
class_name SnapPoint

enum SnapType {
    ENDPOINT,
    MIDPOINT,
    CENTER,
    INTERSECTION,
    PERPENDICULAR,
    TANGENT,
    GRID,
    NONE
}

var type: SnapType
var position: Vector2
var owner: CADObject  # 拥有此捕捉点的对象
var priority: int  # 用于解决多个捕捉点冲突

func _init(pos: Vector2, snap_type: SnapType, obj: CADObject = null):
    position = pos
    type = snap_type
    owner = obj
    
    # 设置优先级
    match type:
        SnapType.ENDPOINT: priority = 5
        SnapType.MIDPOINT: priority = 4
        SnapType.CENTER: priority = 4
        SnapType.INTERSECTION: priority = 5
        SnapType.PERPENDICULAR: priority = 3
        SnapType.TANGENT: priority = 3
        SnapType.GRID: priority = 2
        SnapType.NONE: priority = 1
```

### 4.2 捕捉管理器

```gdscript
# SnapManager.gd
class_name SnapManager extends Node

signal snap_point_found(point: SnapPoint)
signal snap_point_lost()

var enabled: bool = true
var snap_radius: float = 10.0  # 像素
var current_snap: SnapPoint = null
var all_snap_points: Array[SnapPoint] = []

var snap_to_grid: bool = true
var snap_to_endpoints: bool = true
var snap_to_midpoints: bool = true
var snap_to_centers: bool = true
var snap_to_intersections: bool = true
var snap_to_perpendicular: bool = true
var snap_to_tangent: bool = true

func _process(delta):
    if not enabled:
        return
    
    # 清除旧的捕捉点
    all_snap_points.clear()
    
    if snap_to_grid:
        _add_grid_snap_points()
    
    # 从所有CAD对象收集捕捉点
    var canvas = get_parent()
    if canvas and canvas.has_method("get_all_cad_objects"):
        var objects = canvas.get_all_cad_objects()
        for obj in objects:
            _add_object_snap_points(obj)

func _add_grid_snap_points():
    var camera = get_viewport().get_camera()
    if camera:
        var grid_size = 25.0  # 从设置中获取
        var visible_rect = get_viewport().get_visible_rect()
        
        # 计算网格线
        var start_x = floor(visible_rect.position.x / grid_size) * grid_size
        var end_x = ceil((visible_rect.position.x + visible_rect.size.x) / grid_size) * grid_size
        var start_y = floor(visible_rect.position.y / grid_size) * grid_size
        var end_y = ceil((visible_rect.position.y + visible_rect.size.y) / grid_size) * grid_size
        
        # 添加水平和垂直网格捕捉点
        for x in range(start_x, end_x + 1, grid_size):
            for y in range(start_y, end_y + 1, grid_size):
                all_snap_points.append(SnapPoint(Vector2(x, y), SnapPoint.SnapType.GRID))

func _add_object_snap_points(obj: CADObject):
    if obj.object_type == CADObject.ObjectType.LINE:
        _add_line_snap_points(obj)
    elif obj.object_type == CADObject.ObjectType.RECTANGLE:
        _add_rectangle_snap_points(obj)
    elif obj.object_type == CADObject.ObjectType.CIRCLE:
        _add_circle_snap_points(obj)
    # 添加其他对象类型...

func _add_line_snap_points(line: CADObject):
    if snap_to_endpoints:
        all_snap_points.append(SnapPoint(line.start_point, SnapPoint.SnapType.ENDPOINT, line))
        all_snap_points.append(SnapPoint(line.end_point, SnapPoint.SnapType.ENDPOINT, line))
    
    if snap_to_midpoints:
        var mid = (line.start_point + line.end_point) / 2.0
        all_snap_points.append(SnapPoint(mid, SnapPoint.SnapType.MIDPOINT, line))

func find_best_snap_point(mouse_pos: Vector2) -> SnapPoint:
    if not enabled or all_snap_points.size() == 0:
        return null
    
    var best_snap = null
    var best_distance = snap_radius
    
    for snap in all_snap_points:
        var distance = mouse_pos.distance_to(snap.position)
        if distance < best_distance:
            best_distance = distance
            best_snap = snap
        elif distance == best_distance:
            # 如果距离相同，选择优先级更高的
            if snap.priority > best_snap.priority:
                best_snap = snap
    
    return best_snap

func get_current_snap() -> SnapPoint:
    return current_snap

func set_current_snap(snap: SnapPoint):
    current_snap = snap
    if snap:
        snap_point_found.emit(snap)
    else:
        snap_point_lost.emit()

func clear_current_snap():
    current_snap = null
    snap_point_lost.emit()
```

### 4.3 与工具集成

```gdscript
# 修改CanvasTool.gd
var snap_manager: SnapManager

func _ready():
    snap_manager = get_node("/root/InfiniteCanvas/SnapManager")
    if snap_manager:
        snap_manager.snap_point_found.connect(_on_snap_point_found)
        snap_manager.snap_point_lost.connect(_on_snap_point_lost)

func _on_snap_point_found(point: SnapPoint):
    # 显示捕捉可视化
    _show_snap_indicator(point)

func _on_snap_point_lost():
    # 隐藏捕捉可视化
    _hide_snap_indicator()

func _process(delta):
    if snap_manager and snap_manager.enabled:
        var mouse_pos = get_global_mouse_position()
        var best_snap = snap_manager.find_best_snap_point(mouse_pos)
        snap_manager.set_current_snap(best_snap)
        
        if best_snap:
            # 使用捕捉位置而不是实际鼠标位置
            mouse_pos = best_snap.position
    
    # 使用mouse_pos进行工具操作
```

## 5. 尺寸标注系统

### 5.1 尺寸标注对象

```gdscript
# Dimension.gd
class_name Dimension extends CADObject

enum DimensionType {
    LINEAR,      # 线性尺寸
    ALIGNED,     # 对齐尺寸
    ANGULAR,     # 角度尺寸
    RADIAL,      # 半径尺寸
    DIAMETRIC,   # 直径尺寸
}

var dimension_type: DimensionType = DimensionType.LINEAR
var reference_objects: Array = []  # 被测量的对象
var measurement: float = 0.0
var text_position: Vector2
var text_content: String
var precision: int = 2  # 小数位数
var units: String = "mm"  # 单位

# 视觉元素
var line_color: Color = Color.BLUE
var text_color: Color = Color.BLACK
var extension_line_length: float = 10.0
var arrow_size: float = 5.0

func _init():
    .object_type = ObjectType.DIMENSION
    update_measurement()

func set_reference_objects(objects: Array):
    reference_objects = objects
    update_measurement()

func update_measurement():
    if reference_objects.size() < 2:
        return
    
    match dimension_type:
        DimensionType.LINEAR:
            _update_linear_measurement()
        DimensionType.ALIGNED:
            _update_aligned_measurement()
        DimensionType.ANGULAR:
            _update_angular_measurement()
        DimensionType.RADIAL:
            _update_radial_measurement()
        DimensionType.DIAMETRIC:
            _update_diametric_measurement()

func _update_linear_measurement():
    if reference_objects.size() >= 2:
        var obj1 = reference_objects[0]
        var obj2 = reference_objects[1]
        
        # 对于线性尺寸，我们测量水平或垂直距离
        var point1 = obj1.global_position
        var point2 = obj2.global_position
        
        measurement = abs(point2.x - point1.x)  # 水平尺寸
        text_content = "%%.%df %s" % [precision, measurement, units]
        
        # 更新文本位置
        text_position = Vector2((point1.x + point2.x) / 2, min(point1.y, point2.y) - 15)

func _update_aligned_measurement():
    if reference_objects.size() >= 2:
        var obj1 = reference_objects[0]
        var obj2 = reference_objects[1]
        
        var point1 = obj1.global_position
        var point2 = obj2.global_position
        
        measurement = point1.distance_to(point2)
        text_content = "%%.%df %s" % [precision, measurement, units]
        
        # 文本位置在中间，垂直于连接线
        var mid = (point1 + point2) / 2
        var angle = point1.angle_to_point(point2) + PI/2
        text_position = mid + Vector2(cos(angle), sin(angle)) * 15

func _draw():
    match dimension_type:
        DimensionType.LINEAR:
            _draw_linear_dimension()
        DimensionType.ALIGNED:
            _draw_aligned_dimension()
        DimensionType.ANGULAR:
            _draw_angular_dimension()
        DimensionType.RADIAL:
            _draw_radial_dimension()
        DimensionType.DIAMETRIC:
            _draw_diametric_dimension()

func _draw_linear_dimension():
    if reference_objects.size() < 2:
        return
    
    var obj1 = reference_objects[0]
    var obj2 = reference_objects[1]
    var point1 = obj1.global_position
    var point2 = obj2.global_position
    
    # 绘制尺寸线
    var dim_y = min(point1.y, point2.y) - 10
    draw_line(Vector2(point1.x, dim_y), Vector2(point2.x, dim_y), line_color, 1.0)
    
    # 绘制延长线
    draw_line(point1, Vector2(point1.x, dim_y), line_color, 1.0)
    draw_line(point2, Vector2(point2.x, dim_y), line_color, 1.0)
    
    # 绘制箭头
    _draw_arrow(Vector2(point1.x, dim_y), Vector2(point2.x, dim_y))
    _draw_arrow(Vector2(point2.x, dim_y), Vector2(point1.x, dim_y))
    
    # 绘制文本
    draw_string(get_font("dimension"), text_position, text_content, text_color)

func _draw_arrow(start: Vector2, end: Vector2):
    var direction = (end - start).normalized()
    var perpendicular = Vector2(-direction.y, direction.x) * arrow_size
    
    var arrow_points = [
        end,
        end - direction * arrow_size * 2 + perpendicular,
        end - direction * arrow_size * 2 - perpendicular
    ]
    
    draw_polyline(arrow_points, [line_color], 1.0, true)
```

## 6. 文件格式支持

### 6.1 DXF导出器

```gdscript
# DXFExporter.gd
class_name DXFExporter

var header: String = """
0
SECTION
2
HEADER
9
$ACADVER
1
AC1009
9
$INSBASE
10
0.0
20
0.0
30
0.0
0
ENDSEC
"""

var tables: String = """
0
SECTION
2
TABLES
0
TABLE
2
LTYPE
70
1
0
LTYPE
2
CONTINUOUS
70
64
3
Solid line
72
65
73
0
0
ENDTAB
0
TABLE
2
LAYER
70
1
0
LAYER
2
0
70
64
62
7
6
CONTINUOUS
0
ENDTAB
0
ENDSEC
"""

func export_to_dxf(objects: Array, filepath: String) -> void:
    var file = File.new()
    file.open(filepath, File.WRITE)
    
    # 写入头部
    file.store_string(header)
    
    # 写入表
    file.store_string(tables)
    
    # 开始实体部分
    file.store_string("0\nSECTION\n2\nENTITIES\n")
    
    # 导出每个对象
    for obj in objects:
        _export_object(file, obj)
    
    # 结束文件
    file.store_string("0\nENDSEC\n0\nEOF\n")
    file.close()

func _export_object(file: File, obj: CADObject):
    match obj.object_type:
        CADObject.ObjectType.LINE:
            _export_line(file, obj)
        CADObject.ObjectType.CIRCLE:
            _export_circle(file, obj)
        CADObject.ObjectType.RECTANGLE:
            _export_rectangle(file, obj)
        # 添加其他类型...

func _export_line(file: File, line: CADObject):
    file.store_string("0\nLINE\n")
    file.store_string("8\n0\n")  # 图层
    file.store_string("10\n%%.6f\n" % line.start_point.x)
    file.store_string("20\n%%.6f\n" % line.start_point.y)
    file.store_string("30\n0.0\n")  # Z坐标
    file.store_string("11\n%%.6f\n" % line.end_point.x)
    file.store_string("21\n%%.6f\n" % line.end_point.y)
    file.store_string("31\n0.0\n")  # Z坐标

func _export_circle(file: File, circle: CADObject):
    file.store_string("0\nCIRCLE\n")
    file.store_string("8\n0\n")  # 图层
    file.store_string("10\n%%.6f\n" % circle.global_position.x)
    file.store_string("20\n%%.6f\n" % circle.global_position.y)
    file.store_string("30\n0.0\n")  # Z坐标
    file.store_string("40\n%%.6f\n" % circle.radius)
```

### 6.2 增强的SVG导出器

```gdscript
# EnhancedSVGExporter.gd
class_name EnhancedSVGExporter

func export_to_svg(objects: Array, background: Color, filepath: String, options: Dictionary = {}) -> void:
    var file = File.new()
    file.open(filepath, File.WRITE)
    
    # SVG头部
    var width = options.get("width", 1024)
    var height = options.get("height", 768)
    var view_box = options.get("view_box", "0 0 %d %d" % [width, height])
    
    file.store_string('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n')
    file.store_string('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%s">\n' % [width, height, view_box])
    
    # 背景
    if background.a > 0:
        file.store_string('<rect width="100%" height="100%" fill="%s" />\n' % _color_to_hex(background))
    
    # 图层（按顺序）
    var layers = _get_layers_from_objects(objects)
    for layer in layers:
        if layer.visible:
            file.store_string('<!-- Layer: %s -->\n' % layer.name)
            file.store_string('<g id="layer_%d" opacity="%%.2f">\n' % [layer.id, layer.opacity])
            
            # 导出图层中的对象
            for obj in layer.objects:
                _export_object_to_svg(file, obj)
            
            file.store_string('</g>\n')
    
    # 结束SVG
    file.store_string('</svg>\n')
    file.close()

func _get_layers_from_objects(objects: Array) -> Array:
    var layers = {}
    
    for obj in objects:
        if not layers.has(obj.layer_id):
            # 创建一个新的临时图层（在完整实现中，这将来自图层管理器）
            layers[obj.layer_id] = {
                "id": obj.layer_id,
                "name": "Layer %d" % obj.layer_id,
                "visible": true,
                "opacity": 1.0,
                "objects": []
            }
        
        layers[obj.layer_id]["objects"].append(obj)
    
    return layers.values()

func _export_object_to_svg(file: File, obj: CADObject):
    var layer_opacity = 1.0  # 从图层获取
    var effective_opacity = obj.get_property("opacity", 1.0) * layer_opacity
    
    match obj.object_type:
        CADObject.ObjectType.LINE:
            _export_line_to_svg(file, obj, effective_opacity)
        CADObject.ObjectType.RECTANGLE:
            _export_rectangle_to_svg(file, obj, effective_opacity)
        CADObject.ObjectType.CIRCLE:
            _export_circle_to_svg(file, obj, effective_opacity)
        CADObject.ObjectType.TEXT:
            _export_text_to_svg(file, obj, effective_opacity)
        # 添加其他类型...

func _export_line_to_svg(file: File, line: CADObject, opacity: float):
    var color = line.get_property("color", Color.BLACK)
    var width = line.get_property("width", 1.0)
    var start = line.get_property("start_point", Vector2.ZERO)
    var end = line.get_property("end_point", Vector2.RIGHT * 100)
    
    file.store_string('<line x1="%%.2f" y1="%%.2f" x2="%%.2f" y2="%%.2f" ' % [start.x, start.y, end.x, end.y])
    file.store_string('stroke="%s" stroke-width="%%.2f" stroke-opacity="%%.2f" ' % [_color_to_hex(color), width, opacity])
    
    # 线型
    var line_style = line.get_property("line_style", "solid")
    if line_style == "dashed":
        file.store_string('stroke-dasharray="5,3" ')
    elif line_style == "dotted":
        file.store_string('stroke-dasharray="1,2" ')
    
    file.store_string('/>\n')

func _color_to_hex(color: Color) -> String:
    var r = int(color.r * 255)
    var g = int(color.g * 255)
    var b = int(color.b * 255)
    return "#%02x%02x%02x" % [r, g, b]
```

## 7. 命令行接口

### 7.1 命令处理器

```gdscript
# CommandProcessor.gd
class_name CommandProcessor extends Node

signal command_executed(command: String, success: bool)
signal command_history_updated(history: Array)

var command_history: Array = []
var history_index: int = -1
var current_command: String = ""

var commands: Dictionary = {}

func _init():
    # 注册内置命令
    _register_builtin_commands()

func _register_builtin_commands():
    # 绘图命令
    commands["LINE"] = _cmd_line
    commands["RECTANGLE"] = _cmd_rectangle
    commands["CIRCLE"] = _cmd_circle
    commands["ARC"] = _cmd_arc
    
    # 编辑命令
    commands["MOVE"] = _cmd_move
    commands["COPY"] = _cmd_copy
    commands["ROTATE"] = _cmd_rotate
    commands["SCALE"] = _cmd_scale
    commands["DELETE"] = _cmd_delete
    
    # 图层命令
    commands["LAYER"] = _cmd_layer
    commands["LA"] = _cmd_layer  # 别名
    
    # 视图命令
    commands["ZOOM"] = _cmd_zoom
    commands["PAN"] = _cmd_pan
    
    # 系统命令
    commands["UNDO"] = _cmd_undo
    commands["REDO"] = _cmd_redo
    commands["SAVE"] = _cmd_save
    commands["OPEN"] = _cmd_open
    commands["HELP"] = _cmd_help

func execute_command(command: String) -> bool:
    command = command.strip_edges().to_upper()
    
    if command.empty():
        return false
    
    # 添加到历史记录
    if command_history.is_empty() or command_history.back() != command:
        command_history.append(command)
        history_index = command_history.size()
        command_history_updated.emit(command_history)
    
    # 解析命令
    var parts = command.split(" ")
    var cmd_name = parts[0]
    var args = parts.slice(1)
    
    if commands.has(cmd_name):
        var success = commands[cmd_name](args)
        command_executed.emit(command, success)
        return success
    else:
        push_error("Unknown command: %s" % cmd_name)
        command_executed.emit(command, false)
        return false

func _cmd_line(args: Array) -> bool:
    # 实现LINE命令
    # 格式：LINE x1,y1 x2,y2
    if args.size() < 2:
        push_message("Usage: LINE x1,y1 x2,y2")
        return false
    
    var points = []
    for arg in args:
        var coords = arg.split(",")
        if coords.size() == 2:
            points.append(Vector2(float(coords[0]), float(coords[1])))
    
    if points.size() == 2:
        # 创建线对象
        var line = CADLine.new()
        line.set_start_point(points[0])
        line.set_end_point(points[1])
        
        # 添加到当前图层
        var canvas = get_node("/root/InfiniteCanvas")
        if canvas and canvas.has_method("add_cad_object"):
            canvas.add_cad_object(line)
            return true
    
    return false

func _cmd_rectangle(args: Array) -> bool:
    # 实现RECTANGLE命令
    # 格式：RECTANGLE x,y width,height
    if args.size() < 3:
        push_message("Usage: RECTANGLE x,y width,height")
        return false
    
    var pos_parts = args[0].split(",")
    if pos_parts.size() != 2:
        return false
    
    var position = Vector2(float(pos_parts[0]), float(pos_parts[1]))
    var size_parts = args[1].split(",")
    if size_parts.size() != 2:
        return false
    
    var size = Vector2(float(size_parts[0]), float(size_parts[1]))
    
    # 创建矩形（4条线）
    var rect_lines = []
    
    # 顶部
    var top_line = CADLine.new()
    top_line.set_start_point(position)
    top_line.set_end_point(position + Vector2(size.x, 0))
    rect_lines.append(top_line)
    
    # 右侧
    var right_line = CADLine.new()
    right_line.set_start_point(position + Vector2(size.x, 0))
    right_line.set_end_point(position + size)
    rect_lines.append(right_line)
    
    # 底部
    var bottom_line = CADLine.new()
    bottom_line.set_start_point(position + size)
    bottom_line.set_end_point(position + Vector2(0, size.y))
    rect_lines.append(bottom_line)
    
    # 左侧
    var left_line = CADLine.new()
    left_line.set_start_point(position + Vector2(0, size.y))
    left_line.set_end_point(position)
    rect_lines.append(left_line)
    
    # 添加到画布
    var canvas = get_node("/root/InfiniteCanvas")
    if canvas and canvas.has_method("add_cad_objects"):
        canvas.add_cad_objects(rect_lines)
        return true
    
    return false

# 其他命令实现...

func get_command_history() -> Array:
    return command_history

func navigate_history(direction: int) -> String:
    # direction: 1 = up, -1 = down
    if command_history.size() == 0:
        return ""
    
    history_index = clamp(history_index + direction, 0, command_history.size())
    
    if history_index == command_history.size():
        return current_command
    else:
        return command_history[history_index]

func set_current_command(cmd: String):
    current_command = cmd
    history_index = command_history.size()
```

### 7.2 命令行UI

```gdscript
# CommandLine.gd
class_name CommandLine extends LineEdit

var command_processor: CommandProcessor
var history: Array = []
var current_history_index: int = -1

func _ready():
    command_processor = get_node("/root/CommandProcessor")
    if command_processor:
        command_processor.command_history_updated.connect(_on_command_history_updated)
    
    # 设置样式
    add_theme_stylebox_override("normal", get_theme_stylebox("command_line", "LineEdit"))
    add_theme_font_override("font", get_theme_font("command_font", "Font"))
    add_theme_color_override("font_color", get_theme_color("command_text", "FontColor"))
    
    # 连接信号
    connect("text_entered", self, "_on_text_entered")
    connect("focus_entered", self, "_on_focus_entered")
    connect("focus_exited", self, "_on_focus_exited")

func _on_text_entered(text: String):
    if command_processor:
        var success = command_processor.execute_command(text)
        
        if success:
            # 清除输入
            clear()
            
            # 显示成功消息
            var console = get_node("/root/Console")
            if console:
                console.add_message("> %s" % text, Color.GREEN)
        else:
            # 保持文本以便编辑
            select_all()

func _on_command_history_updated(new_history: Array):
    history = new_history
    current_history_index = history.size()

func _input(event: InputEvent):
    if event is InputEventKey:
        if event.keycode == KEY_UP:
            _navigate_history(-1)
            accept_event()
        elif event.keycode == KEY_DOWN:
            _navigate_history(1)
            accept_event()
        elif event.keycode == KEY_TAB:
            _auto_complete()
            accept_event()

func _navigate_history(direction: int):
    if history.size() == 0:
        return
    
    current_history_index = clamp(current_history_index + direction, 0, history.size())
    
    if current_history_index < history.size():
        text = history[current_history_index]
        cursor_position = text.length()

func _auto_complete():
    # 实现命令自动完成
    pass

func _on_focus_entered():
    # 显示命令提示
    placeholder_text = "Enter command..."

func _on_focus_exited():
    placeholder_text = ""

func show():
    visible = true
    grab_focus()

func hide():
    visible = false
```

## 8. 实施优先级

### 8.1 核心功能（优先级1）
1. **图层系统** - 基础架构
2. **CAD对象基类** - 所有CAD对象的基础
3. **基本CAD工具** - 线、矩形、圆
4. **对象选择和属性** - 基本编辑功能

### 8.2 高级功能（优先级2）
1. **智能捕捉系统** - 精确绘图
2. **尺寸标注** - 测量和标注
3. **约束系统** - 几何约束
4. **图层管理UI** - 完整的图层控制

### 8.3 文件格式（优先级3）
1. **增强的SVG导出** - 当前格式的改进
2. **DXF导出** - CAD互操作性
3. **项目文件版本化** - 向后兼容性

### 8.4 UI改进（优先级4）
1. **命令行接口** - 高级用户工作流
2. **CAD工具栏** - 工具组织
3. **属性面板** - 对象检查

## 9. 兼容性考虑

### 9.1 向后兼容性
- 保持对现有项目文件的读取支持
- 逐步迁移：旧项目在新系统中作为单图层导入
- 提供项目升级工具

### 9.2 现有代码集成
- 保持当前的InfiniteCanvas作为CAD对象的容器
- 扩展而不是替换现有的工具系统
- 逐步添加新功能，保持应用可用

## 10. 测试策略

### 10.1 单元测试
- 图层管理器功能
- 约束求解器算法
- 捕捉点计算
- 文件导入/导出

### 10.2 集成测试
- 工具之间的交互
- 图层和对象管理
- 约束和捕捉系统集成

### 10.3 用户测试
- 典型CAD工作流
- 大型项目性能
- 文件兼容性

## 11. 文档要求

### 11.1 开发者文档
- 架构概述
- API参考（每个主要组件）
- 扩展指南
- 贡献指南

### 11.2 用户文档
- 快速入门
- 工具参考
- 命令参考
- 高级教程

## 12. 成功标准

### 12.1 最低可行产品（MVP）
- 所有核心CAD工具可用
- 基本图层系统
- 智能捕捉和对齐
- 增强的SVG导出
- 稳定性和性能可接受

### 12.2 完整版本
- 所有计划功能已实施
- 完整的文档
- 积极的社区参与
- 定期更新和维护

这个技术规格提供了将无限画板应用转换为功能完整的CAD应用所需的详细实现计划。每个组件都被设计为模块化和可扩展，允许逐步实施和测试。