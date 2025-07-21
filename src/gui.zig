const rg = @import("raygui");
const std = @import("std");
const rl = @import("raylib");
const fmt = std.fmt;
const imgui = @import("imgui");
pub const Style = enum { amber, ashes, candy, cherry, cyber, dark, enefete };
const WINDOWBOX_STATUSBAR_HEIGHT: i32 = 24;
const WINDOW_CLOSEBUTTON_SIZE: i32 = 18;
const closeTitleSizeDeltaHalf = (WINDOWBOX_STATUSBAR_HEIGHT - WINDOW_CLOSEBUTTON_SIZE) / 2;

pub fn destroy() void {}
pub fn start() void {}
pub fn update() void {}
pub fn drawDemo() void {}
pub fn render() void {}
pub fn newFrame() void {}

pub fn loadStyle(style: Style) void {
    switch (style) {
        .amber => {
            const stylePath = "resources/gui/styles/style_amber.rgs";
            rg.loadStyle(stylePath);
        },
        .ashes => {
            const stylePath = "resources/gui/styles/style_ashes.rgs";
            rg.loadStyle(stylePath);
        },
        .candy => {
            const stylePath = "resources/gui/styles/style_candy.rgs";
            rg.loadStyle(stylePath);
        },
        .cherry => {
            const stylePath = "resources/gui/styles/style_cherry.rgs";
            rg.loadStyle(stylePath);
        },
        .cyber => {
            const stylePath = "resources/gui/styles/style_cyber.rgs";
            rg.loadStyle(stylePath);
        },
        .dark => {
            const stylepath = "resources/gui/styles/style_dark.rgs";
            rg.loadStyle(stylepath);
        },
        .enefete => {
            const stylepath = "resources/gui/styles/style_enefete.rgs";
            rg.loadStyle(stylepath);
        },
    }
}
pub const MessageBox = struct {
    bounds: rl.Rectangle,
    title: [:0]const u8,
    message: [:0]const u8,
    buttons: [:0]const u8,
    show: bool,
    moving: bool,
    resizing: bool,
    minimized: bool,
    movable: bool,
    resizable: bool,
    pub fn init(
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        title: [:0]const u8,
        message: [:0]const u8,
        buttons: [:0]const u8,
        show: bool,
        resizable: bool,
        movable: bool,
    ) MessageBox {
        const rectangle: rl.Rectangle = .init(x, y, width, height);
        return MessageBox{ .bounds = rectangle, .title = title, .message = message, .buttons = buttons, .moving = false, .resizing = false, .show = show, .minimized = false, .resizable = resizable, .movable = movable };
    }
    pub fn draw(self: *MessageBox) i32 {
        if (self.movable) {
            self.move();
        }
        if (self.resizable) {
            self.resize();
        }
        //buttons = strconcat for each button in buttons - sepafunctionrator ;
        if (self.show) {
            const buttonClicked = rg.messageBox(self.bounds, self.title, self.message, self.buttons);
            if (buttonClicked == 0) {
                self.show = false;
            }
            return buttonClicked;
        } else {
            return 9999;
        }
    }
    fn move(self: *MessageBox) void {
        const mPos = rl.getMousePosition();
        const titleBarArea: rl.Rectangle = .init(self.bounds.x, self.bounds.y, self.bounds.width - (WINDOW_CLOSEBUTTON_SIZE + closeTitleSizeDeltaHalf), WINDOWBOX_STATUSBAR_HEIGHT);
        if (rl.isMouseButtonDown(.left) and !self.resizing and rl.checkCollisionPointRec(mPos, titleBarArea)) {
            self.moving = true;
        } else {
            self.moving = false;
        }
        if (self.moving) {
            const mouse_delta = rl.getMouseDelta();
            self.bounds.x += mouse_delta.x;
            self.bounds.y += mouse_delta.y;
        }
    }
    fn resize(self: *MessageBox) void {
        const mPos = rl.getMousePosition();
        const resizeArea: rl.Rectangle = .init(self.bounds.x + self.bounds.width - 20, self.bounds.y + self.bounds.height - 20, 20, 20);
        if (rl.isMouseButtonDown(.left) and !self.moving and rl.checkCollisionPointRec(mPos, resizeArea)) {
            self.resizing = true;
        } else {
            self.resizing = false;
        }
        if (self.resizing) {
            if (mPos.x > self.bounds.x) {
                self.bounds.width = mPos.x - self.bounds.x;
            }
            if (mPos.y > self.bounds.y) {
                self.bounds.height = mPos.y - self.bounds.y;
            }
        }
    }
};

pub const TextBox = struct {
    bounds: rl.Rectangle,
    text: [:0]u8,
    textSize: i32,
    editMode: bool,
    show: bool,
    pub fn init(
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        text: [:0]u8,
        textSize: i32,
        editMode: bool,
        show: bool,
    ) TextBox {
        const rectangle: rl.Rectangle = .init(x, y, width, height);
        return TextBox{
            .bounds = rectangle,
            .text = text,
            .textSize = textSize,
            .editMode = editMode,
            .show = show,
        };
    }
    pub fn draw(self: *TextBox) void {
        if (self.show) {
            if (rl.checkCollisionPointRec(rl.getMousePosition(), self.bounds)) {
                if (rl.isMouseButtonPressed(.left)) {
                    self.editMode = true;
                }
            } else {
                if (rl.isMouseButtonPressed(.left)) {
                    self.editMode = false;
                }
            }
            const enterPressed = rg.textBox(self.bounds, self.text, self.textSize, self.editMode);
            if (enterPressed) {
                self.editMode = false;
                self.show = false;
            }
        }
    }
};

pub const Text3D = struct {};
