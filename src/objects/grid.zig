const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;
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
        return Grid{
            .cells = cells,
            .empty_char = options.empty_char,
            .alloc = options.alloc,
        };
    }

    pub fn deinit(self: *Grid) void {
        for (self.cells) |row| self.alloc.free(row);
        self.alloc.free(self.cells);
    }

    pub fn setCell(self: *Grid, cell: Cell, coord: Vector2) void {
        if (coord.x < 0 or coord.y < 0) return;
        if (coord.x >= @as(f32, @floatFromInt(self.getCols())) or
            coord.y >= @as(f32, @floatFromInt(self.getRows()))) return;
        self.cells[@intFromFloat(coord.y)][@intFromFloat(coord.x)] = cell;
    }

    pub fn getFreeCoord(self: *Grid) !Vector2 {
        const coords = try self.alloc.alloc(Vector2, self.getRows() * self.getCols());
        defer self.alloc.free(coords);

        var i: usize = 0;
        for (self.cells, 0..) |*row, y| {
            for (row.*, 0..) |*cell, x| {
                if (cell.char != self.empty_char) continue;
                coords[i] = .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
                i += 1;
            }
        }
        if (i == 0) return error.NoFreeCoords;
        return coords[std.crypto.random.uintLessThan(usize, i)];
    }

    pub fn fill(self: *Grid, cell: ?Cell) void {
        for (self.cells) |*row| {
            for (row.*) |*c| {
                c.* = if (cell == null) .{
                    .char = self.empty_char,
                    .color = Color.blank,
                } else cell.?;
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
