const rl = @import("raylib");
const util = @import("util");

const Color = rl.Color;
const Snake = @import("snake.zig").Snake;
const Grid = @import("grid.zig").Grid;
const Cell = @import("grid.zig").Cell;
const CharGroup = @import("char.zig").CharGroup;
const newChars = @import("char.zig").newChars;

const colors = [_]Color{
    Color.orange,
    Color.yellow,
    Color.green,
    Color.blue,
    Color.purple,
    Color.red,
};

pub const State = struct {
    snake: *Snake,
    grid: *Grid,
    char_group: *CharGroup,

    target_length: usize = 5,
    current_length: usize = 0,
    color_idx: usize = 0,

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

        for (self.char_group.chars.items, 0..) |*char, i| {
            if (self.snake.head().coord.equals(char.coord) == 0) {
                continue;
            }
            try self.snake.append(self.char_group.pop(i).cell);
            self.current_length += 1;
            if (self.current_length == self.target_length) {
                // self.score();
                self.current_length = 0;
                self.color_idx += 1;
                self.color_idx %= colors.len;
                try newChars(
                    &self.char_group.chars,
                    util.alphabet,
                    colors[self.color_idx],
                    self.grid,
                );
            }
            break;
        }
        self.char_group.draw(self.grid);
    }
};
