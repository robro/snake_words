const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;

pub const Cell = struct {
    char: u8,
    color: rl.Color,

    pub const empty_cell = Cell{ .char = '.', .color = rl.Color.dark_blue };
};

pub const Grid = struct {
    cells: [][]Cell,
    alloc: Allocator,

    pub fn getRows(self: *Grid) usize {
        return self.cells.len;
    }

    pub fn getCols(self: *Grid) usize {
        return self.cells[0].len;
    }

    pub fn init(rows: usize, cols: usize, alloc: Allocator) !Grid {
        const cells = try alloc.alloc([]Cell, rows);
        for (0..rows) |row| {
            cells[row] = try alloc.alloc(Cell, cols);
        }
        return Grid{ .cells = cells, .alloc = alloc };
    }

    pub fn deinit(self: *Grid) void {
        for (self.cells) |row| self.alloc.free(row);
        self.alloc.free(self.cells);
    }

    pub fn setCell(self: *Grid, coord: Vector2, cell: Cell) void {
        if (coord.x < 0 or coord.y < 0) return;
        if (coord.x >= @as(f32, @floatFromInt(self.getCols())) or
            coord.y >= @as(f32, @floatFromInt(self.getRows()))) return;
        self.cells[@intFromFloat(coord.y)][@intFromFloat(coord.x)] = cell;
    }

    pub fn getFreeCoord(self: *Grid, free_char: u8, alloc: *const Allocator) !Vector2 {
        const coords = try alloc.alloc(Vector2, self.getRows() * self.getCols());
        defer alloc.free(coords);

        var i: usize = 0;
        for (self.cells, 0..) |*row, y| {
            for (row.*, 0..) |*cell, x| {
                if (cell.char != free_char) continue;
                coords[i] = Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
                i += 1;
            }
        }
        if (i == 0) return error.NoFreeCoords;
        return coords[std.crypto.random.uintLessThan(usize, i)];
    }

    pub fn fill(self: *Grid, cell: Cell) void {
        for (self.cells) |row| {
            for (row) |*c| c.* = cell;
        }
    }
};
