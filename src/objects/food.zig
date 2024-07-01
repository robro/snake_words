const std = @import("std");
const rl = @import("raylib");
const engine = @import("engine");

const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const Vector2 = rl.Vector2;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub const Food = struct {
    cell: Cell,
    coord: Vector2,
};

pub const FoodGroup = struct {
    food_list: ArrayList(Food),

    pub fn init(text: [:0]const u8, color: rl.Color, grid: *Grid) !FoodGroup {
        var food_group = FoodGroup{
            .food_list = ArrayList(Food).init(std.heap.page_allocator),
        };
        try food_group.spawnFood(text, color, grid);
        return food_group;
    }

    pub fn deinit(self: *FoodGroup) void {
        self.food_list.deinit();
    }

    pub fn spawnFood(self: *FoodGroup, food_chars: [:0]const u8, color: rl.Color, grid: *Grid) !void {
        try self.food_list.resize(food_chars.len);
        for (food_chars, 0..) |char, i| {
            self.food_list.items[i] = .{
                .cell = .{ .char = char, .color = color },
                .coord = try grid.getFreeCoord('.', &std.heap.page_allocator),
            };
            grid.setCell(self.food_list.items[i].cell, self.food_list.items[i].coord);
        }
    }

    pub fn pop(self: *FoodGroup, idx: usize) Food {
        return self.food_list.orderedRemove(idx);
    }

    pub fn draw(self: *const FoodGroup, grid: *Grid) void {
        for (self.food_list.items) |*char| grid.setCell(char.cell, char.coord);
    }
};
