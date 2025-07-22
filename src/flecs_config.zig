const ecs = @import("zflecs");
const cmp = @import("components.zig");
const stm = @import("systems.zig");
const cam = @import("camera.zig");
pub fn configFlecs(world: *ecs.world_t) void {
    startRest(world);
    addComponents(world);
    addSystems(world);
}
fn addComponents(world: *ecs.world_t) void {
    ecs.COMPONENT(world, cmp.Position);
    ecs.COMPONENT(world, cmp.ScreenPosition);
    ecs.COMPONENT(world, cmp.Velocity);
    ecs.COMPONENT(world, cmp.Health);
}
fn addSystems(world: *ecs.world_t) void {
    _ = ecs.ADD_SYSTEM(world, "draw", ecs.OnUpdate, stm.draw_model);
    _ = ecs.ADD_SYSTEM(world, "move system", ecs.OnUpdate, stm.move_system);
    _ = ecs.ADD_SYSTEM(world, "draw health", ecs.OnUpdate, stm.draw_health_text);
}
fn startRest(world: *ecs.world_t) void {
    const ecsRest = ecs.lookup_fullpath(world, "flecs.rest.Rest");
    const ecsRestVal: ecs.EcsRest = .{};
    _ = ecs.import_c(world, ecs.FlecsStatsImport, "FlecsStats");
    _ = ecs.set_id(world, ecsRest, ecsRest, @sizeOf(ecs.EcsRest), &ecsRestVal);
}
