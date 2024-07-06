const std = @import("std");
const rl = @import("raylib");
const math = @import("math");

const Cell = @import("grid.zig").Cell;
const Grid = @import("grid.zig").Grid;
const Facing = @import("snake.zig").Facing;
const Vec2 = math.Vec2;
const Color = rl.Color;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const assert = @import("util").assert;
const expect = std.testing.expect;

pub const TitleSnakeOptions = struct {
    color: Color,
    cols: usize,
    rows: usize,
    tick: f64,
    alloc: Allocator,
};

pub const TitleSnake = struct {
    color: Color,
    cells: ArrayList(Cell),
    coords: ArrayList(Vec2),
    tick: f64,
    last_tick: ?f64 = null,

    pub fn init(options: TitleSnakeOptions) !TitleSnake {
        assert(
            options.cols >= 2 and options.rows >= 2 and options.rows % 2 == 0,
            "invalid dimensions!",
            .{},
        );

        var ts = TitleSnake{
            .color = options.color,
            .cells = ArrayList(Cell).init(options.alloc),
            .coords = ArrayList(Vec2).init(options.alloc),
            .tick = options.tick,
        };
        var reversed = false;
        var facing = Facing.right;
        var coord = Vec2{ .x = 1, .y = 0 };
        var turn_wait: i32 = 0;
        var text_idx: usize = 0;
        const text = "snake_words";

        while (true) : (text_idx += 1) {
            if (facing == .up or facing == .down) {
                turn_wait = turn_wait - 1;
            }
            if (text_idx < text.len) {
                try ts.cells.append(.{ .char = text[text_idx], .color = ts.color });
            }
            try ts.coords.append(coord);

            if (!reversed) {
                if (coord.x == options.cols - 1) {
                    if (facing == .right) {
                        facing = .down;
                        turn_wait = 3;
                    } else if (facing == .down) {
                        if (coord.y == options.rows - 1) {
                            facing = .left;
                            reversed = true;
                        } else if (turn_wait == 0 and options.cols > 2) {
                            facing = .left;
                        }
                    }
                } else if (coord.x == 0) {
                    if (facing == .left) {
                        facing = .down;
                    } else if (facing == .down) {
                        facing = .right;
                    }
                }
            } else {
                if (coord.x == 0) {
                    if (facing == .left) {
                        facing = .up;
                        if (turn_wait != 0) {
                            turn_wait = 3;
                        } else {
                            turn_wait = 1;
                        }
                    } else if (facing == .up) {
                        if (coord.y == 0) {
                            break;
                        } else if (turn_wait == 0 and options.cols > 1) {
                            facing = .right;
                        }
                    }
                } else if (coord.x == options.cols - 1) {
                    if (facing == .right) {
                        facing = .up;
                    } else if (facing == .up) {
                        facing = .left;
                    }
                }
            }
            switch (facing) {
                .up => coord.y -= 1,
                .down => coord.y += 1,
                .left => coord.x -= 1,
                .right => coord.x += 1,
            }
        }
        return ts;
    }

    pub fn deinit(self: *TitleSnake) void {
        self.cells.deinit();
        self.coords.deinit();
    }

    pub fn update(self: *TitleSnake) !void {
        const time = rl.getTime();
        if (self.last_tick != null and time < self.last_tick.? + self.tick) {
            return;
        }
        self.last_tick = time;
        try self.coords.append(self.coords.orderedRemove(0));
    }

    pub fn draw(self: *TitleSnake, grid: *Grid) void {
        for (self.cells.items, 0..) |*cell, i| {
            grid.setCell(cell.*, self.coords.items[i]);
        }
    }
};

test "title snake" {
    const rows = 5;
    const cols = 3;
    const ts = try TitleSnake.init(rows, cols, std.testing.allocator);
    defer ts.deinit();

    try expect(ts.coords.items.len == rows * cols);
    try expect(std.meta.eql(
        ts.coords.items[ts.coords.items.len - 1].coord,
        Vec2{ .x = 0, .y = 0 },
    ));
}
