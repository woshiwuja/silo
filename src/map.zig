const rl = @import("raylib");
const std = @import("std");
const io = std.io;
const ent = @This();
const math = std.math;
const Allocator = std.mem.Allocator;
pub const Map: type = struct {
    image: rl.Image,
    texture: rl.Texture,
    size: rl.Vector3,
    mesh: rl.Mesh,
    model: rl.Model,
    position: rl.Vector3,
    navMesh: NavMesh,
    pub fn init(map: [:0]const u8, size: rl.Vector3, position: rl.Vector3) !Map {
        const image = try rl.loadImage(map);
        const texture = try rl.loadTextureFromImage(image);
        const mesh = rl.genMeshHeightmap(image, size);
        var model = try rl.loadModelFromMesh(mesh);
        model.materials[0].maps[@intFromEnum(rl.MATERIAL_MAP_DIFFUSE)].texture = texture;
        return Map{ .image = image, .texture = texture, .mesh = mesh, .size = size, .model = model, .position = position, .navMesh = undefined };
    }
    pub fn initDefault() anyerror!Map {
        const image = try rl.loadImage("resources/map256x256.png");
        const texture = try rl.loadTextureFromImage(image);
        const meshSize: rl.Vector3 = .init(500, 20, 500);
        const mesh = rl.genMeshHeightmap(image, meshSize);
        var model = try rl.loadModelFromMesh(mesh);
        model.materials[0].maps[@intFromEnum(rl.MATERIAL_MAP_DIFFUSE)].texture = texture;
        const mapPosition: rl.Vector3 = .init(0, 0, 0);
        return Map{ .image = image, .texture = texture, .mesh = mesh, .size = meshSize, .model = model, .position = mapPosition, .navMesh = undefined };
    }
    pub fn loadObj(self: *Map, objFile: [:0]const u8) !void {
        self.model = try rl.loadModel(objFile);
    }
    fn drawMap(self: Map) void {
        rl.drawModel(self.model, self.position, 1, .beige);
    }
    pub fn update(self: Map) void {
        drawMap(self);
        //getRayCollisionOctreeNode(ray, node);
    }
    pub fn destroy(self: Map) void {
        rl.unloadTexture(self.texture);
        rl.unloadModel(self.model);
    }
    pub fn createNavMesh(self: *Map) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();
        const cell_size: f32 = 0.5;
        const agent_radius: f32 = 0.25;
        if (self.mesh.vertexCount == 0) {
            return error.EmptyMesh;
        }
        self.navMesh = try generateNavigationMesh(allocator, &self.mesh, cell_size, agent_radius);
    }
    pub fn exportToObj(self: *Map, file_path: []const u8) !void {
        const fs = std.fs;
        var file = try fs.cwd().createFile(file_path, .{ .truncate = true });
        defer file.close();

        var writer = file.writer();
        const vc = @as(usize, @intCast(self.mesh.vertexCount));
        const tc = @as(usize, @intCast(self.mesh.triangleCount));
        const hasIndex = self.mesh.indices != null;

        // ──────── Vertici ────────
        for (0..vc) |i| {
            const x = self.mesh.vertices[i * 3 + 0];
            const y = self.mesh.vertices[i * 3 + 1];
            const z = self.mesh.vertices[i * 3 + 2];
            try writer.print("v {!d:.6} {!d:.6} {!d:.6}\n", .{ x, y, z });
        }

        // ──────── Texture coords (opzionale) ────────
        if (self.mesh.texcoords) |tc_buf| {
            for (0..vc) |i| {
                const u = tc_buf[i * 2 + 0];
                const v = tc_buf[i * 2 + 1];
                try writer.print("vt {!d:.6} {!d:.6}\n", .{ u, 1.0 - v });
            }
        }

        // ──────── Normali (opzionale) ────────
        if (self.mesh.normals) |n_buf| {
            for (0..vc) |i| {
                const nx = n_buf[i * 3 + 0];
                const ny = n_buf[i * 3 + 1];
                const nz = n_buf[i * 3 + 2];
                try writer.print("vn {!d:.6} {!d:.6} {!d:.6}\n", .{ nx, ny, nz });
            }
        }

        // ──────── Facce ────────
        const use_tc = self.mesh.texcoords != null;
        const use_nm = self.mesh.normals != null;
        for (0..tc) |i| {
            const base = i * 3;
            const vi0 = if (hasIndex) @as(usize, self.mesh.indices.?[base + 0]) + 1 else base + 1;
            const vi1 = if (hasIndex) @as(usize, self.mesh.indices.?[base + 1]) + 1 else base + 2;
            const vi2 = if (hasIndex) @as(usize, self.mesh.indices.?[base + 2]) + 1 else base + 3;

            if (use_tc and use_nm) {
                try writer.print("f {!d}/{!d}/{!d} {!d}/{!d}/{!d} {!d}/{!d}/{!d}\n", .{ vi0, vi0, vi0, vi1, vi1, vi1, vi2, vi2, vi2 });
            } else if (use_tc) {
                try writer.print("f {!d}/{!d} {!d}/{!d} {!d}/{!d}\n", .{ vi0, vi0, vi1, vi1, vi2, vi2 });
            } else if (use_nm) {
                try writer.print("f {!d}//{!d} {!d}//{!d} {!d}//{!d}\n", .{ vi0, vi0, vi1, vi1, vi2, vi2 });
            } else {
                try writer.print("f {!d} {!d} {!d}\n", .{ vi0, vi1, vi2 });
            }
        }
    }
};
const NavCell = struct {
    center: rl.Vector2,
    size: f32,
    walkable: bool,
    connections: std.ArrayList(*NavCell),
    world_pos: rl.Vector3,

    fn init(allocator: Allocator, center: rl.Vector2, size: f32) NavCell {
        return NavCell{
            .center = center,
            .size = size,
            .walkable = false,
            .connections = std.ArrayList(*NavCell).init(allocator),
            .world_pos = rl.Vector3.init(0, 0, 0),
        };
    }

    fn deinit(self: *NavCell) void {
        self.connections.deinit();
    }

    fn addConnection(self: *NavCell, other: *NavCell) !void {
        try self.connections.append(other);
    }
};
const NavPolygon = struct {
    vertices: std.ArrayList(rl.Vector2),
    center: rl.Vector2,
    connections: std.ArrayList(*NavPolygon),

    fn init(allocator: Allocator, center: rl.Vector2) NavPolygon {
        return NavPolygon{
            .vertices = std.ArrayList(rl.Vector2).init(allocator),
            .center = center,
            .connections = std.ArrayList(*NavPolygon).init(allocator),
        };
    }

    fn deinit(self: *NavPolygon) void {
        self.vertices.deinit();
        self.connections.deinit();
    }

    fn addVertex(self: *NavPolygon, vertex: rl.Vector2) !void {
        try self.vertices.append(vertex);
    }

    fn addConnection(self: *NavPolygon, other: *NavPolygon) !void {
        try self.connections.append(other);
    }
};

