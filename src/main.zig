const rg = @import("raygui");
const rl = @import("raylib");
const std = @import("std");
const Game = @import("game.zig").Game;

var game = Game.init(
    .init(1920, 1080, "test", .end),
    .init(.init(20, 20, 20), .init(0, 8, 0), .init(0, 1.6, 0), 45.0, .perspective),
);
pub fn main() anyerror!void {
    try game.start();
    try game.loop();
    defer game.end();
}
