const window = @import("./window.zig");
const Window = window.Window;
const gui = @import("./gui.zig");
const Gui = gui.Gui;
const rl = @import("raylib");
const Map = @import("map.zig").Map;
const Camera = @import("camera.zig").Camera;
const rg = @import("raygui");
const std = @import("std");
const ecs = @import("zflecs");
const ent = @import("./entity.zig");
const cmp = @import("./component.zig");
const stm = @import("./systems.zig");

const Arraylist = std.ArrayList;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
var visualStyleActive: i32 = 0;
var prevStyle: i32 = 0;
var mB: gui.MessageBox = .init(300, 300, 500, 150, "Test", "X = 0, opzioni a seguire", "Si;Esporta", true, false, true);
var txtValue = [_:0]u8{};
var textBox: gui.TextBox = .init(600, 600, 305, 102, &txtValue, 10000, false, true);
var mA: gui.MessageBox = .init(200, 300, 800, 500, "Import Map", "", "Mappa1;Mappa2", true, true, true);

pub const Game = struct {
    window: Window,
    camera: Camera,
    world: *ecs.world_t,
    deltaTime: f32,
    pub fn init(
        gameWindow: Window,
        gameCamera: Camera,
    ) Game {
        return Game{
            .window = gameWindow,
            .camera = gameCamera,
            .deltaTime = 0,
            .world = undefined,
        };
    }
    pub fn start(self: *Game) !void {
        self.window.openWindow();
        gui.loadStyle(.amber);
        self.world = ecs.init();
        const EcsRest = ecs.lookup_fullpath(self.world, "flecs.rest.Rest");
        const EcsRestVal: ecs.EcsRest = .{};
        _ = ecs.import_c(self.world, ecs.FlecsStatsImport, "FlecsStats");
        _ = ecs.set_id(self.world, EcsRest, EcsRest, @sizeOf(ecs.EcsRest), &EcsRestVal);
        ecs.COMPONENT(self.world, cmp.Position);
        ecs.COMPONENT(self.world, cmp.ScreenPosition);
        ecs.COMPONENT(self.world, cmp.Velocity);
        ecs.COMPONENT(self.world, Camera);
        ecs.COMPONENT(self.world, cmp.Health);
        _ = ecs.ADD_SYSTEM(self.world, "draw", ecs.OnUpdate, stm.draw_model);
        _ = ecs.ADD_SYSTEM(self.world, "move system", ecs.OnUpdate, stm.move_system);
        _ = ecs.ADD_SYSTEM(self.world, "draw health", ecs.OnUpdate, stm.draw_health_text);
    }
    pub fn loop(self: *Game) !void {
        var map = try Map.initDefault();
        while (!rl.windowShouldClose()) {
            if (rl.isCursorHidden()) self.camera.updateCameraMode(.free);
            if (rl.isKeyPressed(.escape)) {
                if (rl.isCursorHidden()) {
                    rl.enableCursor();
                } else {
                    rl.disableCursor();
                }
            }
            rl.beginDrawing();
            rl.clearBackground(.ray_white);
            self.camera.beginMode3D();
            self.window.update();
            _ = ecs.progress(self.world, 0);
            map.update();
            rl.endMode3D();
            try guiLoop(self, &map);
        }
    }

    fn guiLoop(self: *Game, map: *Map) !void {
        rl.drawFPS(10, 10);
        var counter: i32 = 0;
        if (visualStyleActive != prevStyle) {
            switch (visualStyleActive) {
                0 => {
                    gui.loadStyle(.ashes);
                },
                1 => {
                    gui.loadStyle(.amber);
                },
                2 => {
                    gui.loadStyle(.cherry);
                },
                3 => {
                    gui.loadStyle(.cyber);
                },
                4 => {
                    gui.loadStyle(.dark);
                },
                5 => {
                    gui.loadStyle(.enefete);
                },
                else => {
                    gui.loadStyle(.ashes);
                },
            }
            prevStyle = visualStyleActive;
        }
        _ = rg.comboBox(.{ .height = 100, .width = 300, .x = 100, .y = 0 }, "Amber;Ashen;Cherry;Cyber;Dark;Enefete;", &visualStyleActive);
        textBox.draw();
        const p = mA.draw();
        switch (p) {
            1 => {
                try map.loadObj("resources/models/gltf/map.glb");
            },
            2 => {
                try map.loadObj("resources/models/obj/map.obj");
            },
            0 => {
                mA.show = false;
            },
            else => {},
        }
        const s = mB.draw();
        switch (s) {
            1 => {
                //try self.entities.append(Entity{ .id = counter, .position = .init(@floatFromInt(counter + 2), @floatFromInt(counter), 0), .started = false });
                const e = ecs.new_id(self.world);
                _ = ecs.set(self.world, e, cmp.Position, .{ .x = 20, .y = 20, .z = 20 });
                _ = ecs.set(self.world, e, cmp.Velocity, .{ .x = 10, .y = 0, .z = 0 });
                _ = ecs.set(self.world, e, cmp.Health, .{ .min = 0, .max = 100, .current = 100 });
                counter += 1;
            },
            2 => {
                //try map.exportToObj("test.obj");
                std.debug.print("exported", .{});
            },
            0 => {
                mB.show = false;
            },
            else => {},
        }
        rl.endDrawing();
    }

    pub fn end(self: *Game) void {
        rl.closeWindow();
        _ = ecs.fini(self.world);
    }
};
