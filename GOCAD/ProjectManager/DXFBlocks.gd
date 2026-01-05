# DXFBlocks.gd - DXF 块结构
class_name DXFBlocks extends Resource

var blocks: Array = []

func add_block(block: DXFBlock):
    blocks.append(block)

func get_block_by_name(name: String):
    for block in blocks:
        if block.name == name:
            return block
    return null