const NavMesh = struct {
    allocator: std.mem.Allocator,
    polygons: std.ArrayList(NavPolygon),
    cells: std.ArrayList(NavCell),
    cell_size: f32,
    agent_radius: f32,
    bounds: Bounds2D,

    fn init(allocator: std.mem.Allocator, cell_size: f32, agent_radius: f32) NavMesh {
        return NavMesh{
            .allocator = allocator,
            .polygons = std.ArrayList(NavPolygon).init(allocator),
            .cells = std.ArrayList(NavCell).init(allocator),
            .cell_size = cell_size,
            .agent_radius = agent_radius,
            .bounds = Bounds2D{
                .min = .init(0, 0),
                .max = .init(0, 0),
            },
        };
    }

    pub fn deinit(self: *NavMesh) void {
        // Clean up cells
        for (self.cells.items) |*cell| {
            cell.deinit();
        }
        self.cells.deinit();

        // Clean up polygons
        for (self.polygons.items) |*polygon| {
            polygon.deinit();
        }
        self.polygons.deinit();
    }

    fn addCell(self: *NavMesh, cell: NavCell) !void {
        try self.cells.append(cell);
    }

    fn addPolygon(self: *NavMesh, polygon: NavPolygon) !void {
        try self.polygons.append(polygon);
    }
};
fn generateNavigationMesh(allocator: std.mem.Allocator, mesh: *const rl.Mesh, cell_size: f32, agent_radius: f32) !NavMesh {
    if (mesh.vertexCount == 0) {
        return error.EmptyMesh;
    }

    var navMesh = NavMesh.init(allocator, cell_size, agent_radius);
    navMesh.bounds = getMeshBounds2D(mesh);

    std.debug.print("Mesh bounds: ({d:.2}, {d:.2}) to ({d:.2}, {d:.2})\n", .{
        navMesh.bounds.min.x, navMesh.bounds.min.y,
        navMesh.bounds.max.x, navMesh.bounds.max.y,
    });

    // Create spatial grid
    navMesh.cells = try createSpatialGrid(allocator, mesh, cell_size, navMesh.bounds);

    // Count walkable cells
    var walkable_count: usize = 0;
    for (navMesh.cells.items) |*cell| {
        if (cell.walkable) walkable_count += 1;
    }

    std.debug.print("Created {} cells, {} walkable\n", .{ navMesh.cells.items.len, walkable_count });

    // Connect walkable cells
    try connectWalkableCells(&navMesh.cells, cell_size);

    // Generate navigation polygons
    navMesh.polygons = try generateNavPolygons(allocator, &navMesh.cells);

    std.debug.print("Generated {} navigation polygons\n", .{navMesh.polygons.items.len});

    return navMesh;
}
fn getMeshBounds2D(mesh: *const rl.Mesh) Bounds2D {
    if (mesh.vertexCount == 0) {
        return Bounds2D{
            .min = rl.Vector2.init(0, 0),
            .max = rl.Vector2.init(0, 0),
        };
    }

    var min_x = mesh.vertices[0];
    var max_x = mesh.vertices[0];
    var min_z = mesh.vertices[2];
    var max_z = mesh.vertices[2];

    var i: usize = 0;
    while (i < mesh.vertexCount) : (i += 1) {
        const x = mesh.vertices[i * 3];
        const z = mesh.vertices[i * 3 + 2];

        if (x < min_x) min_x = x;
        if (x > max_x) max_x = x;
        if (z < min_z) min_z = z;
        if (z > max_z) max_z = z;
    }

    return Bounds2D{
        .min = rl.Vector2.init(min_x, min_z),
        .max = rl.Vector2.init(max_x, max_z),
    };
}

