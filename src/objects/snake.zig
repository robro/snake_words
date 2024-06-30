const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;

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

    _tail: ?Part = null,
    _last_tick: f64 = 0,

    pub fn init(
        text: [:0]const u8,
        color: rl.Color,
        tick: f64,
        coord: Vector2,
        facing: Facing,
        alloc: Allocator,
    ) !Snake {
        var cells = ArrayList(Cell).init(alloc);
        try cells.resize(text.len);
        var body = ArrayList(Part).init(alloc);
        try body.resize(text.len);

        var offset: f32 = undefined;
        for (body.items, 0..) |*part, i| {
            cells.items[i] = .{ .char = text[i], .color = color };
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

    pub fn deinit(self: *Snake) void {
        self.cells.deinit();
        self.parts.deinit();
    }

    pub fn update(self: *Snake) void {
        const time = rl.getTime();
        if (time < self._last_tick + self.tick) return;
        self._last_tick = time;

        var facing = self.head().facing;
        switch (engine.input.getLastPressed()) {
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
        self._tail = self.parts.pop();
    }

    pub fn add(self: *Snake, cell: Cell) !void {
        try self.parts.append(self._tail.?);
        try self.cells.append(cell);
    }

    pub fn draw(self: *Snake, grid: *Grid) void {
        for (self.parts.items, 0..) |*part, i| {
            grid.setCell(part.coord, self.cells.items[i]);
        }
    }

    pub fn head(self: *Snake) *Part {
        return &self.parts.items[0];
    }
};
