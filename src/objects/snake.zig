const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;
const Cell = engine.grid.Cell;

var _last_tick: f64 = 0;
var _last_key: rl.KeyboardKey = .key_null;

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
    cells: ArrayList(Cell),
    tick: f64,
    parts: ArrayList(Part),
    tail: ?Part = null,

    pub fn update(self: *Snake) void {
        const key_pressed = rl.getKeyPressed();
        if (key_pressed != .key_null) _last_key = key_pressed;

        const time = rl.getTime();
        if (time < _last_tick + self.tick) return;
        _last_tick = time;

        var facing = self.head().facing;
        switch (_last_key) {
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
        self.parts.insert(0, .{ .facing = facing, .coord = coord }) catch unreachable;
        self.tail = self.parts.pop();
    }

    pub fn draw(self: *Snake, grid: [][]Cell) void {
        for (self.parts.items, 0..) |*part, i| {
            engine.grid.drawCell(grid, part.coord, self.cells.items[i]);
        }
    }

    pub fn add(self: *Snake, cell: Cell) void {
        self.parts.append(self.tail.?);
        self.cells.append(cell);
    }

    pub fn head(self: *Snake) *Part {
        return &self.parts.items[0];
    }

    pub fn free(self: *Snake) void {
        self.cells.deinit();
        self.parts.deinit();
    }
};

pub fn createSnake(
    word: [:0]const u8,
    color: rl.Color,
    tick: f64,
    coord: Vector2,
    facing: Facing,
    alloc: *Allocator,
) !Snake {
    var cells = ArrayList(Cell).init(alloc.*);
    try cells.resize(word.len);
    var body = ArrayList(Part).init(alloc.*);
    try body.resize(word.len);

    var offset: f32 = undefined;
    for (body.items, 0..) |*part, i| {
        cells.items[i] = .{ .char = word[i], .color = color };
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
    return Snake{ .cells = cells, .tick = tick, .parts = body };
}
