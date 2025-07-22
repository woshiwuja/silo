const jolt = @import("zphysics");

fn start() !void {
    try jolt.init();
    defer jolt.deinit();
}
