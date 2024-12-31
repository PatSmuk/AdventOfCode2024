const std = @import("std");
const util = @import("util");
const Regex = @import("regex").Regex;

const MAX_X = 101;
const MAX_Y = 103;
const SECONDS_TO_SIMULATE = 100;

const Robot = struct {
    px: u8,
    py: u8,
    vx: i8,
    vy: i8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var input_regex = try Regex.compile(allocator, "p=(-?\\d+),(-?\\d+) v=(-?\\d+),(-?\\d+)");
    defer input_regex.deinit();

    const lines = try util.readInputFileLines([]u8, allocator, "day14.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var robots = try std.ArrayList(Robot).initCapacity(allocator, lines.len);
    defer robots.deinit();

    for (lines) |line| {
        var captures = (try input_regex.captures(line)).?;
        defer captures.deinit();

        const px = try std.fmt.parseInt(u8, captures.sliceAt(1).?, 10);
        const py = try std.fmt.parseInt(u8, captures.sliceAt(2).?, 10);
        const vx = try std.fmt.parseInt(i8, captures.sliceAt(3).?, 10);
        const vy = try std.fmt.parseInt(i8, captures.sliceAt(4).?, 10);

        std.debug.assert(px < MAX_X);
        std.debug.assert(py < MAX_Y);

        robots.appendAssumeCapacity(.{
            .px = px,
            .py = py,
            .vx = vx,
            .vy = vy,
        });
    }

    drawGrid(robots.items);

    for (0..SECONDS_TO_SIMULATE) |_| {
        for (robots.items) |*robot| {
            var x = @as(i16, @intCast(robot.px)) + robot.vx;
            if (x < 0) x += MAX_X;
            if (x >= MAX_X) x -= MAX_X;

            var y = @as(i16, @intCast(robot.py)) + robot.vy;
            if (y < 0) y += MAX_Y;
            if (y >= MAX_Y) y -= MAX_Y;

            robot.px = @as(u8, @intCast(x));
            robot.py = @as(u8, @intCast(y));
        }
    }

    drawGrid(robots.items);

    const safety_factor = blk: {
        var top_left: u16 = 0;
        var top_right: u16 = 0;
        var bottom_left: u16 = 0;
        var bottom_right: u16 = 0;

        for (robots.items) |robot| {
            const is_left = robot.px < (MAX_X / 2);
            const is_right = robot.px > (MAX_X / 2);
            const is_top = robot.py < (MAX_Y / 2);
            const is_bottom = robot.py > (MAX_Y / 2);

            if (is_left and is_top) top_left += 1;
            if (is_left and is_bottom) bottom_left += 1;
            if (is_right and is_top) top_right += 1;
            if (is_right and is_bottom) bottom_right += 1;
        }

        break :blk @as(u32, top_left) * top_right * bottom_left * bottom_right;
    };

    std.debug.print("{d}", .{safety_factor});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn drawGrid(robots: []const Robot) void {
    for (0..MAX_Y) |y| {
        for (0..MAX_X) |x| {
            var count: u8 = 0;
            for (robots) |robot| {
                if (robot.px == x and robot.py == y) {
                    count += 1;
                }
            }
            if (count > 0) {
                std.debug.print("{d}", .{count});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}
