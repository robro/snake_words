const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;
const Cell = engine.grid.Cell;

var last_tick: f64 = 0;
var last_key: rl.KeyboardKey = .key_null;

const Facing = enum {
    up,
    down,
    left,
    right,
};

const Part = struct {
    facing: Facing,
    coord: Vector2,
};

pub const Snake = struct {
    chars: ArrayList(u8),
    tick: f64,
    body: ArrayList(Part),
    tail: ?Part = null,

    pub fn update(self: *Snake) void {
        const key_pressed = rl.getKeyPressed();
        if (key_pressed != .key_null) last_key = key_pressed;

        const time = rl.getTime();
        if (time < last_tick + self.tick) return;
        last_tick = time;

        var facing = self.head().facing;
        switch (last_key) {
            .key_up => facing = if (facing != .down) .up else .down,
            .key_down => facing = if (facing != .up) .down else .up,
            .key_left => facing = if (facing != .right) .left else .right,
            .key_right => facing = if (facing != .left) .right else .left,
            else => {},
        }
        var coord = self.head().coord;
        switch (facing) {
            .up => coord.y -= 1,
            .down => coord.y += 1,
            .left => coord.x -= 1,
            .right => coord.x += 1,
        }
        self.body.insert(0, .{ .facing = facing, .coord = coord }) catch unreachable;
        self.tail = self.body.pop();
    }

    pub fn draw(self: *Snake, grid: [][]Cell) void {
        for (self.body.items, 0..) |*part, i| {
            engine.grid.drawToCell(grid, part.coord, .{
                .char = self.chars.items[i],
                .color = rl.Color.white,
            });
        }
    }

    pub fn add(self: *Snake, char: u8) void {
        self.body.append(self.tail.?);
        self.chars.append(char);
    }

    pub fn head(self: *Snake) *Part {
        return &self.body.items[0];
    }

    pub fn free(self: *Snake) void {
        self.chars.deinit();
        self.body.deinit();
    }
};

pub fn createSnake(
    text: [:0]const u8,
    tick: f64,
    coord: Vector2,
    facing: Facing,
    alloc: *Allocator,
) !Snake {
    var chars = ArrayList(u8).init(alloc.*);
    try chars.resize(text.len);
    var body = ArrayList(Part).init(alloc.*);
    try body.resize(text.len);

    var offset: f32 = undefined;
    for (body.items, 0..) |*part, i| {
        chars.items[i] = text[i];
        offset = @floatFromInt(i);
        part.facing = facing;
        part.coord = coord;
        switch (facing) {
            .up => part.coord.y += offset,
            .down => part.coord.y -= offset,
            .left => part.coord.x += offset,
            .right => part.coord.x -= offset,
        }
    }
    return Snake{ .chars = chars, .tick = tick, .body = body };
}
