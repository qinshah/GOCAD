# DXFReader.gd - 新版本使用 load() 方法
class_name DXFReader

# DXF 文件读取器
# 参考 libdxfrw 库的实现

var current_line: int = 0
var lines: Array = []
var current_section: String = ""
var current_entity = null
var current_handle: String = ""

# 来自 libdxfrw 的代码组
var code_groups: Dictionary = {
    0: "STRING",
    1: "STRING",
    2: "NAME",
    3: "STRING",
    4: "STRING",
    5: "HANDLE",
    6: "LINETYPE",
    7: "STRING",
    8: "LAYER",
    9: "VARIABLE",
    10: "X_COORD",
    11: "X_COORD",
    12: "X_COORD",
    13: "X_COORD",
    14: "X_COORD",
    20: "Y_COORD",
    21: "Y_COORD",
    22: "Y_COORD",
    23: "Y_COORD",
    24: "Y_COORD",
    30: "Z_COORD",
    31: "Z_COORD",
    32: "Z_COORD",
    33: "Z_COORD",
    34: "Z_COORD",
    38: "ELEVATION",
    39: "THICKNESS",
    40: "FLOAT",
    41: "FLOAT",
    42: "FLOAT",
    43: "FLOAT",
    44: "FLOAT",
    45: "FLOAT",
    46: "FLOAT",
    47: "FLOAT",
    48: "FLOAT",
    49: "FLOAT",
    50: "ANGLE",
    51: "ANGLE",
    60: "INT",
    62: "COLOR",
    66: "FLAGS",
    70: "FLAGS",
    71: "FLAGS",
    72: "FLAGS",
    73: "FLAGS",
    74: "FLAGS",
    75: "FLAGS",
    90: "INT",
    91: "INT",
    92: "INT",
    93: "INT",
    94: "INT",
    95: "INT",
    96: "INT",
    97: "INT",
    98: "INT",
    99: "INT",
    100: "STRING",
    102: "STRING",
    105: "HANDLE",
    110: "X_COORD",
    111: "X_COORD",
    112: "X_COORD",
    120: "Y_COORD",
    121: "Y_COORD",
    122: "Y_COORD",
    130: "Z_COORD",
    131: "Z_COORD",
    132: "Z_COORD",
    140: "FLOAT",
    141: "FLOAT",
    142: "FLOAT",
    143: "FLOAT",
    144: "FLOAT",
    145: "FLOAT",
    146: "FLOAT",
    147: "FLOAT",
    170: "FLAGS",
    171: "FLAGS",
    172: "FLAGS",
    173: "FLAGS",
    174: "FLAGS",
    175: "FLAGS",
    210: "X_EXTRUSION",
    220: "Y_EXTRUSION",
    230: "Z_EXTRUSION",
    270: "FLAGS",
    271: "FLAGS",
    272: "FLAGS",
    273: "FLAGS",
    280: "FLAGS",
    281: "FLAGS",
    290: "FLAG",
    291: "FLAG",
    292: "FLAG",
    293: "FLAG",
    294: "FLAG",
    295: "FLAG",
    296: "FLAG",
    297: "FLAG",
    298: "FLAG",
    299: "FLAG",
    300: "STRING",
    301: "STRING",
    302: "STRING",
    303: "STRING",
    304: "STRING",
    305: "STRING",
    310: "STRING",
    311: "STRING",
    312: "STRING",
    313: "STRING",
    314: "STRING",
    315: "STRING",
    320: "HANDLE",
    330: "HANDLE",
    340: "HANDLE",
    350: "HANDLE",
    360: "HANDLE",
    370: "LINEWEIGHT",
    380: "HANDLE",
    390: "HANDLE",
    400: "INT",
    401: "INT",
    402: "INT",
    410: "STRING",
    411: "STRING",
    420: "FLOAT",
    430: "STRING",
    440: "FLOAT",
    450: "FLOAT",
    451: "FLOAT",
    452: "FLOAT",
    453: "FLOAT",
    460: "FLOAT",
    461: "FLOAT",
    462: "FLOAT",
    463: "FLOAT",
    470: "STRING",
    480: "HANDLE",
    481: "HANDLE",
    999: "COMMENT",
    1000: "STRING",
    1001: "STRING",
    1002: "STRING",
    1003: "STRING",
    1004: "STRING",
    1005: "HANDLE",
    1010: "FLOAT",
    1011: "FLOAT",
    1012: "FLOAT",
    1013: "FLOAT",
    1020: "FLOAT",
    1021: "FLOAT",
    1022: "FLOAT",
    1023: "FLOAT",
    1030: "FLOAT",
    1031: "FLOAT",
    1032: "FLOAT",
    1033: "FLOAT",
    1040: "FLOAT",
    1041: "FLOAT",
    1042: "FLOAT",
    1050: "HANDLE",
    1051: "HANDLE",
    1052: "HANDLE",
    1053: "HANDLE",
    1054: "HANDLE",
    1055: "HANDLE",
    1056: "HANDLE",
    1057: "HANDLE",
    1058: "HANDLE",
    1059: "HANDLE",
    1060: "HANDLE",
    1061: "HANDLE",
    1062: "HANDLE",
    1063: "HANDLE",
    1070: "INT",
    1071: "INT"
}

