# GOCAD系统架构

## 组件图

```mermaid
graph TD
    A[GOCAD Application] --> B[InfiniteCanvas]
    A --> C[LayerManager]
    A --> D[ConstraintManager]
    A --> E[SnapManager]
    A --> F[CommandProcessor]
    A --> G[FileExporters]
    
    B --> H[CADObjects]
    B --> I[Tools]
    B --> J[Camera]
    B --> K[Grid]
    
    C --> L[Layers]
    L --> M[CADObjects]
    
    D --> N[Constraints]
    N --> O[GeometricConstraints]
    N --> P[DimensionalConstraints]
    
    E --> Q[SnapPoints]
    
    F --> R[Commands]
    
    G --> S[SVGExporter]
    G --> T[DXFExporter]
    G --> U[PDFExporter]
```

## 类图 - 核心CAD对象

```mermaid
classDiagram
    class CADObject {
        <<abstract>>
        +ObjectType object_type
        +int layer_id
        +Dictionary properties
        +Array constraints
        +bool is_selected
        +bool is_locked
        +set_property(key, value)
        +get_property(key)
        +add_constraint(constraint)
        +remove_constraint(constraint)
        +select()
        +deselect()
        +lock()
        +unlock()
        +to_dict()
        +from_dict(data)
    }
    
    class CADLine {
        +Vector2 start_point
        +Vector2 end_point
        +float line_width
        +Color line_color
        +String line_style
        +set_start_point(point)
        +set_end_point(point)
        +get_length()
        +get_angle()
    }
    
    class CADRectangle {
        +Vector2 position
        +Vector2 size
        +float rotation
        +Color fill_color
        +Color border_color
        +float border_width
    }
    
    class CADCircle {
        +Vector2 center
        +float radius
        +Color fill_color
        +Color border_color
        +float border_width
        +get_circumference()
        +get_area()
    }
    
    class CADText {
        +String content
        +Vector2 position
        +String font_name
        +int font_size
        +Color color
        +String alignment
        +set_text(text)
        +get_bounds()
    }
    
    class Dimension {
        +DimensionType dimension_type
        +Array reference_objects
        +float measurement
        +Vector2 text_position
        +String text_content
        +int precision
        +String units
        +update_measurement()
    }
    
    CADObject <|-- CADLine
    CADObject <|-- CADRectangle
    CADObject <|-- CADCircle
    CADObject <|-- CADText
    CADObject <|-- Dimension
```

## 图层系统架构

```mermaid
classDiagram
    class LayerManager {
        +Array layers
        +Layer active_layer
        +create_layer(name, type)
        +remove_layer(layer_id)
        +set_active_layer(layer_id)
        +get_layer_by_id(layer_id)
        +move_layer_up(layer_id)
        +move_layer_down(layer_id)
    }
    
    class Layer {
        +int id
        +String name
        +LayerType type
        +bool visible
        +bool locked
        +float opacity
        +Color color
        +Array objects
        +add_object(obj)
        +remove_object(obj)
        +clear()
    }
    
    class LayerType {
        <<enumeration>>
        NORMAL
        GUIDE
        DIMENSION
        REFERENCE
    }
    
    LayerManager "1" *-- "0..*" Layer
    Layer "1" *-- "0..*" CADObject
```

## 约束系统架构

```mermaid
classDiagram
    class ConstraintManager {
        +Array constraints
        +bool is_solving
        +int max_iterations
        +float tolerance
        +add_constraint(constraint)
        +remove_constraint(constraint)
        +clear_constraints()
        +get_constraints_for_object(obj)
        +_queue_solve()
        +_compare_constraint_priority(a, b)
    }
    
    class Constraint {
        <<abstract>>
        +ConstraintType type
        +Array targets
        +bool is_satisfied
        +int priority
        +solve(delta)
        +visualize()
        +check_satisfied()
    }
    
    class GeometricConstraint {
        +solve(delta)
        +_solve_horizontal()
        +_solve_vertical()
        +_solve_parallel()
        +_solve_perpendicular()
        +_solve_tangent()
        +_solve_coincident()
        +_solve_concentric()
    }
    
    class DimensionalConstraint {
        +float value
        +Node2D dimension_line
        +solve(delta)
        +_solve_fixed_distance()
        +_solve_fixed_angle()
        +update_visualization()
    }
    
    class ConstraintType {
        <<enumeration>>
        HORIZONTAL
        VERTICAL
        PARALLEL
        PERPENDICULAR
        TANGENT
        FIXED_DISTANCE
        FIXED_ANGLE
        COINCIDENT
        CONCENTRIC
    }
    
    ConstraintManager "1" *-- "0..*" Constraint
    Constraint <|-- GeometricConstraint
    Constraint <|-- DimensionalConstraint
    Constraint "1" *-- "1..*" CADObject
```

