# DXFCircle.gd - DXF 圆实体
class_name DXFCircle extends DXFEntity

var center: Vector3 = Vector3.ZERO
var radius: float = 1.0
var extrusion: Vector3 = Vector3.UP  # 挤出方向

func _init():
    type = EntityType.CIRCLE

func _get_entity_specific_dxf() -> String:
    var result = ""
    
    # 中心点
    result += "10\n%%.6f\n" % center.x
    result += "20\n%%.6f\n" % center.y
    result += "30\n%%.6f\n" % center.z
    
    # 半径
    result += "40\n%%.6f\n" % radius
    
    # 挤出方向（可选）
    if extrusion != Vector3.UP:
        result += "210\n%%.6f\n" % extrusion.x
        result += "220\n%%.6f\n" % extrusion.y
        result += "230\n%%.6f\n" % extrusion.z
    
    return result

func _parse_entity_specific_codes(codes: Dictionary):
    if codes.has(10): center.x = float(codes[10])
    if codes.has(20): center.y = float(codes[20])
    if codes.has(30): center.z = float(codes[30])
    if codes.has(40): radius = float(codes[40])
    if codes.has(210): extrusion.x = float(codes[210])
    if codes.has(220): extrusion.y = float(codes[220])
    if codes.has(230): extrusion.z = float(codes[230])

func _validate_entity_specific() -> bool:
    # 检查半径是否有效
    if radius <= 0:
        return false
    
    # 检查坐标是否有效
    if is_nan(center.x) or is_nan(center.y) or is_nan(center.z):
        return false
    
    return true

func get_circumference() -> float:
    return 2 * PI * radius

func get_area() -> float:
    return PI * radius * radius