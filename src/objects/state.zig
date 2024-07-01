const std = @import("std");
const rl = @import("raylib");
const util = @import("util");
const scratch = @import("scratch");

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
    Color.green,
    Color.purple,
    Color.yellow,
    Color.blue,
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
    char_group: *CharGroup,
    target_word: [:0]u8,
    curr_word_idx: usize,
    alloc: Allocator,
    color_idx: usize = 0,

    pub fn init(snake: *Snake, grid: *Grid, char_group: *CharGroup, alloc: Allocator) !State {
        const target_word = try alloc.allocSentinel(u8, word_length, 0);
        newTarget(target_word);
        try newChars(
            &char_group.chars,
            target_word,
            fg_colors[0],
            grid,
        );
        return State{
            .snake = snake,
            .grid = grid,
            .char_group = char_group,
            .target_word = target_word,
            .curr_word_idx = snake.length(),
            .alloc = alloc,
        };
    }

    pub fn update(self: *State) !void {
        self.grid.fill(.{ .char = '.', .color = self.bgColor() });
        self.snake.update();
        self.snake.draw(self.grid);

        for (self.char_group.chars.items, 0..) |*char, i| {
            if (self.snake.head().coord.equals(char.coord) == 0) {
                continue;
            }
            const new_cell = self.char_group.pop(i).cell;
            try self.snake.append(new_cell);

            if (self.currWordLen() == word_length) {
                // TODO: Do word scoring here
                // clearWord(self.curr_word);
                self.curr_word_idx = self.snake.length();
                self.color_idx += 1;
                self.color_idx %= fg_colors.len;
                newTarget(self.target_word);
                try newChars(
                    &self.char_group.chars,
                    self.target_word,
                    self.fgColor(),
                    self.grid,
                );
            }
            break;
        }
        self.char_group.draw(self.grid);
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

fn clearWord(word: [:0]u8) void {
    for (word) |*char| char.* = '_';
}

pub fn newTarget(buf: []u8) void {
    std.mem.copyForwards(
        u8,
        buf,
        util.words[std.crypto.random.uintLessThan(usize, util.words.len)],
    );
}
