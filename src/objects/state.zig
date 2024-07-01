const std = @import("std");
const rl = @import("raylib");
const util = @import("util");
const scratch = @import("scratch");

const Color = rl.Color;
const Snake = @import("snake.zig").Snake;
const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const FoodGroup = @import("food.zig").FoodGroup;
const Food = @import("food.zig").Food;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const fg_colors = [_]Color{
    Color.orange,
    Color.green,
    Color.purple,
    Color.yellow,
    Color.sky_blue,
    Color.red,
};

const bg_colors = [_]Color{
    Color.dark_brown,
    Color.dark_green,
    Color.dark_purple,
    Color.dark_brown,
    Color.dark_blue,
    Color.init(100, 20, 30, 255),
};

const target_length = 5;

pub const State = struct {
    snake: *Snake,
    grid: *Grid,
    food_group: *FoodGroup,
    target_word: [:0]u8,
    partial_start_idx: usize,
    alloc: Allocator,
    color_idx: usize = 0,

    pub fn init(snake: *Snake, food_group: *FoodGroup, grid: *Grid, alloc: Allocator) !State {
        var state = State{
            .snake = snake,
            .grid = grid,
            .food_group = food_group,
            .target_word = try alloc.allocSentinel(u8, target_length, 0),
            .partial_start_idx = snake.length(),
            .alloc = alloc,
        };
        state.newTarget();
        try state.food_group.spawnFood(
            state.target_word,
            fg_colors[0],
            grid,
        );
        return state;
    }

    pub fn update(self: *State) !void {
        self.grid.fill(.{ .char = Cell.empty_cell.char, .color = self.bgColor() });
        self.snake.update();
        self.snake.draw(self.grid);
        var new_food: ?Food = null;

        for (self.food_group.food.items, 0..) |*food, i| {
            if (self.snake.head().coord.equals(food.coord) == 1) {
                new_food = self.food_group.pop(i);
                break;
            }
        }
        if (new_food != null) {
            try self.snake.append(new_food.?.cell);
            if (std.mem.eql(u8, self.partialWord(), self.target_word)) {
                try self.finishWord(true);
            } else if (!std.mem.startsWith(u8, self.target_word, self.partialWord())) {
                try self.finishWord(false);
            }
        }
        self.food_group.draw(self.grid);
    }

    pub fn finishWord(self: *State, success: bool) !void {
        const color = if (success) Color.ray_white else Color.dark_gray;
        for (self.snake.cells.items[self.partial_start_idx..]) |*cell| {
            cell.color = color;
        }
        self.partial_start_idx = self.snake.length();
        self.color_idx += 1;
        self.color_idx %= fg_colors.len;
        self.newTarget();
        try self.food_group.spawnFood(
            self.target_word,
            self.fgColor(),
            self.grid,
        );
    }

    pub fn partialWord(self: *State) [:0]u8 {
        var buf = scratch.scratchBuf(self.partialLength() + 1);
        var idx: usize = 0;
        for (self.snake.cells.items[self.partial_start_idx..]) |*cell| {
            buf[idx] = cell.char;
            idx += 1;
        }
        buf[idx] = 0;
        return buf[0..idx :0];
    }

    pub fn partialLength(self: *State) usize {
        return self.snake.length() - self.partial_start_idx;
    }

    pub fn newTarget(self: *State) void {
        std.mem.copyForwards(
            u8,
            self.target_word,
            util.words[std.crypto.random.uintLessThan(usize, util.words.len)],
        );
    }

    pub fn fgColor(self: *State) Color {
        return fg_colors[self.color_idx];
    }

    pub fn bgColor(self: *State) Color {
        return bg_colors[self.color_idx];
    }

    pub fn deinit(self: *State) void {
        self.alloc.free(self.target_word);
    }
};
