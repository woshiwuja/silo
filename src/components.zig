const rl = @import("raylib");
const ecs = @import("zflecs");
pub const Position = struct { x: f32, y: f32, z: f32 };
pub const Velocity = struct { x: f32, y: f32, z: f32 };
pub const Health = struct { min: i32, max: i32, current: i32 };
pub const ScreenPosition = rl.Vector2;
