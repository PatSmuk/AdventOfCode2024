const std = @import("std");
const util = @import("util");
const Regex = @import("regex").Regex;

const MAX_X = 101;
const MAX_Y = 103;
const SECONDS_TO_SIMULATE = 1000000;

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

    var stdout_writer = std.io.bufferedWriter(std.io.getStdOut().writer());
    var seconds_buf = [_]u8{3 + 1 + 7 + 1 + 1} ** 10; // XXX seconds\n\0

    var input_regex = try Regex.compile(allocator, "p=(\\d+),(\\d+) v=(-?\\d+),(-?\\d+)");
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

    for (0..SECONDS_TO_SIMULATE) |seconds| {
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

        if (detectTree(robots.items)) {
            const seconds_str = try std.fmt.bufPrint(&seconds_buf, "{d}\n", .{seconds + 1});
            _ = try stdout_writer.write(seconds_str);
            try drawGrid(robots.items, &stdout_writer);
            break;
        }
    }
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn drawGrid(robots: []const Robot, writer: anytype) !void {
    var count_buf = [_]u8{0} ** 4;

    for (0..MAX_Y) |y| {
        for (0..MAX_X) |x| {
            var count: u8 = 0;
            for (robots) |robot| {
                if (robot.px == x and robot.py == y) {
                    count += 1;
                }
            }
            if (count > 0) {
                const count_str = std.fmt.bufPrintIntToSlice(&count_buf, count, 10, .lower, .{});
                _ = try writer.write(count_str);
            } else {
                _ = try writer.write(".");
            }
        }
        _ = try writer.write("\n");
    }
    _ = try writer.write("\n");
    try writer.flush();
}

fn detectTree(robots: []const Robot) bool {
    var counts = [_]u8{0} ** (MAX_X * MAX_Y);
    for (robots) |robot| {
        counts[robot.py * MAX_X + robot.px] += 1;
    }

    for (0..MAX_X) |x| {
        var consecutive_count: u8 = 0;
        for (0..MAX_Y) |y| {
            if (counts[y * MAX_X + x] > 0) {
                consecutive_count += 1;
            } else {
                consecutive_count = 0;
            }
            if (consecutive_count == 10) {
                return true;
            }
        }
    }

    for (0..MAX_Y) |y| {
        var consecutive_count: u8 = 0;
        for (0..MAX_X) |x| {
            if (counts[y * MAX_X + x] > 0) {
                consecutive_count += 1;
            } else {
                consecutive_count = 0;
            }
            if (consecutive_count == 10) {
                return true;
            }
        }
    }

    return false;
}
