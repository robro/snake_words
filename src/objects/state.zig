const std = @import("std");
const rl = @import("raylib");
const util = @import("util");
const scratch = @import("scratch");

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

    target_word: [:0]u8,
    partial_start_idx: usize,
    alloc: Allocator,
    timer: Timer,

    color_idx: usize = 0,
    combo: usize = 0,
    multiplier: usize = 1,
    score: usize = 0,
    game_state: GameState = .seeking,

    const target_length = 5;
    const max_multiplier = 8;
    const eval_time: usize = 1_000; // ms
    const gameover_time: usize = 1_000; // ms

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
            .target_word = try alloc.allocSentinel(u8, target_length, 0),
            .partial_start_idx = snake_options.text.len,
            .alloc = alloc,
            .timer = try Timer.start(),
        };
        state.newTarget();
        state.grid.clear(null);
        state.snake.drawToGrid(&state.grid);
        try state.food_group.spawnFood(
            state.target_word,
            state.fgColor(),
            &state.grid,
        );
        return state;
    }

    pub fn deinit(self: *State) void {
        self.alloc.free(self.target_word);
        self.snake.deinit();
        self.food_group.deinit();
        self.grid.deinit();
    }

    pub fn reset(self: *State) !void {
        self.snake = try Snake.init(self.snake_options);
        self.food_group = try FoodGroup.init(self.food_group_options);
        self.grid = try Grid.init(self.grid_options);
        self.partial_start_idx = self.snake.length();
        self.timer.reset();

        self.color_idx += 1;
        self.color_idx %= colors.len;
        self.combo = 0;
        self.multiplier = 1;
        self.score = 0;

        self.newTarget();
        self.grid.clear(null);
        self.snake.drawToGrid(&self.grid);
        try self.food_group.spawnFood(
            self.target_word,
            self.fgColor(),
            &self.grid,
        );
        self.game_state = .seeking;
    }

    pub fn update(self: *State) !void {
        try switch (self.game_state) {
            .seeking => self.updateSeeking(),
            .evaluate => self.updateEvaluate(),
            .gameover => self.updateGameover(),
        };
    }

    fn updateSeeking(self: *State) !void {
        self.updateAndColide();
        for (self.food_group.food.items, 0..) |*food, i| {
            if (food.edible() and self.snake.head().coord.equals(food.coord) == 1) {
                try self.snake.append(self.food_group.pop(i).cell);
                self.combo += 1;
                if (std.mem.eql(u8, self.target_word, self.partialWord())) {
                    self.multiplier = @min(max_multiplier, self.multiplier * 2);
                    self.timer.reset();
                    self.game_state = .evaluate;
                } else if (!std.mem.startsWith(u8, self.target_word, self.partialWord())) {
                    self.combo = 0;
                    self.multiplier = 1;
                    self.timer.reset();
                    self.game_state = .evaluate;
                }
                self.score += 10 * self.multiplier;
                self.timer.reset();
                break;
            }
        }
        self.snake.drawToGrid(&self.grid);
        self.food_group.drawToGrid(&self.grid);
    }

    fn updateEvaluate(self: *State) !void {
        self.updateAndColide();
        self.snake.drawToGrid(&self.grid);
        if (self.timer.read() < eval_time * std.time.ns_per_ms or self.game_state == .gameover) {
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
            &self.grid,
        );
        self.timer.reset();
        self.game_state = .seeking;
    }

    fn updateGameover(self: *State) !void {
        if (self.timer.read() < gameover_time * std.time.ns_per_ms) {
            return;
        }
        if (rl.getKeyPressed() == .key_null) {
            return;
        }
        try self.reset();
    }

    fn updateAndColide(self: *State) void {
        self.snake.update();
        self.grid.clear(self.bgColor());
        if (self.snake.isColliding(&self.grid)) {
            self.timer.reset();
            self.game_state = .gameover;
        }
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

    pub fn multiplierColor(self: *State) Color {
        switch (self.game_state) {
            .evaluate => return if (self.multiplier > 1) self.fgColor() else self.bgColor(),
            else => return self.bgColor(),
        }
    }

    pub fn evaluateColor(self: *State) Color {
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
};
