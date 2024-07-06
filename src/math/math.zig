const util = @import("util");

pub const Vec2 = struct {
    row: usize,
    col: usize,

    pub fn eql(self: *Vec2, coord: Vec2) bool {
        return self.row == coord.row and self.col == coord.col;
    }
};

pub const Range2 = struct {
    start: Vec2,
    end: Vec2,

    pub fn init(start: Vec2, end: Vec2) Range2 {
        util.assert(start.row < end.row and start.col < end.col, "invalid range!", .{});
        return .{ .start = start, .end = end };
    }

    pub fn contains(self: *Range2, coord: Vec2) bool {
        if (coord.row < self.start.row and coord.col < self.start.col) {
            return false;
        }
        if (coord.row >= self.end.row and coord.col >= self.end.col) {
            return false;
        }
        return true;
    }
};