func import_from_dxf(filepath: String):
    var file = FileAccess.open(filepath, FileAccess.READ)
    if file == null:
        push_error("无法打开文件：%s" % filepath)
        return null
    
    var DXFDocument = load("res://ProjectManager/DXFDocument.gd")
    if not DXFDocument:
        print("无法加载 DXFDocument 类")
        return null
        
    var document = DXFDocument.new()
    lines = file.get_as_text().split("\n")
    file.close()
    
    current_line = 0
    
    # 解析文件
    while current_line < lines.size():
        var code = lines[current_line].strip_edges()
        current_line += 1
        
        if current_line >= lines.size():
            break
        
        var value = lines[current_line].strip_edges()
        current_line += 1
        
        _process_code_pair(int(code), value, document)
    
    return document

func _process_code_pair(code: int, value: String, document):
    # 处理代码组（参考 libdxfrw）
    match code:
        0:  # 实体类型
            _process_code_0(value, document)
        2:  # 名称/变量
            _process_code_2(value, document)
        5:  # 句柄
            current_handle = value
        8:  # 图层
            if current_entity:
                current_entity.layer = value
        6:  # 线型
            if current_entity:
                current_entity.line_type = value
        62:  # 颜色
            if current_entity:
                current_entity.color = int(value)
        370:  # 线宽
            if current_entity:
                current_entity.line_weight = int(value)
        9:  # 变量名
            _process_code_9(value, document)
        10, 20, 30:  # X, Y, Z 坐标
            _process_coordinate_codes(code, value)
        _:
            if current_entity:
                current_entity.process_code(code, value)

func _process_code_0(value: String, document):
    match value:
        "SECTION":
            current_section = _read_section_type()
        "ENDSEC":
            current_section = ""
        "EOF":
            # 文件结束
            pass
        "LINE":
            var DXFLine = load("res://ProjectManager/DXFLine.gd")
            if DXFLine:
                current_entity = DXFLine.new()
                current_entity.handle = current_handle
                document.entities.append(current_entity)
            else:
                print("无法加载 DXFLine 类")
        "CIRCLE":
            var DXFCircle = load("res://ProjectManager/DXFCircle.gd")
            if DXFCircle:
                current_entity = DXFCircle.new()
                current_entity.handle = current_handle
                document.entities.append(current_entity)
            else:
                print("无法加载 DXFCircle 类")
        "ARC":
            var DXFArc = load("res://ProjectManager/DXFArc.gd")
            if DXFArc:
                current_entity = DXFArc.new()
                current_entity.handle = current_handle
                document.entities.append(current_entity)
            else:
                print("无法加载 DXFArc 类")
        "LWPOLYLINE":
            var DXFLWPolyline = load("res://ProjectManager/DXFLWPolyline.gd")
            if DXFLWPolyline:
                current_entity = DXFLWPolyline.new()
                current_entity.handle = current_handle
                document.entities.append(current_entity)
            else:
                print("无法加载 DXFLWPolyline 类")
        "POLYLINE":
            # 标准多段线（更复杂，暂时不实现）
            print("不支持的实体类型：POLYLINE")
        "TEXT":
            # 文本实体（暂时不实现）
            print("不支持的实体类型：TEXT")
        "INSERT":
            # 块插入（暂时不实现）
            print("不支持的实体类型：INSERT")
        "DIMENSION":
            # 尺寸标注（暂时不实现）
            print("不支持的实体类型：DIMENSION")
        "SPLINE":
            # 样条曲线（暂时不实现）
            print("不支持的实体类型：SPLINE")
        "ENDTAB":
            # 表结束
            pass
        _:
            # 其他实体类型
            print("未知实体类型：%s" % value)

