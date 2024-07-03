const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const Vector2 = rl.Vector2;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Timer = std.time.Timer;
const Color = rl.Color;

pub const Food = struct {
    cell: Cell,
    coord: Vector2,
    timer: Timer,
    wait_time_ms: u32 = 500,

    pub fn init(cell: Cell, coord: Vector2) !Food {
        return Food{
            .cell = cell,
            .coord = coord,
            .timer = try Timer.start(),
        };
    }

    pub fn edible(self: *Food) bool {
        return self.timer.read() > self.wait_time_ms * std.time.ns_per_ms;
    }

    pub fn displayChar(self: *Food) u8 {
        return if (self.edible()) self.cell.char else std.crypto.random.uintLessThan(u8, 26) + 97;
    }

    pub fn drawToGrid(self: *Food, grid: *Grid) void {
        grid.setCell(.{ .char = self.displayChar(), .color = self.cell.color }, self.coord);
    }
};

pub const FoodGroupOptions = struct {
    alloc: Allocator,
};

pub const FoodGroup = struct {
    food: ArrayList(Food),

    pub fn init(options: FoodGroupOptions) !FoodGroup {
        return FoodGroup{ .food = ArrayList(Food).init(options.alloc) };
    }

    pub fn deinit(self: *FoodGroup) void {
        self.food.deinit();
    }

    pub fn spawnFood(self: *FoodGroup, food_chars: []const u8, color: Color, grid: *Grid) !void {
        try self.food.resize(food_chars.len);
        for (self.food.items, 0..) |*food, i| {
            food.* = try Food.init(
                .{ .char = food_chars[i], .color = color },
                try grid.getFreeCoord(),
            );
            grid.setCell(food.cell, food.coord);
        }
    }

    pub fn drawToGrid(self: *FoodGroup, grid: *Grid) void {
        for (self.food.items) |*food| food.drawToGrid(grid);
    }

    pub fn pop(self: *FoodGroup, idx: usize) Food {
        return self.food.orderedRemove(idx);
    }

    pub fn size(self: *FoodGroup) usize {
        return self.food.items.len;
    }
};
