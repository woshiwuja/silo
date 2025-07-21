const rl = @import("raylib");
const std = @import("std");
pub const Window = struct {
    width: i32,
    height: i32,
    title: [:0]const u8,
    exitKey: rl.KeyboardKey,
    pub fn init(width: i32, height: i32, title: [:0]const u8, exitKey: rl.KeyboardKey) Window {
        return Window{
            .width = width,
            .height = height,
            .title = title,
            .exitKey = exitKey,
        };
    }
    pub fn openWindow(self: Window) void {
        rl.initWindow(self.width, self.height, self.title);
        rl.setTargetFPS(144); // Set our game to run at 60 frames-per-second
        rl.toggleFullscreen();
        rl.setExitKey(self.exitKey);
        rl.disableCursor();
        rl.drawFPS(10, 10);
    }
    pub fn update(self: Window) void {
        if (rl.isKeyPressed(.f11)) {
            std.debug.print("{}", .{self});
            rl.toggleFullscreen();
        }
    }
};