func _process_code_2(value: String, document):
    # 处理名称/变量
    if current_section == "TABLES":
        # 表名称
        pass
    elif current_section == "BLOCKS":
        # 块名称
        pass

func _process_code_9(value: String, document):
    # 处理变量名
    if current_section == "HEADER":
        # 读取变量值
        if current_line < lines.size():
            var var_code = int(lines[current_line])
            current_line += 1
            if current_line < lines.size():
                var var_value = lines[current_line]
                current_line += 1
                _set_header_variable(value, var_code, var_value, document)

func _set_header_variable(name: String, code: int, value: String, document):
    match name:
        "$ACADVER":
            document.version = value
        "$INSBASE":
            if code == 10:
                document.header.insbase_x = float(value)
            elif code == 20:
                document.header.insbase_y = float(value)
            elif code == 30:
                document.header.insbase_z = float(value)
        "$EXTMIN":
            if code == 10:
                document.header.extmin_x = float(value)
            elif code == 20:
                document.header.extmin_y = float(value)
            elif code == 30:
                document.header.extmin_z = float(value)
        "$EXTMAX":
            if code == 10:
                document.header.extmax_x = float(value)
            elif code == 20:
                document.header.extmax_y = float(value)
            elif code == 30:
                document.header.extmax_z = float(value)
        "$LTSCALE":
            document.header.ltscale = float(value)
        "$LWDISPLAY":
            document.header.lwdisplay = int(value)
        "$CELTYPE":
            document.header.celtype = value
        "$CECOLOR":
            document.header.cecolor = int(value)
        "$CELTSCALE":
            document.header.celtscale = float(value)

func _process_coordinate_codes(code: int, value: String):
    if not current_entity:
        return
    
    var float_value = float(value)
    
    # 获取实体类型
    var entity_type = -1
    if current_entity.has_method("get_type"):
        entity_type = current_entity.get_type()
    else:
        # 尝试直接访问 type 属性
        if current_entity.has("type"):
            entity_type = current_entity.type
    
    match code:
        10:  # X 坐标
            if entity_type == 0:  # LINE
                if current_entity.has("start_point"):
                    current_entity.start_point.x = float_value
            elif entity_type == 1:  # CIRCLE
                if current_entity.has("center"):
                    current_entity.center.x = float_value
            elif entity_type == 2:  # ARC
                if current_entity.has("center"):
                    current_entity.center.x = float_value
        20:  # Y 坐标
            if entity_type == 0:  # LINE
                if current_entity.has("start_point"):
                    current_entity.start_point.y = float_value
            elif entity_type == 1:  # CIRCLE
                if current_entity.has("center"):
                    current_entity.center.y = float_value
            elif entity_type == 2:  # ARC
                if current_entity.has("center"):
                    current_entity.center.y = float_value
        30:  # Z 坐标
            if entity_type == 0:  # LINE
                if current_entity.has("start_point"):
                    current_entity.start_point.z = float_value
            elif entity_type == 1:  # CIRCLE
                if current_entity.has("center"):
                    current_entity.center.z = float_value
            elif entity_type == 2:  # ARC
                if current_entity.has("center"):
                    current_entity.center.z = float_value
        11:  # 第二个 X 坐标（用于线的终点等）
            if entity_type == 0:  # LINE
                if current_entity.has("end_point"):
                    current_entity.end_point.x = float_value
        21:  # 第二个 Y 坐标
            if entity_type == 0:  # LINE
                if current_entity.has("end_point"):
                    current_entity.end_point.y = float_value
        31:  # 第二个 Z 坐标
            if entity_type == 0:  # LINE
                if current_entity.has("end_point"):
                    current_entity.end_point.z = float_value
        40:  # 半径（用于圆和弧）
            if entity_type == 1:  # CIRCLE
                if current_entity.has("radius"):
                    current_entity.radius = float_value
            elif entity_type == 2:  # ARC
                if current_entity.has("radius"):
                    current_entity.radius = float_value
        50:  # 起始角度（用于弧）
            if entity_type == 2:  # ARC
                if current_entity.has("start_angle"):
                    current_entity.start_angle = float_value
        51:  # 结束角度（用于弧）
            if entity_type == 2:  # ARC
                if current_entity.has("end_angle"):
                    current_entity.end_angle = float_value

func _read_section_type() -> String:
    if current_line < lines.size():
        return lines[current_line].strip_edges()
    return ""