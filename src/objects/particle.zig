const std = @import("std");
const rl = @import("raylib");
const util = @import("util");
const math = @import("math");

const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const Color = rl.Color;
const Vec2 = math.Vec2;
const Range2 = math.Range2;
const Timer = std.time.Timer;
const Allocator = std.mem.Allocator;
const Grid = @import("grid.zig").Grid;

const Particle = struct {
    src_color: Color,
    coord: Vec2,
    timer: Timer,
    lifetime: u64, // ms

    pub fn init(start_color: Color, coord: Vec2, lifetime: u64) !Particle {
        util.assert(lifetime > 0, "lifetime must be greater than zero!", .{});
        return Particle{
            .src_color = start_color,
            .coord = coord,
            .timer = try Timer.start(),
            .lifetime = lifetime,
        };
    }

    pub fn finished(self: *Particle) bool {
        return self.timer.read() > self.lifetime * std.time.ns_per_ms;
    }

    pub fn color(self: *Particle) Color {
        return lerpColor(self.src_color, self.timer.read(), self.lifetime * std.time.ns_per_ms);
    }
};

pub const Trail = struct {
    particles: ArrayList(Particle),
    color: Color,
    lifetime: u64, // ms
    coord: ?Vec2 = null,
    last_coord: ?Vec2 = null,

    pub fn init(color: Color, lifetime: u64, alloc: Allocator) Trail {
        return Trail{
            .particles = ArrayList(Particle).init(alloc),
            .color = color,
            .lifetime = lifetime,
        };
    }

    pub fn deinit(self: *Trail) void {
        self.particles.deinit();
    }

    pub fn update(self: *Trail) !void {
        if (self.coord == null) {
            return;
        }
        while (self.particles.items.len > 0 and self.particles.items[0].finished()) {
            _ = self.particles.orderedRemove(0);
        }
        if (self.last_coord == null or !self.last_coord.?.eql(self.coord.?)) {
            self.last_coord = self.coord.?;
            try self.particles.append(try Particle.init(self.color, self.last_coord.?, self.lifetime));
        }
    }

    pub fn draw(self: *Trail, grid: *Grid) void {
        return drawParticles(&self.particles, grid);
    }
};

pub const SplashOptions = struct {
    max_size: usize,
    lifetime: u64,
    tick: f64,
};

pub const Splash = struct {
    particles: ArrayList(Particle),
    queue: ArrayList(NumberedVec2),
    visited: ArrayList(Vec2),
    color: Color,
    coord: Vec2,
    max_size: usize,
    lifetime: u64, // ms
    tick: f64, // seconds
    last_tick: f64 = 0,
    size: usize = 1,
    finished_count: usize = 0,

    const NumberedVec2 = struct {
        num: usize,
        coord: Vec2,
    };

    const offsets = [_]Vec2{
        .{ .x = 0, .y = -1 },
        .{ .x = 0, .y = 1 },
        .{ .x = -1, .y = 0 },
        .{ .x = 1, .y = 0 },
    };

    pub fn init(color: Color, coord: Vec2, max_size: usize, lifetime: u64, tick: f64, alloc: Allocator) !Splash {
        util.assert(max_size > 0, "max_size must be greater than zero!", .{});
        util.assert(lifetime > 0, "lifetime must be greater than zero!", .{});

        var splash = Splash{
            .particles = ArrayList(Particle).init(alloc),
            .queue = ArrayList(NumberedVec2).init(alloc),
            .visited = ArrayList(Vec2).init(alloc),
            .color = color,
            .coord = coord,
            .max_size = max_size,
            .lifetime = lifetime,
            .tick = tick,
        };
        try splash.queue.append(.{ .num = 0, .coord = coord });
        try splash.visited.append(coord);
        return splash;
    }

    pub fn deinit(self: *Splash) void {
        self.particles.deinit();
        self.queue.deinit();
        self.visited.deinit();
    }

    pub fn update(self: *Splash, bounds: Range2) !void {
        defer while (self.particles.items.len > 0 and self.particles.items[0].finished()) {
            _ = self.particles.orderedRemove(0);
            self.finished_count += 1;
        };
        if (self.size > self.max_size) {
            return;
        }
        const time = rl.getTime();
        if (time < self.last_tick + self.tick) {
            return;
        }
        self.last_tick = time;
        while (self.queue.items.len > 0) {
            if (self.queue.items[0].num > self.size) {
                self.size += 1;
                return;
            }
            const num_vec = self.queue.orderedRemove(0);
            try self.particles.append(try Particle.init(self.color, num_vec.coord, self.lifetime));
            outer: for (offsets) |offset| {
                const next_coord = num_vec.coord.add(offset);
                if (!bounds.contains(next_coord)) {
                    continue;
                }
                for (self.visited.items) |coord| {
                    if (next_coord.eql(coord)) {
                        continue :outer;
                    }
                }
                try self.queue.append(.{ .num = num_vec.num + 1, .coord = next_coord });
                try self.visited.append(next_coord);
            }
        }
    }

    pub fn finished(self: *Splash) bool {
        return self.particles.items.len == 0 and self.finished_count > 0;
    }

    pub fn draw(self: *Splash, grid: *Grid) void {
        return drawParticles(&self.particles, grid);
    }
};

