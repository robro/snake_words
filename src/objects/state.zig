const std = @import("std");
const rl = @import("raylib");
const util = @import("util");

const Color = rl.Color;
const Snake = @import("snake.zig").Snake;
const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const CharGroup = @import("char.zig").CharGroup;
const newChars = @import("char.zig").newChars;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const fg_colors = [_]Color{
    Color.orange,
    Color.yellow,
    Color.green,
    Color.blue,
    Color.purple,
    Color.red,
};

const bg_colors = [_]Color{
    Color.dark_brown,
    Color.dark_brown,
    Color.dark_green,
    Color.dark_blue,
    Color.dark_purple,
    Color.init(100, 20, 30, 255),
};

const word_length = 5;

pub const State = struct {
    snake: *Snake,
    grid: *Grid,
    char_group: *CharGroup,
    alloc: Allocator,
    curr_word: [:0]u8,
    curr_word_idx: usize,
    color_idx: usize = 0,

    pub fn init(snake: *Snake, grid: *Grid, char_group: *CharGroup, alloc: Allocator) !State {
        const curr_word = try alloc.allocSentinel(u8, word_length, 0);
        clearWord(curr_word);
        return State{
            .snake = snake,
            .grid = grid,
            .char_group = char_group,
            .curr_word = curr_word,
            .curr_word_idx = snake.length(),
            .alloc = alloc,
        };
    }

    pub fn update(self: *State) !void {
        self.grid.fill(.{ .char = '.', .color = bg_colors[self.color_idx] });
        self.snake.update();
        self.snake.draw(self.grid);

        for (self.char_group.chars.items, 0..) |*char, i| {
            if (self.snake.head().coord.equals(char.coord) == 0) {
                continue;
            }
            const new_cell = self.char_group.pop(i).cell;
            try self.snake.append(new_cell);

            const curr_length = self.snake.length() - self.curr_word_idx;
            self.curr_word[curr_length - 1] = new_cell.char;

            if (curr_length == word_length) {
                // TODO: Do word scoring here
                clearWord(self.curr_word);
                self.curr_word_idx = self.snake.length();
                self.color_idx += 1;
                self.color_idx %= fg_colors.len;
                try newChars(
                    &self.char_group.chars,
                    util.alphabet,
                    fg_colors[self.color_idx],
                    self.grid,
                );
            }
            break;
        }
        self.char_group.draw(self.grid);
    }

    pub fn color(self: *State) Color {
        return fg_colors[self.color_idx];
    }

    pub fn deinit(self: *State) void {
        self.alloc.free(self.curr_word);
    }
};

fn clearWord(word: [:0]u8) void {
    for (word) |*char| char.* = '_';
}
