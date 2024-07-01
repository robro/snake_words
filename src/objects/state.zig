const std = @import("std");
const rl = @import("raylib");
const util = @import("util");
const scratch = @import("scratch");

const Color = rl.Color;
const Snake = @import("snake.zig").Snake;
const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const FoodGroup = @import("food.zig").FoodGroup;
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

const word_length = 5;

pub const State = struct {
    snake: *Snake,
    grid: *Grid,
    food_group: *FoodGroup,
    target_word: [:0]u8,
    curr_word_idx: usize,
    alloc: Allocator,
    color_idx: usize = 0,

    pub fn init(snake: *Snake, food_group: *FoodGroup, grid: *Grid, alloc: Allocator) !State {
        var state = State{
            .snake = snake,
            .grid = grid,
            .food_group = food_group,
            .target_word = try alloc.allocSentinel(u8, word_length, 0),
            .curr_word_idx = snake.length(),
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
        self.grid.fill(.{ .char = '.', .color = self.bgColor() });
        self.snake.update();
        self.snake.draw(self.grid);

        for (self.food_group.food_list.items, 0..) |*char, i| {
            if (self.snake.head().coord.equals(char.coord) == 0) {
                continue;
            }
            const new_cell = self.food_group.pop(i).cell;
            try self.snake.append(new_cell);

            if (self.currWordLen() == word_length or
                self.target_word[self.currWordLen() - 1] != new_cell.char)
            {
                if (self.currWordLen() < word_length) {
                    for (self.snake.cells.items[self.curr_word_idx..]) |*cell| {
                        cell.color = Color.gray;
                    }
                }
                // TODO: Score the word
                self.curr_word_idx = self.snake.length();
                self.color_idx += 1;
                self.color_idx %= fg_colors.len;
                self.newTarget();
                try self.food_group.spawnFood(
                    self.target_word,
                    self.fgColor(),
                    self.grid,
                );
            }
            break;
        }
        self.food_group.draw(self.grid);
    }

    pub fn currWord(self: *State) [:0]u8 {
        var buf = scratch.scratchBuf(self.currWordLen() + 1);
        var idx: usize = 0;
        for (self.snake.cells.items[self.curr_word_idx..]) |*cell| {
            buf[idx] = cell.char;
            idx += 1;
        }
        buf[idx] = 0;
        return @ptrCast(buf);
    }

    pub fn currWordLen(self: *State) usize {
        return self.snake.length() - self.curr_word_idx;
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
