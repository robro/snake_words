const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const Vector2 = rl.Vector2;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Timer = std.time.Timer;

pub const Food = struct {
    cell: Cell,
    coord: Vector2,
};

pub const FoodGroup = struct {
    food: ArrayList(Food),
    timer: Timer,
    edible: bool = false,
    edible_wait: usize = 500, // ms

    pub fn init(text: []const u8, color: rl.Color, grid: *Grid) !FoodGroup {
        var food_group = FoodGroup{
            .food = ArrayList(Food).init(std.heap.page_allocator),
            .timer = try Timer.start(),
        };
        try food_group.spawnFood(text, color, grid);
        return food_group;
    }

    pub fn deinit(self: *FoodGroup) void {
        self.food.deinit();
    }

    pub fn update(self: *FoodGroup) void {
        if (!self.edible and self.timer.read() > self.edible_wait * std.time.ns_per_ms) {
            self.edible = true;
        }
    }

    pub fn spawnFood(self: *FoodGroup, food_chars: []const u8, color: rl.Color, grid: *Grid) !void {
        try self.food.resize(food_chars.len);
        self.timer.reset();
        self.edible = false;
        for (food_chars, 0..) |char, i| {
            self.food.items[i] = .{
                .cell = .{ .char = char, .color = color },
                .coord = try grid.getFreeCoord(),
            };
            grid.setCell(self.food.items[i].cell, self.food.items[i].coord);
        }
    }

    pub fn pop(self: *FoodGroup, idx: usize) Food {
        return self.food.orderedRemove(idx);
    }

    pub fn draw(self: *FoodGroup, grid: *Grid) void {
        var char: u8 = undefined;
        for (self.food.items) |*food| {
            char = if (!self.edible) std.crypto.random.uintLessThan(u8, 26) + 97 else food.cell.char;
            grid.setCell(.{ .char = char, .color = food.cell.color }, food.coord);
        }
    }
};
