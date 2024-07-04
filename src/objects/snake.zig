const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;
const InputQueue = engine.input.InputQueue;

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

    facing: ?Facing = null,
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

    pub fn update(self: *Snake, input_queue: *InputQueue) void {
        const time = rl.getTime();
        if (time < self.last_tick + self.tick) {
            return;
        }
        self.last_tick = time;

        if (self.facing == null) self.facing = self.head().facing;
        switch (input_queue.pop()) {
            .key_up => self.facing = if (self.head().facing != .down) .up else self.facing,
            .key_down => self.facing = if (self.head().facing != .up) .down else self.facing,
            .key_left => self.facing = if (self.head().facing != .right) .left else self.facing,
            .key_right => self.facing = if (self.head().facing != .left) .right else self.facing,
            else => {},
        }
        var coord = self.head().coord;
        switch (self.facing.?) {
            .up => coord.y -= 1,
            .down => coord.y += 1,
            .left => coord.x -= 1,
            .right => coord.x += 1,
        }
        self.parts.insert(0, .{ .facing = self.facing.?, .coord = coord }) catch unreachable;
        self.tail = self.parts.pop();
    }

    pub fn append(self: *Snake, cell: Cell) !void {
        try self.parts.append(self.tail.?);
        try self.cells.append(cell);
    }

    pub fn draw(self: *Snake, grid: *Grid) void {
        for (self.parts.items, 0..) |*part, i| {
            grid.setCell(self.cells.items[i], part.coord);
        }
    }

    pub fn colliding(self: *Snake, grid: *Grid) bool {
        if (self.x() < 0 or self.x() >= @as(f32, @floatFromInt(grid.getCols())) or
            self.y() < 0 or self.y() >= @as(f32, @floatFromInt(grid.getRows())))
        {
            return true;
        }
        for (self.parts.items[1..]) |*part| {
            if (self.head().coord.equals(part.coord) == 1) {
                return true;
            }
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
