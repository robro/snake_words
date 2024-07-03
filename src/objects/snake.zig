const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;

pub const Facing = enum {
    up,
    down,
    left,
    right,
};

pub const Part = struct {
    facing: Facing,
    coord: Vector2,
};

pub const SnakeOptions = struct {
    text: [:0]const u8,
    color: rl.Color,
    tick: f64,
    coord: Vector2,
    facing: Facing,
    alloc: Allocator,
};

pub const Snake = struct {
    cells: ArrayList(Cell),
    parts: ArrayList(Part),
    tick: f64,

    tail: ?Part = null,
    last_tick: f64 = 0,

    pub fn init(options: SnakeOptions) !Snake {
        var cells = ArrayList(Cell).init(options.alloc);
        var parts = ArrayList(Part).init(options.alloc);
        try cells.resize(options.text.len);
        try parts.resize(options.text.len);

        for (parts.items, 0..) |*part, i| {
            cells.items[i] = .{ .char = options.text[i], .color = options.color };
            part.facing = options.facing;
            part.coord = options.coord;
            switch (part.facing) {
                .up => part.coord.y += @as(f32, @floatFromInt(i)),
                .down => part.coord.y -= @as(f32, @floatFromInt(i)),
                .left => part.coord.x += @as(f32, @floatFromInt(i)),
                .right => part.coord.x -= @as(f32, @floatFromInt(i)),
            }
        }
        return Snake{ .cells = cells, .parts = parts, .tick = options.tick };
    }

    pub fn deinit(self: *Snake) void {
        self.cells.deinit();
        self.parts.deinit();
    }

    pub fn update(self: *Snake) void {
        var facing = self.head().facing;
        switch (rl.getKeyPressed()) {
            .key_up => facing = if (facing != .down) .up else .down,
            .key_down => facing = if (facing != .up) .down else .up,
            .key_left => facing = if (facing != .right) .left else .right,
            .key_right => facing = if (facing != .left) .right else .left,
            else => {},
        }
        self.head().facing = facing;

        const time = rl.getTime();
        if (time < self.last_tick + self.tick) return;
        self.last_tick = time;

        var coord = self.head().coord;
        switch (self.head().facing) {
            .up => coord.y -= 1,
            .down => coord.y += 1,
            .left => coord.x -= 1,
            .right => coord.x += 1,
        }
        self.parts.insert(0, .{ .facing = self.head().facing, .coord = coord }) catch unreachable;
        self.tail = self.parts.pop();
    }

    pub fn append(self: *Snake, cell: Cell) !void {
        try self.parts.append(self.tail.?);
        try self.cells.append(cell);
    }

    pub fn drawToGrid(self: *Snake, grid: *Grid) void {
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
