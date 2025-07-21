const rl = @import("raylib");
pub const Camera: type = struct {
    position: rl.Vector3,
    target: rl.Vector3,
    up: rl.Vector3,
    fovy: f32,
    projection: rl.CameraProjection,
    rlCamera: rl.Camera,
    pub fn init(position: rl.Vector3, target: rl.Vector3, up: rl.Vector3, fovy: f32, projection: rl.CameraProjection) Camera {
        const rlCamera = rl.Camera{
            .position = position,
            .target = target,
            .up = up,
            .fovy = fovy,
            .projection = projection,
        };
        return Camera{ .position = position, .target = target, .up = up, .fovy = fovy, .projection = projection, .rlCamera = rlCamera };
    }
    pub fn update() void {}
    pub fn updateCameraMode(self: *Camera, mode: rl.CameraMode) void {
        rl.updateCamera(&self.rlCamera, mode);
    }
    pub fn beginMode3D(self: Camera) void {
        rl.beginMode3D(self.rlCamera);
    }
};