## 捕捉系统架构

```mermaid
classDiagram
    class SnapManager {
        +bool enabled
        +float snap_radius
        +SnapPoint current_snap
        +Array snap_points
        +bool snap_to_grid
        +bool snap_to_endpoints
        +bool snap_to_midpoints
        +bool snap_to_centers
        +bool snap_to_intersections
        +bool snap_to_perpendicular
        +bool snap_to_tangent
        +find_best_snap_point(mouse_pos)
        +get_current_snap()
        +set_current_snap(snap)
        +clear_current_snap()
        +_add_grid_snap_points()
        +_add_object_snap_points(obj)
        +_add_line_snap_points(line)
        +_add_rectangle_snap_points(rect)
        +_add_circle_snap_points(circle)
    }
    
    class SnapPoint {
        +SnapType type
        +Vector2 position
        +CADObject owner
        +int priority
    }
    
    class SnapType {
        <<enumeration>>
        ENDPOINT
        MIDPOINT
        CENTER
        INTERSECTION
        PERPENDICULAR
        TANGENT
        GRID
        NONE
    }
    
    SnapManager "1" *-- "0..*" SnapPoint
    SnapPoint "1" --> "0..1" CADObject
```

## 文件导出架构

```mermaid
classDiagram
    class FileExporter {
        <<abstract>>
        +export(filepath, options)
    }
    
    class SVGExporter {
        +export_to_svg(objects, background, filepath, options)
        +_get_layers_from_objects(objects)
        +_export_object_to_svg(file, obj, opacity)
        +_export_line_to_svg(file, line, opacity)
        +_export_rectangle_to_svg(file, rect, opacity)
        +_export_circle_to_svg(file, circle, opacity)
        +_export_text_to_svg(file, text, opacity)
        +_color_to_hex(color)
    }
    
    class DXFExporter {
        +String header
        +String tables
        +export_to_dxf(objects, filepath)
        +_export_object(file, obj)
        +_export_line(file, line)
        +_export_circle(file, circle)
        +_export_rectangle(file, rect)
        +_export_text(file, text)
    }
    
    class PDFExporter {
        +export_to_pdf(objects, filepath, options)
        +_create_pdf_document()
        +_add_page()
        +_draw_objects()
        +_save_document()
    }
    
    FileExporter <|-- SVGExporter
    FileExporter <|-- DXFExporter
    FileExporter <|-- PDFExporter
```

## 命令处理架构

```mermaid
classDiagram
    class CommandProcessor {
        +Array command_history
        +int history_index
        +String current_command
        +Dictionary commands
        +execute_command(command)
        +_register_builtin_commands()
        +get_command_history()
        +navigate_history(direction)
        +set_current_command(cmd)
    }
    
    class CommandLine {
        +CommandProcessor command_processor
        +Array history
        +int current_history_index
        +_on_text_entered(text)
        +_on_command_history_updated(new_history)
        +_input(event)
        +_navigate_history(direction)
        +_auto_complete()
        +show()
        +hide()
    }
    
    class Command {
        <<interface>>
        +execute(args) bool
    }
    
    CommandProcessor "1" *-- "1" CommandLine
    CommandProcessor "1" *-- "0..*" Command
```

## 数据流图 - 用户交互

```mermaid
flowchart TD
    A[用户输入] --> B[输入处理器]
    B --> C{输入类型}
    
    C -->|鼠标移动| D[捕捉管理器]
    D --> E[查找最佳捕捉点]
    E --> F[更新光标位置]
    
    C -->|工具使用| G[活动工具]
    G --> H[创建/修改对象]
    H --> I[添加到当前图层]
    
    C -->|命令输入| J[命令处理器]
    J --> K[解析命令]
    K --> L[执行操作]
    
    C -->|对象选择| M[选择管理器]
    M --> N[更新选择状态]
    N --> O[显示属性面板]
    
    I --> P[图层管理器]
    L --> P
    O --> P
    
    P --> Q[约束管理器]
    Q --> R[解决约束]
    
    R --> S[渲染更新]
    F --> S
    N --> S
```

## 系统集成概述

