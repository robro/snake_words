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
const Timer = std.time.Timer;

const GameState = enum {
    seeking,
    evaluate,
    gameover,
};

const colors = [_][2]Color{
    .{ Color.orange, Color.dark_brown },
    .{ Color.green, Color.dark_green },
    .{ Color.purple, Color.dark_purple },
    .{ Color.yellow, Color.dark_brown },
    .{ Color.sky_blue, Color.dark_blue },
    .{ Color.red, Color.init(100, 20, 30, 255) },
};

const target_length = 5;
const max_multiplier = 8;

pub const State = struct {
    snake: *Snake,
    grid: *Grid,
    food_group: *FoodGroup,
    target_word: [:0]u8,
    partial_start_idx: usize,
    alloc: Allocator,
    timer: Timer,
    color_idx: usize = 0,
    combo: usize = 0,
    multiplier: usize = 1,
    score: usize = 0,
    game_state: GameState = .seeking,
    eval_time: usize = 1_000, // ms

    pub fn init(snake: *Snake, food_group: *FoodGroup, grid: *Grid, alloc: Allocator) !State {
        var state = State{
            .snake = snake,
            .grid = grid,
            .food_group = food_group,
            .target_word = try alloc.allocSentinel(u8, target_length, 0),
            .partial_start_idx = snake.length(),
            .alloc = alloc,
            .timer = try Timer.start(),
        };
        state.newTarget();
        try state.food_group.spawnFood(
            state.target_word,
            colors[0][0],
            grid,
        );
        return state;
    }

    pub fn update(self: *State) !void {
        self.grid.fill(.{ .char = Cell.empty_cell.char, .color = self.bgColor() });
        self.food_group.update();
        self.snake.update();
        self.snake.draw(self.grid);
        try switch (self.game_state) {
            .seeking => self.updateSearch(),
            .evaluate => self.updateEval(),
            .gameover => self.updateGameover(),
        };
    }

    fn updateSearch(self: *State) !void {
        var new_food: ?Food = null;
        for (self.food_group.food.items, 0..) |*food, i| {
            if (!self.food_group.edible) {
                break;
            }
            if (self.snake.head().coord.equals(food.coord) == 1) {
                new_food = self.food_group.pop(i);
                break;
            }
        }
        if (new_food != null) {
            try self.snake.append(new_food.?.cell);
            self.combo += 1;
            if (std.mem.eql(u8, self.partialWord(), self.target_word)) {
                self.multiplier = @min(max_multiplier, self.multiplier * 2);
                self.finishSearch();
            } else if (!std.mem.startsWith(u8, self.target_word, self.partialWord())) {
                self.combo = 0;
                self.multiplier = 1;
                self.finishSearch();
            }
            self.score += 10 * self.multiplier;
            self.timer.reset();
        }
        self.food_group.draw(self.grid);
    }

    fn finishSearch(self: *State) void {
        for (self.target_word) |*char| char.* = 0;
        self.timer.reset();
        self.game_state = .evaluate;
    }

    fn updateEval(self: *State) !void {
        if (self.timer.read() < self.eval_time * std.time.ns_per_ms) {
            return;
        }
        self.setTailColor(if (self.combo > 0) Color.ray_white else Color.gray);
        self.partial_start_idx = self.snake.length();
        self.color_idx += 1;
        self.color_idx %= colors.len;
        self.newTarget();
        try self.food_group.spawnFood(
            self.target_word,
            self.fgColor(),
            self.grid,
        );
        self.timer.reset();
        self.game_state = .seeking;
    }

    fn updateGameover(self: *State) void {
        // TODO: Implement losing and restarting
        _ = self;
    }

    fn setTailColor(self: *State, color: Color) void {
        for (self.snake.cells.items[self.partial_start_idx..]) |*cell| {
            cell.color = color;
        }
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
        return colors[self.color_idx][0];
    }

    pub fn bgColor(self: *State) Color {
        return colors[self.color_idx][1];
    }

    pub fn partialColor(self: *State) Color {
        switch (self.game_state) {
            .evaluate => {
                if (self.flashing()) {
                    return if (self.combo > 0) Color.ray_white else Color.black;
                } else {
                    return Color.blank;
                }
            },
            else => return self.fgColor(),
        }
    }

    pub fn cursorColor(self: *State) Color {
        switch (self.game_state) {
            .seeking => return if (self.blinking()) self.fgColor() else Color.black,
            else => return Color.blank,
        }
    }

    pub fn multiColor(self: *State) Color {
        switch (self.game_state) {
            .evaluate => return if (self.multiplier > 1) self.fgColor() else self.bgColor(),
            else => return self.bgColor(),
        }
    }

    pub fn evalColor(self: *State) Color {
        switch (self.game_state) {
            .evaluate => return if (self.combo == 0) self.bgColor() else Color.blank,
            else => return Color.blank,
        }
    }

    fn flashing(self: *State) bool {
        if (self.timer.read() / 100_000_000 % 2 == 0) return true;
        return false;
    }

    fn blinking(self: *State) bool {
        if (self.timer.read() / 300_000_000 % 2 == 0) return true;
        return false;
    }

    pub fn deinit(self: *State) void {
        self.alloc.free(self.target_word);
    }
};
