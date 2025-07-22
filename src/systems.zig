const cmp = @import("./components.zig");
const std = @import("std");
const rl = @import("raylib");
const camera = @import("camera.zig");
const Position = cmp.Position;
const Velocity = cmp.Velocity;
const ecs = @import("zflecs");

pub fn draw_model(positions: []Position) void {
    for (positions) |position| {
        const pos: rl.Vector3 = .init(position.x, position.y, position.z);
        rl.drawSphere(pos, 1, .blue);
    }
}

pub fn draw_health_text(positions: []cmp.Position, healths: []cmp.Health) void {
    for (positions, healths) |p, h| {
        const cameraTarget: rl.Vector3 = .init(p.x, p.y, p.z);
        const position: rl.Vector3 = .init(p.x, p.y, p.z);
        const cam = rl.Camera3D{ .target = cameraTarget, .fovy = 0.45, .position = position, .projection = .perspective, .up = .init(0, 1, 0) };
        rl.beginMode3D(cam);
        const pos = rl.getWorldToScreen(position, cam);
        rl.endMode3D();
        std.debug.print("POSITION {}\n", .{pos});
        rl.drawText(rl.textFormat("Health %i", .{h.current}), 0, 0, 20, .black);
    }
}

pub fn move_system(positions: []Position, velocities: []const Velocity) void {
    for (positions, velocities) |*p, v| {
        p.x += v.x * rl.getFrameTime();
        p.y += v.y * rl.getFrameTime();
        p.z += v.z * rl.getFrameTime();
    }
}
