# Map Creator Enhancement Implementation TODO

## Current Status
- Basic grid-based map editor with ocean base, grid, and objects layers
- Tools: select, brush, stamp, line, shape, text, note
- Biome system with colors for rendering

## Implementation Steps

### 1. Multiple Grid Support
- [x] Update GridPainter to support 'hex' gridType with flat-top hexagons
- [x] Read map_creator_dialog.dart to understand current structure
- [x] Add grid type selection (square/hex) in map creation dialog
- [x] Update map model to include gridType field (if needed)
- [x] Ensure grid type is only editable during creation
- [x] Update map editor to use gridType from mapData for grid layer

### 2. Land Layers Implementation
- [x] Fully implement ElevationPainter with height-based rendering
- [ ] Enhance BiomePainter with proper biome data rendering and brush strokes
- [ ] Implement TerrainPainter for natural features (mountains, forests)
- [ ] Enhance SettlementsPainter with improved stamp rendering

### 3. Brush Tool Enhancements
- [ ] Add tool settings panel widget
- [ ] Add brush size, opacity, shape (circle/square) controls
- [ ] Add biome type selector for brush
- [ ] Update brush application logic to use new settings
- [ ] Integrate tool settings panel into main UI

### 4. Stamp Tool Enhancements
- [ ] Add stamp types (town, mountain, castle, forest grove)
- [ ] Add rotation and scaling controls in tool settings
- [ ] Update stamp rendering with new types and transformations
- [ ] Add stamp library browser

### 5. Texture System
- [ ] Add texture loading system from assets
- [ ] Implement texture rendering for layers
- [ ] Add texture blending for smooth transitions
- [ ] Update layer rendering to support textures

### 6. Layer Management
- [ ] Update layer panel with blending modes
- [ ] Add layer reordering functionality
- [ ] Add opacity sliders for each layer
- [ ] Improve layer visibility toggles

### 7. UI Improvements
- [ ] Add color picker for custom biomes
- [ ] Implement undo/redo for brush and stamp operations
- [ ] Add comprehensive tool settings panel
- [ ] Enhance overall UI layout

### 8. Export Functionality
- [ ] Implement basic SVG export for the map
- [ ] Add export options and settings
