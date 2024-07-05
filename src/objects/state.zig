const std = @import("std");
const rl = @import("raylib");
const util = @import("util");
const scratch = @import("scratch");
const engine = @import("engine");

const TitleSnake = @import("title.zig").TitleSnake;
const TSOptions = @import("title.zig").TSOptions;
const Snake = @import("snake.zig").Snake;
const SnakeOptions = @import("snake.zig").SnakeOptions;
const Grid = @import("grid.zig").Grid;
const GridOptions = @import("grid.zig").GridOptions;
const Cell = @import("grid.zig").Cell;
const FoodGroup = @import("food.zig").FoodGroup;
const FoodGroupOptions = @import("food.zig").FoodGroupOptions;
const Food = @import("food.zig").Food;
const SplashGroup = @import("particle.zig").SplashGroup;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Timer = std.time.Timer;
const InputQueue = engine.input.InputQueue;
const Vector2 = rl.Vector2;
const Color = rl.Color;

const GameState = enum {
    title,
    starting,
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
    title_snake: TitleSnake,
    grid: Grid,
    snake: Snake,
    food_group: FoodGroup,
    splash_group: SplashGroup,
    ts_options: TSOptions,
    grid_options: GridOptions,
    snake_options: SnakeOptions,
    food_group_options: FoodGroupOptions,
    word_indices: []usize,
    partial_idx: usize,
    alloc: Allocator,
    timer: Timer,
    input_queue: InputQueue,
    color_idx: usize,

    word_idx: usize = 0,
    combo: usize = 0,
    max_combo: usize = 0,
    multiplier: f64 = 1,
    max_multiplier: f64 = 8,
    score: f64 = 0,
    prev_score: f64 = 0,
    score_time: f64 = 0,
    tally_rate: f64 = 100, // points per second
    game_state: GameState = .title,
    title_wait: usize = 500, // ms
    start_wait: usize = 750, // ms
    eval_time: usize = 1000, // ms
    gameover_wait: usize = 500, // ms
    gameover_text: []const u8 = "udied",
    title_text: []const u8 = "start",
    target_word: []const u8 = undefined,

    pub fn init(
        ts_options: TSOptions,
        grid_options: GridOptions,
        snake_options: SnakeOptions,
        food_group_options: FoodGroupOptions,
        alloc: Allocator,
    ) !State {
        var state = State{
            .title_snake = try TitleSnake.init(ts_options),
            .grid = try Grid.init(grid_options),
            .snake = try Snake.init(snake_options),
            .food_group = FoodGroup.init(food_group_options),
            .splash_group = SplashGroup.init(alloc),
            .ts_options = ts_options,
            .grid_options = grid_options,
            .snake_options = snake_options,
            .food_group_options = food_group_options,
            .word_indices = try alloc.alloc(usize, util.words.len),
            .partial_idx = snake_options.text.len,
            .alloc = alloc,
            .timer = try Timer.start(),
            .input_queue = InputQueue.init(alloc),
            .color_idx = std.crypto.random.uintLessThan(usize, colors.len),
        };
        for (state.word_indices, 0..) |*idx, i| idx.* = i;
        std.crypto.random.shuffle(usize, state.word_indices);
        state.target_word = state.nextTarget();
        return state;
    }

    pub fn deinit(self: *State) void {
        self.title_snake.deinit();
        self.grid.deinit();
        self.snake.deinit();
        self.food_group.deinit();
        self.splash_group.deinit();
        self.input_queue.deinit();
        self.alloc.free(self.word_indices);
    }

    pub fn reset(self: *State) !void {
        self.deinit();
        self.* = try State.init(
            self.ts_options,
            self.grid_options,
            self.snake_options,
            self.food_group_options,
            self.alloc,
        );
    }

    pub fn update(self: *State) !void {
        try switch (self.game_state) {
            .title => self.title(),
            .starting => self.starting(),
            .seeking => self.seeking(),
            .evaluate => self.evaluate(),
            .gameover => self.gameover(),
        };
    }

    fn title(self: *State) !void {
        self.grid.fill(null);
        try self.title_snake.update();
        self.title_snake.draw(&self.grid);
        if (self.timer.read() < self.title_wait * std.time.ns_per_ms) {
            return;
        }
        if (rl.getKeyPressed() == .key_null) {
            return;
        }
        self.timer.reset();
        self.grid.fill(null);
        self.game_state = .starting;
    }

    fn starting(self: *State) !void {
        if (self.timer.read() < self.start_wait * std.time.ns_per_ms) {
            return;
        }
        try self.spawnFood(self.target_word, self.fgColor());
        self.game_state = .seeking;
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
                self.scoring();
                try self.splash_group.spawnSplash(
                    Color.ray_white,
                    self.snake.head().coord,
                    24,
                    500,
                    0.04,
                );
                self.game_state = .evaluate;
            } else if (!std.mem.startsWith(u8, self.target_word, self.partialWord())) {
                self.combo = 0;
                self.multiplier = 1;
                self.game_state = .evaluate;
            } else {
                self.scoring();
                try self.splash_group.spawnSplash(
                    self.fgColor(),
                    self.snake.head().coord,
                    5,
                    350,
                    0.05,
                );
            }
            self.max_combo = @max(self.max_combo, self.combo);
            self.timer.reset();
            break;
        }
        self.grid.fill(.{ .char = self.grid.empty_char, .color = self.bgColor() });
        self.splash_group.draw(&self.grid);
        self.snake.draw(&self.grid);
        self.food_group.draw(&self.grid);
    }

    fn evaluate(self: *State) !void {
        if (self.food_group.size() != 0) self.food_group.clear();
        try self.updateAndCollide();
        self.grid.fill(.{ .char = self.grid.empty_char, .color = self.bgColor() });
        self.splash_group.draw(&self.grid);
        self.snake.draw(&self.grid);
        if (self.timer.read() < self.eval_time * std.time.ns_per_ms or self.game_state == .gameover) {
            return;
        }
        self.setTailColor(if (self.combo > 0) Color.ray_white else Color.gray);
        self.partial_idx = self.snake.length();
        self.color_idx += 1;
        self.color_idx %= colors.len;
        self.target_word = self.nextTarget();
        try self.spawnFood(self.target_word, self.fgColor());
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
        if (self.timer.read() < self.gameover_wait * std.time.ns_per_ms) {
            return;
        }
        if (rl.getKeyPressed() == .key_null) {
            return;
        }
        try self.reset();
        // try self.spawnFood(self.target_word, self.fgColor());
        // self.game_state = .seeking;
        self.game_state = .title;
    }

    fn updateAndCollide(self: *State) !void {
        try self.input_queue.add(rl.getKeyPressed());
        self.snake.update(&self.input_queue);
        try self.splash_group.update();
        if (self.snake.colliding(&self.grid)) {
            self.timer.reset();
            self.game_state = .gameover;
        }
    }

    fn scoring(self: *State) void {
        self.prev_score = self.score;
        self.score += 10 * self.multiplier;
        self.score_time = rl.getTime();
    }

    pub fn spawnFood(self: *State, chars: []const u8, color: Color) !void {
        for (chars) |char| {
            const cell: Cell = .{ .char = char, .color = color };
            const coord = self.getFreeCoord();
            if (coord != null) {
                try self.food_group.add(try Food.init(cell, coord.?));
            }
        }
    }

    pub fn getFreeCoord(self: *State) ?Vector2 {
        var occupied = ArrayList(Vector2).init(self.alloc);
        defer occupied.deinit();

        for (self.snake.parts.items) |*part| {
            occupied.append(part.coord) catch continue;
        }
        for (self.food_group.food.items) |*food| {
            occupied.append(food.coord) catch continue;
        }
        var free = ArrayList(Vector2).init(self.alloc);
        defer free.deinit();

        for (0..self.grid.getRows()) |y| {
            for (0..self.grid.getCols()) |x| {
                var occ_idx: ?usize = null;
                for (occupied.items, 0..) |*coord, i| {
                    if (coord.x == @as(f32, @floatFromInt(x)) and coord.y == @as(f32, @floatFromInt(y))) {
                        occ_idx = i;
                        break;
                    }
                }
                if (occ_idx == null) {
                    free.append(.{
                        .x = @as(f32, @floatFromInt(x)),
                        .y = @as(f32, @floatFromInt(y)),
                    }) catch continue;
                } else {
                    _ = occupied.swapRemove(occ_idx.?);
                }
            }
        }
        if (free.items.len > 0) {
            return free.items[std.crypto.random.uintLessThan(usize, free.items.len)];
        }
        return null;
    }

    pub fn scoreDisplay(self: *State) f64 {
        if (self.game_state == .gameover or self.score == self.prev_score) {
            return self.score;
        }
        return @floor(std.math.lerp(
            self.prev_score,
            self.score,
            @min(1, (rl.getTime() - self.score_time) / (self.score - self.prev_score) * self.tally_rate),
        ));
    }

    fn setTailColor(self: *State, color: Color) void {
        for (self.snake.cells.items[self.partial_idx..]) |*cell| {
            cell.color = color;
        }
    }

    pub fn partialLength(self: *State) usize {
        switch (self.game_state) {
            .title => return self.title_text.len - 1,
            else => return self.snake.length() - self.partial_idx,
        }
    }

    pub fn partialWord(self: *State) []const u8 {
        var buf = scratch.scratchBuf(self.partialLength());
        for (self.snake.cells.items[self.partial_idx..], 0..) |*cell, i| {
            buf[i] = cell.char;
        }
        return buf;
    }

    pub fn nextTarget(self: *State) []const u8 {
        defer {
            self.word_idx += 1;
            self.word_idx %= self.word_indices.len;
        }
        return util.words[self.word_indices[self.word_idx]];
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

    pub fn titleColor(self: *State) Color {
        switch (self.game_state) {
            .title => return Color.light_gray,
            .starting => return if (self.flashing()) Color.ray_white else Color.blank,
            else => return Color.blank,
        }
    }

    pub fn pointsColor(self: *State) Color {
        switch (self.game_state) {
            .seeking => return self.bgColor(),
            .evaluate => return self.bgColor(),
            .gameover => return self.bgColor(),
            else => return Color.blank,
        }
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
            .title => return if (self.blinking()) Color.light_gray else Color.black,
            .seeking => return if (self.blinking()) self.fgColor() else Color.black,
            else => return Color.blank,
        }
    }

    pub fn multiplierColor(self: *State) Color {
        switch (self.game_state) {
            .seeking => return self.bgColor(),
            .evaluate => return if (self.multiplier > 1) self.fgColor() else self.bgColor(),
            .gameover => return self.bgColor(),
            else => return Color.blank,
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
        if (self.timer.read() / 75_000_000 % 2 == 0) {
            return true;
        }
        return false;
    }

    fn blinking(self: *State) bool {
        if (self.timer.read() / 400_000_000 % 2 == 0) {
            return true;
        }
        return false;
    }
};
