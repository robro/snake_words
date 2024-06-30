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

    pub fn rows(self: *Grid) usize {
        return self.cells.len;
    }

    pub fn cols(self: *Grid) usize {
        return self.cells[0].len;
    }

    pub fn setCell(self: *Grid, coord: Vector2, cell: Cell) void {
        if (coord.x < 0 or coord.y < 0) return;
        if (coord.x >= @as(f32, @floatFromInt(self.cols())) or
            coord.y >= @as(f32, @floatFromInt(self.rows()))) return;
        self.cells[@intFromFloat(coord.y)][@intFromFloat(coord.x)] = cell;
    }

    pub fn getFreeCoord(self: *Grid, free_char: u8, alloc: *Allocator) !Vector2 {
        const coords = try alloc.alloc(Vector2, self.rows() * self.cols());
        defer alloc.free(coords);

        var i: usize = 0;
        for (self.cells, 0..) |*row, y| {
            for (row.*, 0..) |*cell, x| {
                if (cell.char != free_char) continue;
                coords[i] = Vector2{ .x = x, .y = y };
                i += 1;
            }
        }
        return coords[std.crypto.random.uintLessThan(usize, i)];
    }

    pub fn fill(self: *Grid, cell: Cell) void {
        for (self.cells) |row| {
            for (row) |*c| c.* = cell;
        }
    }

    pub fn free(self: *Grid, alloc: *Allocator) void {
        for (self.cells) |row| alloc.free(row);
        alloc.free(self.cells);
    }
};

pub fn createGrid(rows: usize, cols: usize, alloc: *Allocator) !Grid {
    const cells = try alloc.alloc([]Cell, rows);
    for (0..rows) |row| {
        cells[row] = try alloc.alloc(Cell, cols);
    }
    return Grid{ .cells = cells };
}
