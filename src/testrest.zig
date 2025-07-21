const ecs = @import("zflecs");
const std = @import("std");
pub fn main() !void {
    const world = ecs.init();
    defer _ = ecs.fini(world);
    const EcsRest = ecs.lookup_fullpath(world, "flecs.rest.Rest");
    const EcsRestVal: ecs.EcsRest = .{};
    _ = ecs.import_c(world, ecs.FlecsStatsImport, "FlecsStats");
    _ = ecs.set_id(world, EcsRest, EcsRest, @sizeOf(ecs.EcsRest), &EcsRestVal);
    while (true) {
        _ = ecs.progress(world, 0);
    }
}
