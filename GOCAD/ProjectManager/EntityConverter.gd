# EntityConverter.gd - 实体转换器
# 将 DXF 实体转换为笔画，反之亦然
class_name EntityConverter

# 来自 libdxfrw 的转换参数
var tolerance: float = 0.001  # 用于几何检测
var min_line_length: float = 0.1  # 最小线长度
var max_polyline_vertices: int = 2048  # 最大多段线顶点数

func stroke_to_entity(stroke: BrushStroke):
    # 这个方法将笔画转换为 DXF 实体
    # 暂时不实现，因为我们主要关注的是从 DXF 导入
    return null

func entity_to_stroke(entity):
    # 这个方法将 DXF 实体转换为笔画
    # 我们需要检查实体的类型并相应地处理
    
    var BrushStroke = load("res://BrushStroke/BrushStroke.tscn")
    if not BrushStroke:
        print("无法加载 BrushStroke 类")
        return null
        
    var stroke = BrushStroke.instantiate()
    
    # 设置笔画属性
    stroke.color = _dxf_color_to_godot(_get_entity_color(entity))
    stroke.size = _dxf_lineweight_to_brush_size(_get_entity_lineweight(entity))
    
    # 根据实体类型处理
    var entity_type = _get_entity_type(entity)
    
    match entity_type:
        "LINE":
            _convert_line_to_stroke(entity, stroke)
        "CIRCLE":
            _convert_circle_to_stroke(entity, stroke)
        "ARC":
            _convert_arc_to_stroke(entity, stroke)
        "LWPOLYLINE":
            _convert_polyline_to_stroke(entity, stroke)
        _:
            print("不支持的实体类型: %s" % entity_type)
            return null
    
    return stroke

func _get_entity_type(entity):
    # 尝试获取实体类型
    if entity.has_method("_get_entity_type_name"):
        return entity._get_entity_type_name()
    elif entity.has("type"):
        # 尝试从 type 属性获取类型名称
        var type_value = entity.type
        if type_value == 0:
            return "LINE"
        elif type_value == 1:
            return "CIRCLE"
        elif type_value == 2:
            return "ARC"
        elif type_value == 3:
            return "LWPOLYLINE"
        else:
            return "UNKNOWN"
    else:
        return "UNKNOWN"

func _get_entity_color(entity):
    # 尝试获取实体颜色
    if entity.has("color"):
        return entity.color
    else:
        return 256  # BYLAYER

func _get_entity_lineweight(entity):
    # 尝试获取实体线宽
    if entity.has("line_weight"):
        return entity.line_weight
    else:
        return -1  # BYLAYER

func _convert_line_to_stroke(entity, stroke):
    # 将线实体转换为笔画
    if entity.has("start_point") and entity.has("end_point"):
        stroke.add_point(Vector2(entity.start_point.x, entity.start_point.y))
        stroke.add_point(Vector2(entity.end_point.x, entity.end_point.y))

func _convert_circle_to_stroke(entity, stroke):
    # 将圆实体转换为笔画（近似为多段线）
    if entity.has("center") and entity.has("radius"):
        var segments = 32
        var radius = entity.radius
        var center = Vector2(entity.center.x, entity.center.y)
        
        for i in range(segments + 1):
            var angle = i * 2 * PI / segments
            var point = center + Vector2(cos(angle), sin(angle)) * radius
            stroke.add_point(point)

func _convert_arc_to_stroke(entity, stroke):
    # 将弧实体转换为笔画（近似为多段线）
    if entity.has("center") and entity.has("radius") and entity.has("start_angle") and entity.has("end_angle"):
        var segments = 16
        var radius = entity.radius
        var center = Vector2(entity.center.x, entity.center.y)
        var start_angle = entity.start_angle
        var end_angle = entity.end_angle
        
        # 确保角度在正确的范围内
        while start_angle < 0:
            start_angle += 2 * PI
        while end_angle < 0:
            end_angle += 2 * PI
        
        # 计算角度范围
        var angle_range = end_angle - start_angle
        if angle_range < 0:
            angle_range += 2 * PI
        
        for i in range(segments + 1):
            var angle = start_angle + i * angle_range / segments
            var point = center + Vector2(cos(angle), sin(angle)) * radius
            stroke.add_point(point)

func _convert_polyline_to_stroke(entity, stroke):
    # 将多段线实体转换为笔画
    if entity.has("vertices"):
        for vertex in entity.vertices:
            stroke.add_point(vertex)
            
        # 如果闭合，添加一个点以闭合笔画
        if entity.has("closed") and entity.closed and entity.vertices.size() > 0:
            stroke.add_point(entity.vertices[0])

func _dxf_color_to_godot(dxf_color: int) -> Color:
    # 转换 DXF 颜色索引为 Godot 颜色
    # 基于 libdxfrw 的颜色映射
    
    if dxf_color == 256:  # BYLAYER
        return Color.WHITE  # 默认
    elif dxf_color == 0:  # BYBLOCK
        return Color.WHITE  # 默认
    
    # 标准 DXF 颜色
    var colors = [
        Color(1, 0, 0),        # 1 - 红色
        Color(1, 1, 0),        # 2 - 黄色
        Color(0, 1, 0),        # 3 - 绿色
        Color(0, 1, 1),        # 4 - 青色
        Color(0, 0, 1),        # 5 - 蓝色
        Color(1, 0, 1),        # 6 - 洋红色
        Color(1, 1, 1),        # 7 - 白色/黑色
        Color(0.5, 0.5, 0.5),  # 8 - 灰色
        Color(0.75, 0.75, 0.75), # 9 - 浅灰色
        Color(1, 0.5, 0.5),    # 10 - 浅红色
        Color(1, 0.75, 0.75),  # 11 - 浅洋红色
        Color(0.75, 0.75, 1),  # 12 - 浅蓝色
        Color(0.75, 1, 0.75),  # 13 - 浅青色
        Color(1, 1, 0.75),    # 14 - 浅黄色
        Color(0.75, 1, 1),    # 15 - 浅绿色
        Color(0.5, 0.5, 0.5)   # 16 - 中灰色
    ]
    
    if dxf_color >= 1 and dxf_color <= 16:
        return colors[dxf_color - 1]
    
    # 其他颜色：使用 HSV 转换
    var h = (dxf_color - 17) * 0.02
    return Color.from_hsv(h, 0.7, 0.9)

func _dxf_lineweight_to_brush_size(line_weight: int) -> float:
    # 转换 DXF 线宽为笔画大小
    # 基于 libdxfrw 的线宽映射
    
    if line_weight == -1:  # BYLAYER
        return 1.0  # 默认
    elif line_weight == -2:  # BYBLOCK
        return 1.0  # 默认
    elif line_weight == -3:  # DEFAULT
        return 1.0  # 默认
    
    # 标准线宽（以毫米为单位）
    var lineweights = [
        0.00,   # 0
        0.05,   # 1
        0.09,   # 2
        0.13,   # 3
        0.15,   # 4
        0.18,   # 5
        0.20,   # 6
        0.25,   # 7
        0.30,   # 8
        0.35,   # 9
        0.40,   # 10
        0.50,   # 11
        0.53,   # 12
        0.60,   # 13
        0.70,   # 14
        0.80,   # 15
        0.90,   # 16
        1.00,   # 17
        1.06,   # 18
        1.20,   # 19
        1.40,   # 20
        1.58,   # 21
        2.00,   # 22
        2.11    # 23
    ]
    
    if line_weight >= 0 and line_weight <= 23:
        # 转换为像素（假设 96 DPI）
        return lineweights[line_weight] * 96 / 25.4 * 10
    
    return 1.0  # 默认