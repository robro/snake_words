const std = @import("std");
const rl = @import("raylib");

const Allocator = std.mem.Allocator;
const Vector2 = rl.Vector2;

pub const GridCell = struct {
    char: u8,
    color: rl.Color,
};

pub fn createGrid(rows: usize, cols: usize, alloc: *Allocator) ![][]GridCell {
    const grid = try alloc.alloc([]GridCell, rows);
    for (0..rows) |row| {
        grid[row] = try alloc.alloc(GridCell, cols);
    }
    return grid;
}

pub fn drawToCell(grid: [][]GridCell, coord: Vector2, cell: GridCell) void {
    if (coord.x < 0 or coord.y < 0) return;
    if (coord.x >= @as(f32, @floatFromInt(grid[0].len)) or
        coord.y >= @as(f32, @floatFromInt(grid.len))) return;
    grid[@intFromFloat(coord.y)][@intFromFloat(coord.x)] = cell;
}

pub fn freeGrid(grid: [][]GridCell, alloc: *Allocator) void {
    for (grid) |row| alloc.free(row);
    alloc.free(grid);
}

pub fn fillGrid(grid: [][]GridCell, char: u8, color: rl.Color) void {
    for (grid) |row| {
        for (row) |*item| {
            item.char = char;
            item.color = color;
        }
    }
}
