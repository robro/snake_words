const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;
const KeyboardKey = rl.KeyboardKey;

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
    parts: ArrayList(Part),
    tick: f64,

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

    pub fn handleInput(self: *Snake, pressed: KeyboardKey) void {
        var facing = self.head().facing;
        switch (pressed) {
            .key_up => facing = if (facing != .down) .up else .down,
            .key_down => facing = if (facing != .up) .down else .up,
            .key_left => facing = if (facing != .right) .left else .right,
            .key_right => facing = if (facing != .left) .right else .left,
            else => {},
        }
        self.head().facing = facing;
    }

    pub fn update(self: *Snake) void {
        const time = rl.getTime();
        if (time < self._last_tick + self.tick) return;
        self._last_tick = time;

        var coord = self.head().coord;
        switch (self.head().facing) {
            .up => coord.y -= 1,
            .down => coord.y += 1,
            .left => coord.x -= 1,
            .right => coord.x += 1,
        }
        self.parts.insert(0, .{ .facing = self.head().facing, .coord = coord }) catch unreachable;
        self._tail = self.parts.pop();
    }

    pub fn append(self: *Snake, cell: Cell) !void {
        try self.parts.append(self._tail.?);
        try self.cells.append(cell);
    }

    pub fn draw(self: *Snake, grid: *Grid) void {
        for (self.parts.items, 0..) |*part, i| {
            grid.setCell(self.cells.items[i], part.coord);
        }
    }

    pub fn isColliding(self: *Snake, grid: *Grid) bool {
        if (self.x() < 0 or self.x() >= @as(f32, @floatFromInt(grid.getCols())) or
            self.y() < 0 or self.y() >= @as(f32, @floatFromInt(grid.getRows())))
        {
            return true;
        }
        for (self.parts.items[1..]) |*part| {
            if (self.head().coord.equals(part.coord) == 1) return true;
        }
        return false;
    }

    pub fn head(self: *Snake) *Part {
        return &self.parts.items[0];
    }

    pub fn length(self: *Snake) usize {
        return self.cells.items.len;
    }

    pub fn x(self: *Snake) f32 {
        return self.head().coord.x;
    }

    pub fn y(self: *Snake) f32 {
        return self.head().coord.y;
    }
};
