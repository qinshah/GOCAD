# DXFLWPolyline.gd - DXF 轻量多段线实体
class_name DXFLWPolyline extends DXFEntity

var vertices: Array = []
var closed: bool = false
var width: float = 0.0
var elevation: float = 0.0
var extrusion: Vector3 = Vector3.UP

func _init():
    type = EntityType.LWPOLYLINE

func _get_entity_specific_dxf() -> String:
    var result = ""
    
    # 顶点数
    result += "90\n%d\n" % vertices.size()
    
    # 标志（位编码）
    var flags = 0
    if closed:
        flags |= 1
    if width > 0:
        flags |= 2
    result += "70\n%d\n" % flags
    
    # 默认宽度（可选）
    if width > 0:
        result += "43\n%%.6f\n" % width
    
    # 高度（可选）
    if elevation != 0:
        result += "38\n%%.6f\n" % elevation
    
    # 挤出方向（可选）
    if extrusion != Vector3.UP:
        result += "210\n%%.6f\n" % extrusion.x
        result += "220\n%%.6f\n" % extrusion.y
        result += "230\n%%.6f\n" % extrusion.z
    
    # 顶点
    for i in range(vertices.size()):
        var vertex = vertices[i]
        result += "10\n%%.6f\n" % vertex.x
        result += "20\n%%.6f\n" % vertex.y
        
        # 可选：起始宽度和结束宽度
        # result += "40\n%%.6f\n" % start_width
        # result += "41\n%%.6f\n" % end_width
        
        # 可选：顶点高度
        if elevation != 0:
            result += "30\n%%.6f\n" % elevation
    
    return result

func _parse_entity_specific_codes(codes: Dictionary):
    # 顶点数
    if codes.has(90):
        var vertex_count = int(codes[90])
        
    # 标志
    if codes.has(70):
        var flags = int(codes[70])
        closed = (flags & 1) != 0
        
    # 默认宽度
    if codes.has(43):
        width = float(codes[43])
        
    # 高度
    if codes.has(38):
        elevation = float(codes[38])
        
    # 挤出方向
    if codes.has(210): extrusion.x = float(codes[210])
    if codes.has(220): extrusion.y = float(codes[220])
    if codes.has(230): extrusion.z = float(codes[230])
    
    # 解析顶点（需要更复杂的逻辑来处理多个顶点）
    # 这个需要在 DXFReader 中处理

func _validate_entity_specific() -> bool:
    # 检查顶点数
    if vertices.size() < 2:
        return false
    
    # 检查闭合多段线是否有足够的顶点
    if closed and vertices.size() < 3:
        return false
    
    return true

func get_length() -> float:
    var total_length = 0.0
    for i in range(vertices.size() - 1):
        total_length += vertices[i].distance_to(vertices[i + 1])
    if closed and vertices.size() > 2:
        total_length += vertices.back().distance_to(vertices[0])
    return total_length

func add_vertex(vertex: Vector2):
    vertices.append(vertex)