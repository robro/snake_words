const util = @import("util");

pub const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn eql(self: Vec2, coord: Vec2) bool {
        return self.y == coord.y and self.x == coord.x;
    }

    pub fn add(self: Vec2, coord: Vec2) Vec2 {
        return .{ .x = self.x + coord.x, .y = self.y + coord.y };
    }

    pub fn zero() Vec2 {
        return .{ .x = 0, .y = 0 };
    }
};

pub const Range2 = struct {
    start: Vec2,
    end: Vec2,

    pub fn init(start_x: i32, start_y: i32, end_x: i32, end_y: i32) Range2 {
        util.assert(start_x < end_x and start_y < end_y, "invalid range!", .{});
        return .{
            .start = .{ .x = start_x, .y = start_y },
            .end = .{ .x = end_x, .y = end_y },
        };
    }

    pub fn contains(self: Range2, coord: Vec2) bool {
        if (coord.x < self.start.x or coord.y < self.start.y) {
            return false;
        }
        if (coord.x >= self.end.x or coord.y >= self.end.y) {
            return false;
        }
        return true;
    }

    pub fn height(self: Range2) u32 {
        return @intCast(self.end.y - self.start.y);
    }

    pub fn width(self: Range2) u32 {
        return @intCast(self.end.x - self.start.x);
    }
};
