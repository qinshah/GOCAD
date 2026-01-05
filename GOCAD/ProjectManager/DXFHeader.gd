# DXFHeader.gd - DXF 头部信息
class_name DXFHeader extends Resource

var insbase_x: float = 0.0
var insbase_y: float = 0.0
var insbase_z: float = 0.0
var extmin_x: float = -1000.0
var extmin_y: float = -1000.0
var extmin_z: float = 0.0
var extmax_x: float = 1000.0
var extmax_y: float = 1000.0
var extmax_z: float = 0.0
var ltscale: float = 1.0
var lwdisplay: int = 1
var celtype: String = "BYLAYER"
var cecolor: int = 256
var celtscale: float = 1.0