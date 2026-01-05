# DXFDocument.gd - DXF 文档结构
class_name DXFDocument extends Resource

var version: String = "AC1015"  # R2000 - 最兼容的版本
var header: DXFHeader = DXFHeader.new()
var tables: DXFTables = DXFTables.new()
var blocks: DXFBlocks = DXFBlocks.new()
var entities: Array = []
var objects: Array = []

# 头部变量（来自 libdxfrw）
var header_vars: Dictionary = {
    "$ACADVER": "AC1015",
    "$INSBASE": Vector3.ZERO,
    "$EXTMIN": Vector3(-1000, -1000, 0),
    "$EXTMAX": Vector3(1000, 1000, 0),
    "$LTSCALE": 1.0,
    "$LWDISPLAY": 1,
    "$CELTYPE": "BYLAYER",
    "$CECOLOR": 256,  # BYLAYER
    "$CELTSCALE": 1.0
}

func add_entity(entity: DXFEntity):
    entities.append(entity)

func get_entities_by_type(type: String):
    var result = []
    for entity in entities:
        if entity.type == type:
            result.append(entity)
    return result

func validate() -> bool:
    # 实施类似 libdxfrw 的验证
    if entities.size() == 0:
        return false
    
    # 检查所有实体是否有效
    for entity in entities:
        if not entity.validate():
            return false
    
    return true