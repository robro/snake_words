const rl = @import("raylib");

const KeyboardKey = rl.KeyboardKey;

var last_pressed: KeyboardKey = .key_null;

pub fn getLastPressed() KeyboardKey {
    return last_pressed;
}

pub fn update() void {
    const pressed = rl.getKeyPressed();
    if (pressed != .key_null) last_pressed = pressed;
}
