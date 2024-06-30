const rl = @import("raylib");
const util = @import("util");

const Snake = @import("snake.zig").Snake;
const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const CharGroup = @import("char.zig").CharGroup;
const newChars = @import("char.zig").newChars;

pub const State = struct {
    snake: *Snake,
    grid: *Grid,
    char_group: *CharGroup,

    pub fn init(snake: *Snake, grid: *Grid, char_group: *CharGroup) State {
        return State{
            .snake = snake,
            .grid = grid,
            .char_group = char_group,
        };
    }

    pub fn update(self: *State) !void {
        self.grid.fill(Cell.empty_cell);
        self.snake.update();
        self.snake.draw(self.grid);

        for (self.char_group.chars.items) |*char| {
            if (self.snake.head().coord.equals(char.coord) == 1) {
                try self.snake.add(char.cell);
                try newChars(
                    &self.char_group.chars,
                    util.alphabet,
                    rl.Color.purple,
                    self.grid,
                );
                continue;
            }
        }
        self.char_group.draw(self.grid);
    }
};
