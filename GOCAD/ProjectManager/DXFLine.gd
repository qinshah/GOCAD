# DXFLine.gd - DXF 线实体
class_name DXFLine extends DXFEntity

var start_point: Vector3 = Vector3.ZERO
var end_point: Vector3 = Vector3.RIGHT
var extrusion: Vector3 = Vector3.UP  # 挤出方向

func _init():
    type = EntityType.LINE

func _get_entity_specific_dxf() -> String:
    var result = ""
    
    # 起点
    result += "10\n%%.6f\n" % start_point.x
    result += "20\n%%.6f\n" % start_point.y
    result += "30\n%%.6f\n" % start_point.z
    
    # 终点
    result += "11\n%%.6f\n" % end_point.x
    result += "21\n%%.6f\n" % end_point.y
    result += "31\n%%.6f\n" % end_point.z
    
    # 挤出方向（可选）
    if extrusion != Vector3.UP:
        result += "210\n%%.6f\n" % extrusion.x
        result += "220\n%%.6f\n" % extrusion.y
        result += "230\n%%.6f\n" % extrusion.z
    
    return result

func _parse_entity_specific_codes(codes: Dictionary):
    if codes.has(10): start_point.x = float(codes[10])
    if codes.has(20): start_point.y = float(codes[20])
    if codes.has(30): start_point.z = float(codes[30])
    if codes.has(11): end_point.x = float(codes[11])
    if codes.has(21): end_point.y = float(codes[21])
    if codes.has(31): end_point.z = float(codes[31])
    if codes.has(210): extrusion.x = float(codes[210])
    if codes.has(220): extrusion.y = float(codes[220])
    if codes.has(230): extrusion.z = float(codes[230])

func _validate_entity_specific() -> bool:
    # 检查起点和终点是否不同
    if start_point == end_point:
        return false
    
    # 检查坐标是否有效
    if is_nan(start_point.x) or is_nan(start_point.y) or is_nan(start_point.z):
        return false
    if is_nan(end_point.x) or is_nan(end_point.y) or is_nan(end_point.z):
        return false
    
    return true

func get_length() -> float:
    return start_point.distance_to(end_point)

func get_angle() -> float:
    return atan2(end_point.y - start_point.y, end_point.x - start_point.x)