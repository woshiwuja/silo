const cmp = @import("./component.zig");
const std = @import("std");
const rl = @import("raylib");
const camera = @import("camera.zig");
const Position = cmp.Position;
const Velocity = cmp.Velocity;

pub fn draw_model(positions: []Position) void {
    for (positions) |position| {
        const pos: rl.Vector3 = .init(position.x, position.y, position.z);
        rl.drawSphere(pos, 1, .blue);
    }
}

pub fn draw_health_text(screenPositions: []cmp.ScreenPosition, healths: []cmp.Health) void {
    for (screenPositions, healths) |p, h| {
        rl.drawText(rl.textFormat("Health %i", .{h.current}), @intFromFloat(p.x), @intFromFloat(p.y), 50, .black);
    }
}

pub fn move_system(positions: []Position, velocities: []const Velocity) void {
    for (positions, velocities) |*p, v| {
        p.x += v.x * rl.getFrameTime();
        p.y += v.y * rl.getFrameTime();
        p.z += v.z * rl.getFrameTime();
    }
}
