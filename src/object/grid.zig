const std = @import("std");
const rl = @import("raylib");
const math = @import("math");

const Allocator = std.mem.Allocator;
const Vec2 = math.Vec2;
const Color = rl.Color;

pub const Cell = struct {
    char: u8,
    color: Color,
};

pub const GridOptions = struct {
    rows: usize,
    cols: usize,
    empty_char: u8,
    alloc: Allocator,
};

pub const Grid = struct {
    cells: [][]Cell,
    empty_char: u8,
    alloc: Allocator,

    pub fn init(options: GridOptions) !Grid {
        const cells = try options.alloc.alloc([]Cell, options.rows);
        for (0..options.rows) |row| {
            cells[row] = try options.alloc.alloc(Cell, options.cols);
        }
        var grid = Grid{
            .cells = cells,
            .empty_char = options.empty_char,
            .alloc = options.alloc,
        };
        grid.fill(null);
        return grid;
    }

    pub fn deinit(self: *Grid) void {
        for (self.cells) |row| self.alloc.free(row);
        self.alloc.free(self.cells);
    }

    pub fn setCell(self: *Grid, cell: Cell, coord: Vec2) void {
        if (coord.x < 0 or coord.x >= self.getCols() or
            coord.y < 0 or coord.y >= self.getRows())
        {
            return;
        }
        self.cells[@intCast(coord.y)][@intCast(coord.x)] = cell;
    }

    pub fn fill(self: *Grid, color: ?Color) void {
        for (self.cells) |*row| {
            for (row.*) |*c| {
                c.* = .{
                    .char = self.empty_char,
                    .color = if (color == null) Color.blank else color.?,
                };
            }
        }
    }

    pub fn getRows(self: *Grid) usize {
        return self.cells.len;
    }

    pub fn getCols(self: *Grid) usize {
        return self.cells[0].len;
    }
};