const Bounds2D = struct {
    min: rl.Vector2,
    max: rl.Vector2,
};

fn createSpatialGrid(allocator: Allocator, mesh: *const rl.Mesh, cell_size: f32, bounds: Bounds2D) !std.ArrayList(NavCell) {
    const grid_width = @as(usize, @intFromFloat(math.ceil((bounds.max.x - bounds.min.x) / cell_size)));
    const grid_height = @as(usize, @intFromFloat(math.ceil((bounds.max.y - bounds.min.y) / cell_size)));

    var cells = std.ArrayList(NavCell).init(allocator);
    try cells.ensureTotalCapacity(grid_width * grid_height);

    var y: usize = 0;
    while (y < grid_height) : (y += 1) {
        var x: usize = 0;
        while (x < grid_width) : (x += 1) {
            const center = rl.Vector2.init(
                bounds.min.x + (@as(f32, @floatFromInt(x)) + 0.5) * cell_size,
                bounds.min.y + (@as(f32, @floatFromInt(y)) + 0.5) * cell_size,
            );

            var cell = NavCell.init(allocator, center, cell_size);

            // Test if cell is walkable
            var height: f32 = 0;
            if (isPointOnMesh(mesh, center, &height)) {
                cell.walkable = true;
                std.debug.print("is cell walkable? {}\n", .{cell.walkable});
                cell.world_pos = rl.Vector3.init(center.x, height, center.y);
            }

            try cells.append(cell);
        }
    }

    return cells;
}
fn connectWalkableCells(cells: *std.ArrayList(NavCell), cell_size: f32) !void {
    for (cells.items, 0..) |*cell, i| {
        if (!cell.walkable) continue;

        for (cells.items, 0..) |*other_cell, j| {
            if (i == j or !other_cell.walkable) continue;

            const distance = cell.center.distance(other_cell.center);

            // Connect if adjacent (within 1.5 * cell_size for diagonal connections)
            if (distance <= cell_size * 1.5) {
                try cell.addConnection(other_cell);
            }
        }
    }
}