pub const SplashGroup = struct {
    splashes: ArrayList(Splash),
    alloc: Allocator,

    pub fn init(alloc: Allocator) SplashGroup {
        return SplashGroup{ .splashes = ArrayList(Splash).init(alloc), .alloc = alloc };
    }

    pub fn deinit(self: *SplashGroup) void {
        for (self.splashes.items) |*splash| {
            splash.deinit();
        }
        self.splashes.deinit();
    }

    pub fn spawnSplash(self: *SplashGroup, color: Color, coord: Vec2, options: SplashOptions) !void {
        try self.splashes.append(try Splash.init(
            color,
            coord,
            options.max_size,
            options.lifetime,
            options.tick,
            self.alloc,
        ));
    }

    pub fn update(self: *SplashGroup, bounds: Range2) !void {
        for (self.splashes.items) |*splash| {
            try splash.update(bounds);
        }
        var i: usize = self.splashes.items.len;
        while (i > 0) {
            i -= 1;
            if (self.splashes.items[i].finished()) {
                self.splashes.items[i].deinit();
                _ = self.splashes.orderedRemove(i);
            }
        }
    }

    pub fn draw(self: *SplashGroup, grid: *Grid) void {
        for (self.splashes.items) |*splash| {
            splash.draw(grid);
        }
    }
};

pub fn lerpColor(src_color: Color, current: u64, limit: u64) Color {
    const lerp: f64 = 1 - @min(1, @as(f64, @floatFromInt(current)) / @as(f64, @floatFromInt(limit)));
    return Color.init(
        @as(u8, @intFromFloat(@as(f64, @floatFromInt(src_color.r)) * lerp)),
        @as(u8, @intFromFloat(@as(f64, @floatFromInt(src_color.g)) * lerp)),
        @as(u8, @intFromFloat(@as(f64, @floatFromInt(src_color.b)) * lerp)),
        src_color.a,
    );
}

pub fn drawParticles(particles: *ArrayList(Particle), grid: *Grid) void {
    for (particles.items) |*p| {
        if (p.coord.x < 0 or p.coord.x >= grid.getCols() or
            p.coord.y < 0 or p.coord.y >= grid.getCols())
        {
            continue;
        }
        const x: usize = @intCast(p.coord.x);
        const y: usize = @intCast(p.coord.y);
        const grid_color = grid.cells[y][x].color;
        const r: u8 = @min(255, @as(u16, p.color().r) + grid_color.r);
        const g: u8 = @min(255, @as(u16, p.color().g) + grid_color.g);
        const b: u8 = @min(255, @as(u16, p.color().b) + grid_color.b);
        grid.cells[y][x].color = Color.init(r, g, b, grid_color.a);
    }
}
