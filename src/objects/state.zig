const std = @import("std");
const rl = @import("raylib");
const util = @import("util");
const scratch = @import("scratch");
const engine = @import("engine");

const Color = rl.Color;
const Snake = @import("snake.zig").Snake;
const SnakeOptions = @import("snake.zig").SnakeOptions;
const Grid = @import("grid.zig").Grid;
const GridOptions = @import("grid.zig").GridOptions;
const Cell = @import("grid.zig").Cell;
const FoodGroup = @import("food.zig").FoodGroup;
const FoodGroupOptions = @import("food.zig").FoodGroupOptions;
const Food = @import("food.zig").Food;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Timer = std.time.Timer;
const InputQueue = engine.input.InputQueue;

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

pub const State = struct {
    grid: Grid,
    snake: Snake,
    food_group: FoodGroup,

    grid_options: GridOptions,
    snake_options: SnakeOptions,
    food_group_options: FoodGroupOptions,

    shuffled_indices: []usize,
    partial_idx: usize,
    alloc: Allocator,
    timer: Timer,
    input_queue: InputQueue,

    word_idx: usize = 0,
    color_idx: usize = 0,
    combo: usize = 0,
    max_combo: usize = 0,
    multiplier: usize = 1,
    score: usize = 0,
    game_state: GameState = .seeking,
    target_word: []const u8 = undefined,
    max_multiplier: usize = 8,
    eval_time: usize = 1_000, // ms
    gameover_time: usize = 1_000, // ms
    gameover_text: []const u8 = "udied",

    pub fn init(
        grid_options: GridOptions,
        snake_options: SnakeOptions,
        food_group_options: FoodGroupOptions,
        alloc: Allocator,
    ) !State {
        var state = State{
            .grid = try Grid.init(grid_options),
            .snake = try Snake.init(snake_options),
            .food_group = try FoodGroup.init(food_group_options),
            .grid_options = grid_options,
            .snake_options = snake_options,
            .food_group_options = food_group_options,
            .shuffled_indices = try alloc.alloc(usize, util.words.len),
            .partial_idx = snake_options.text.len,
            .alloc = alloc,
            .timer = try Timer.start(),
            .input_queue = InputQueue.init(alloc),
        };
        for (state.shuffled_indices, 0..) |*idx, i| idx.* = i;
        std.crypto.random.shuffle(usize, state.shuffled_indices);
        state.newTargetWord();
        state.grid.fill(null);
        state.snake.draw(&state.grid);
        try state.food_group.spawnFood(
            state.target_word,
            state.fgColor(),
            &state.grid,
        );
        return state;
    }

    pub fn deinit(self: *State) void {
        self.alloc.free(self.shuffled_indices);
        self.snake.deinit();
        self.food_group.deinit();
        self.grid.deinit();
        self.input_queue.deinit();
    }

    pub fn reset(self: *State) !void {
        self.snake.deinit();
        self.food_group.deinit();
        self.grid.deinit();

        self.snake = try Snake.init(self.snake_options);
        self.food_group = try FoodGroup.init(self.food_group_options);
        self.grid = try Grid.init(self.grid_options);
        self.partial_idx = self.snake.length();
        self.timer.reset();
        self.input_queue.clear();

        self.word_idx = 0;
        self.color_idx += 1;
        self.color_idx %= colors.len;
        self.combo = 0;
        self.max_combo = 0;
        self.multiplier = 1;
        self.score = 0;

        std.crypto.random.shuffle(usize, self.shuffled_indices);
        self.newTargetWord();
        self.grid.fill(null);
        self.snake.draw(&self.grid);
        try self.food_group.spawnFood(
            self.target_word,
            self.fgColor(),
            &self.grid,
        );
        self.game_state = .seeking;
    }

    pub fn update(self: *State) !void {
        try switch (self.game_state) {
            .seeking => self.seeking(),
            .evaluate => self.evaluate(),
            .gameover => self.gameover(),
        };
    }

    fn seeking(self: *State) !void {
        try self.updateAndCollide();
        for (self.food_group.food.items, 0..) |*food, i| {
            if (!food.edible() or self.snake.head().coord.equals(food.coord) == 0) {
                continue;
            }
            try self.snake.append(self.food_group.pop(i).cell);
            self.combo += 1;
            if (std.mem.eql(u8, self.target_word, self.partialWord())) {
                self.multiplier = @min(self.max_multiplier, self.multiplier * 2);
                self.score += 10 * self.multiplier;
                self.game_state = .evaluate;
            } else if (!std.mem.startsWith(u8, self.target_word, self.partialWord())) {
                self.combo = 0;
                self.multiplier = 1;
                self.game_state = .evaluate;
            } else {
                self.score += 10 * self.multiplier;
            }
            self.max_combo = @max(self.max_combo, self.combo);
            self.timer.reset();
            break;
        }
        self.snake.draw(&self.grid);
        self.food_group.draw(&self.grid);
    }

    fn evaluate(self: *State) !void {
        if (self.food_group.size() != 0) self.food_group.clear();
        try self.updateAndCollide();
        self.snake.draw(&self.grid);
        if (self.timer.read() < self.eval_time * std.time.ns_per_ms or self.game_state == .gameover) {
            return;
        }
        self.setTailColor(if (self.combo > 0) Color.ray_white else Color.gray);
        self.partial_idx = self.snake.length();
        self.color_idx += 1;
        self.color_idx %= colors.len;
        self.newTargetWord();
        try self.food_group.spawnFood(
            self.target_word,
            self.fgColor(),
            &self.grid,
        );
        self.timer.reset();
        self.game_state = .seeking;
    }

    fn gameover(self: *State) !void {
        self.grid.fill(null);
        self.combo = self.max_combo;
        for (self.food_group.food.items) |*food| {
            food.cell.char = util.randomChar();
        }
        for (self.snake.cells.items) |*cell| {
            cell.char = util.randomChar();
        }
        self.grid.fill(null);
        self.snake.draw(&self.grid);
        self.food_group.draw(&self.grid);
        if (self.timer.read() < self.gameover_time * std.time.ns_per_ms) {
            return;
        }
        if (rl.getKeyPressed() == .key_null) {
            return;
        }
        try self.reset();
    }

    fn updateAndCollide(self: *State) !void {
        try self.input_queue.add(rl.getKeyPressed());
        self.grid.fill(.{ .char = self.grid.empty_char, .color = self.bgColor() });
        self.snake.update(&self.input_queue);
        if (self.snake.colliding(&self.grid)) {
            self.timer.reset();
            self.game_state = .gameover;
        }
    }

    fn setTailColor(self: *State, color: Color) void {
        for (self.snake.cells.items[self.partial_idx..]) |*cell| {
            cell.color = color;
        }
    }

    pub fn partialLength(self: *State) usize {
        return self.snake.length() - self.partial_idx;
    }

    pub fn partialWord(self: *State) []const u8 {
        var buf = scratch.scratchBuf(self.partialLength());
        for (self.snake.cells.items[self.partial_idx..], 0..) |*cell, i| {
            buf[i] = cell.char;
        }
        return buf;
    }

    pub fn newTargetWord(self: *State) void {
        self.target_word = util.words[self.shuffled_indices[self.word_idx]];
        self.word_idx += 1;
        self.word_idx %= self.shuffled_indices.len;
    }

    pub fn targetDisplay(self: *State) []const u8 {
        const buf = scratch.scratchBuf(self.food_group.size());
        for (self.food_group.food.items, 0..) |*food, i| {
            buf[i] = food.displayChar();
        }
        return buf;
    }

    pub fn fgColor(self: *State) Color {
        return colors[self.color_idx][0];
    }

    pub fn bgColor(self: *State) Color {
        return colors[self.color_idx][1];
    }

    pub fn targetColor(self: *State) Color {
        switch (self.game_state) {
            .seeking => return self.bgColor(),
            else => return Color.blank,
        }
    }

    pub fn partialColor(self: *State) Color {
        switch (self.game_state) {
            .seeking => return self.fgColor(),
            .evaluate => {
                if (self.flashing()) {
                    return if (self.combo > 0) Color.ray_white else Color.black;
                } else {
                    return Color.blank;
                }
            },
            else => return Color.blank,
        }
    }

    pub fn gameoverColor(self: *State) Color {
        switch (self.game_state) {
            .gameover => return if (self.blinking()) Color.black else Color.blank,
            else => return Color.blank,
        }
    }

    pub fn cursorColor(self: *State) Color {
        switch (self.game_state) {
            .seeking => return if (self.blinking()) self.fgColor() else Color.black,
            else => return Color.blank,
        }
    }

    pub fn multiplierColor(self: *State) Color {
        switch (self.game_state) {
            .evaluate => return if (self.multiplier > 1) self.fgColor() else self.bgColor(),
            else => return self.bgColor(),
        }
    }

    pub fn evaluateColor(self: *State) Color {
        switch (self.game_state) {
            .evaluate => return if (self.combo == 0) self.bgColor() else Color.blank,
            .gameover => return self.bgColor(),
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
};
