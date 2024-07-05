const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");
const util = @import("util");

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
    wait_time_ms: usize = 500,

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
        return if (self.edible()) self.cell.char else util.randomChar();
    }

    pub fn draw(self: *Food, grid: *Grid) void {
        grid.setCell(.{ .char = self.displayChar(), .color = self.cell.color }, self.coord);
    }
};

pub const FoodGroupOptions = struct {
    alloc: Allocator,
};

pub const FoodGroup = struct {
    food: ArrayList(Food),

    pub fn init(options: FoodGroupOptions) FoodGroup {
        return FoodGroup{ .food = ArrayList(Food).init(options.alloc) };
    }

    pub fn deinit(self: *FoodGroup) void {
        self.food.deinit();
    }

    pub fn add(self: *FoodGroup, food: Food) !void {
        try self.food.append(food);
    }

    pub fn draw(self: *FoodGroup, grid: *Grid) void {
        for (self.food.items) |*food| food.draw(grid);
    }

    pub fn pop(self: *FoodGroup, idx: usize) Food {
        return self.food.orderedRemove(idx);
    }

    pub fn size(self: *FoodGroup) usize {
        return self.food.items.len;
    }

    pub fn clear(self: *FoodGroup) void {
        self.food.clearAndFree();
    }
};
