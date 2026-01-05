# DXFTables.gd - DXF 表结构
class_name DXFTables extends Resource

var layers: Array = []
var linetypes: Array = []
var styles: Array = []
var views: Array = []
var ucs: Array = []
var appids: Array = []
var dimstyles: Array = []

func add_layer(layer: DXFLayer):
    layers.append(layer)

func get_layer_by_name(name: String):
    for layer in layers:
        if layer.name == name:
            return layer
    return null