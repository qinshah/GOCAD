# DXFEntity.gd - DXF 实体基类
class_name DXFEntity extends Resource

enum EntityType {
    LINE,
    CIRCLE,
    ARC,
    LWPOLYLINE,
    POLYLINE,
    TEXT,
    DIMENSION,
    INSERT,
    SPLINE
}

var type: EntityType
var layer: String = "0"
var line_type: String = "BYLAYER"
var color: int = 256  # BYLAYER
var line_weight: int = -1  # BYLAYER
var handle: String = ""

# 来自 libdxfrw 的常见 DXF 代码
var dxf_codes: Dictionary = {}

func to_dxf() -> String:
    var result = ""
    
    # 实体类型
    result += "0\n%s\n" % _get_entity_type_name()
    
    # 图层
    result += "8\n%s\n" % layer
    
    # 线型
    if line_type != "BYLAYER":
        result += "6\n%s\n" % line_type
    
    # 颜色
    if color != 256:  # 256 = BYLAYER
        result += "62\n%d\n" % color
    
    # 线宽
    if line_weight != -1:  # -1 = BYLAYER
        result += "370\n%d\n" % line_weight
    
    # 实体特定数据
    result += _get_entity_specific_dxf()
    
    return result

func from_dxf(codes: Dictionary) -> void:
    # 解析 DXF 代码
    if codes.has(8):
        layer = codes[8]
    if codes.has(6):
        line_type = codes[6]
    if codes.has(62):
        color = int(codes[62])
    if codes.has(370):
        line_weight = int(codes[370])
    
    # 实体特定解析
    _parse_entity_specific_codes(codes)

func validate() -> bool:
    # 基本验证
    if layer.empty():
        return false
    
    # 实体特定验证
    return _validate_entity_specific()

func _get_entity_type_name() -> String:
    match type:
        EntityType.LINE: return "LINE"
        EntityType.CIRCLE: return "CIRCLE"
        EntityType.ARC: return "ARC"
        EntityType.LWPOLYLINE: return "LWPOLYLINE"
        EntityType.POLYLINE: return "POLYLINE"
        EntityType.TEXT: return "TEXT"
        EntityType.DIMENSION: return "DIMENSION"
        EntityType.INSERT: return "INSERT"
        EntityType.SPLINE: return "SPLINE"
    return "UNKNOWN"

func _get_entity_specific_dxf() -> String:
    return ""  # 由子类实现

func _parse_entity_specific_codes(codes: Dictionary):
    pass  # 由子类实现

func _validate_entity_specific() -> bool:
    return true  # 由子类实现