fn generateNavPolygons(allocator: Allocator, cells: *const std.ArrayList(NavCell)) !std.ArrayList(NavPolygon) {
    var polygons = std.ArrayList(NavPolygon).init(allocator);

    // Create polygon for each walkable cell
    for (cells.items) |*cell| {
        if (!cell.walkable) continue;

        var polygon = NavPolygon.init(allocator, cell.center);

        // Create square polygon from cell
        const half_size = cell.size * 0.5;
        try polygon.addVertex(rl.Vector2.init(cell.center.x - half_size, cell.center.y - half_size));
        try polygon.addVertex(rl.Vector2.init(cell.center.x + half_size, cell.center.y - half_size));
        try polygon.addVertex(rl.Vector2.init(cell.center.x + half_size, cell.center.y + half_size));
        try polygon.addVertex(rl.Vector2.init(cell.center.x - half_size, cell.center.y + half_size));

        try polygons.append(polygon);
    }

    // Link polygon connections
    var poly_index: usize = 0;
    for (cells.items) |*cell| {
        if (!cell.walkable) continue;

        var polygon = &polygons.items[poly_index];

        for (cell.connections.items) |connected_cell| {
            // Find the polygon corresponding to this connected cell
            var connected_poly_index: usize = 0;
            for (cells.items) |*other_cell| {
                if (!other_cell.walkable) continue;

                if (other_cell == connected_cell) {
                    try polygon.addConnection(&polygons.items[connected_poly_index]);
                    break;
                }
                connected_poly_index += 1;
            }
        }

        poly_index += 1;
    }

    return polygons;
}
fn isPointOnMesh(mesh: *const rl.Mesh, point: rl.Vector2, height: *f32) bool {
    // Convert non-indexed mesh to triangles and test
    var i: usize = 0;
    while (i < mesh.vertexCount) : (i += 3) {
        const v1 = rl.Vector2.init(mesh.vertices[i * 3], mesh.vertices[i * 3 + 2]);
        const v2 = rl.Vector2.init(mesh.vertices[(i + 1) * 3], mesh.vertices[(i + 1) * 3 + 2]);
        const v3 = rl.Vector2.init(mesh.vertices[(i + 2) * 3], mesh.vertices[(i + 2) * 3 + 2]);

        if (pointInTriangle(point, v1, v2, v3)) {
            // Calculate height using simple average (you could use barycentric coordinates for more accuracy)
            const y1 = mesh.vertices[i * 3 + 1];
            const y2 = mesh.vertices[(i + 1) * 3 + 1];
            const y3 = mesh.vertices[(i + 2) * 3 + 1];

            height.* = (y1 + y2 + y3) / 3.0;
            return true;
        }
    }
    return false;
}
fn pointInTriangle(p: rl.Vector2, a: rl.Vector2, b: rl.Vector2, c: rl.Vector2) bool {
    const v0 = c.subtract(a);
    const v1 = b.subtract(a);
    const v2 = p.subtract(a);

    const dot00 = v0.dotProduct(v0);
    const dot01 = v0.dotProduct(v1);
    const dot02 = v0.dotProduct(v2);
    const dot11 = v1.dotProduct(v1);
    const dot12 = v1.dotProduct(v2);

    const inv_denom = 1.0 / (dot00 * dot11 - dot01 * dot01);
    const u = (dot11 * dot02 - dot01 * dot12) * inv_denom;
    const v = (dot00 * dot12 - dot01 * dot02) * inv_denom;

    return (u >= 0) and (v >= 0) and (u + v <= 1);
}