```mermaid
graph LR
    subgraph Core System
        A[InfiniteCanvas] --> B[LayerManager]
        A --> C[ConstraintManager]
        A --> D[SnapManager]
        A --> E[SelectionManager]
    end
    
    subgraph UI Components
        F[Toolbar] --> A
        G[LayerPanel] --> B
        H[PropertiesPanel] --> E
        I[CommandLine] --> J[CommandProcessor]
        J --> A
    end
    
    subgraph File System
        K[ProjectLoader] --> A
        L[SVGExporter] --> A
        M[DXFExporter] --> A
        N[PDFExporter] --> A
    end
    
    subgraph User Interaction
        O[Mouse/Keyboard] --> F
        O --> I
        O --> A
        P[Touch] --> A
    end
    
    style Core System fill:#f9f,stroke:#333
    style UI Components fill:#bbf,stroke:#333
    style File System fill:#f96,stroke:#333
    style User Interaction fill:#6f9,stroke:#333
```

## 实施顺序

```mermaid
gantt
    title GOCAD实施时间表
    dateFormat  YYYY-MM-DD
    section 核心基础架构
    图层系统               :a1, 2024-01-01, 14d
    CAD对象基类           :a2, 2024-01-01, 10d
    捕捉系统              :a3, 2024-01-15, 10d
    
    section 基本CAD功能
    基本工具              :b1, 2024-01-20, 14d
    尺寸标注              :b2, 2024-02-01, 10d
    对象选择和属性       :b3, 2024-01-25, 7d
    
    section 高级功能
    约束系统              :c1, 2024-02-10, 21d
    高级编辑工具          :c2, 2024-02-20, 14d
    块和符号库           :c3, 2024-03-01, 10d
    
    section 文件格式
    增强的SVG导出         :d1, 2024-02-15, 7d
    DXF导出               :d2, 2024-02-25, 14d
    项目文件版本化       :d3, 2024-03-05, 7d
    
    section UI/UX
    命令行接口           :e1, 2024-03-10, 10d
    CAD工具栏            :e2, 2024-03-15, 7d
    属性面板             :e3, 2024-03-20, 10d
    图层管理UI           :e4, 2024-03-25, 7d
    
    section 测试和文档
    综合测试套件          :f1, 2024-04-01, 14d
    用户文档             :f2, 2024-04-05, 14d
    开发者文档           :f3, 2024-04-10, 14d
    
    section 发布准备
    开源准备             :g1, 2024-04-20, 7d
    社区构建             :g2, 2024-04-25, 14d
    最终测试和发布       :g3, 2024-05-01, 7d
```

## 关键接口

### 图层管理器接口
```gdscript
# 所有组件与图层管理器交互的方式
interface LayerManagerInterface:
    func create_layer(name: String, type: int) -> Layer
    func remove_layer(layer_id: int) -> void
    func set_active_layer(layer_id: int) -> void
    func get_active_layer() -> Layer
    func get_layer_by_id(layer_id: int) -> Layer
    func get_all_layers() -> Array
    func move_layer_up(layer_id: int) -> void
    func move_layer_down(layer_id: int) -> void
```

### 约束管理器接口
```gdscript
interface ConstraintManagerInterface:
    func add_constraint(constraint: Constraint) -> void
    func remove_constraint(constraint: Constraint) -> void
    func clear_constraints() -> void
    func get_constraints_for_object(obj: Object) -> Array
    func solve_all_constraints() -> bool
    func set_max_iterations(iterations: int) -> void
    func set_tolerance(tolerance: float) -> void
```

### 捕捉管理器接口
```gdscript
interface SnapManagerInterface:
    func set_enabled(enabled: bool) -> void
    func set_snap_radius(radius: float) -> void
    func set_snap_to_grid(enabled: bool) -> void
    func set_snap_to_endpoints(enabled: bool) -> void
    func set_snap_to_midpoints(enabled: bool) -> void
    func set_snap_to_centers(enabled: bool) -> void
    func set_snap_to_intersections(enabled: bool) -> void
    func find_best_snap_point(mouse_pos: Vector2) -> SnapPoint
    func get_current_snap() -> SnapPoint
    func clear_current_snap() -> void
```

## 设计原则

1. **模块化**：每个组件都是自包含的，具有明确的职责
2. **可扩展性**：通过接口和基类设计以便于未来扩展
3. **性能**：优化大型项目的渲染和内存使用
4. **用户体验**：直观的界面和一致的行为
5. **兼容性**：保持对现有功能的支持
6. **文档**：每个组件都有清晰的文档和示例

## 关键技术决策

1. **约束求解**：迭代方法，具有可配置的最大迭代次数和容差
2. **图层渲染**：按图层顺序渲染，具有可配置的不透明度
3. **对象选择**：基于优先级的捕捉点系统
4. **文件格式**：逐步增强，保持向后兼容性
5. **命令处理**：基于文本的接口，具有历史记录和自动完成

这个架构文档提供了GOCAD系统的完整概述，展示了组件如何相互作用以及整体设计原则。它作为实施和未来扩展的蓝图。