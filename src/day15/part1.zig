const std = @import("std");
const util = @import("util");

const DirectionVector = [2]i8;

const direction_vectors = [_]DirectionVector{
    .{ 0, -1 }, // up
    .{ 1, 0 }, // right
    .{ 0, 1 }, // down
    .{ -1, 0 }, // left
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day15.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var grid = std.ArrayList([]u8).init(allocator);
    defer grid.deinit();

    var moves = std.ArrayList(u8).init(allocator);
    defer moves.deinit();

    var robot_x: u8 = undefined;
    var robot_y: u8 = undefined;

    for (lines, 0..) |line, y| {
        if (line[0] == '#') {
            try grid.append(line);
            if (std.mem.indexOfScalar(u8, line, '@')) |x| {
                robot_x = @as(u8, @intCast(x));
                robot_y = @as(u8, @intCast(y));
            }
        } else if (line.len > 0) {
            try moves.appendSlice(line);
        }
    }

    next_move: for (moves.items) |move| {
        // debugDrawGrid(grid.items);
        // std.debug.print("\nMove {c}\n", .{move});

        const direction = switch (move) {
            '^' => direction_vectors[0],
            '>' => direction_vectors[1],
            'v' => direction_vectors[2],
            '<' => direction_vectors[3],
            else => unreachable,
        };

        var check_x = @as(u8, @intCast(@as(i8, @intCast(robot_x)) + direction[0]));
        var check_y = @as(u8, @intCast(@as(i8, @intCast(robot_y)) + direction[1]));

        while (true) {
            if (grid.items[check_y][check_x] == '#') {
                continue :next_move;
            }

            if (grid.items[check_y][check_x] == '.') {
                grid.items[check_y][check_x] = 'O';
                grid.items[robot_y][robot_x] = '.';
                robot_x = @as(u8, @intCast(@as(i8, @intCast(robot_x)) + direction[0]));
                robot_y = @as(u8, @intCast(@as(i8, @intCast(robot_y)) + direction[1]));
                grid.items[robot_y][robot_x] = '@';
                break;
            }

            std.debug.assert(grid.items[check_y][check_x] == 'O');
            check_x = @as(u8, @intCast(@as(i8, @intCast(check_x)) + direction[0]));
            check_y = @as(u8, @intCast(@as(i8, @intCast(check_y)) + direction[1]));
        }
    }

    // debugDrawGrid(grid.items);

    var coord_sum: usize = 0;
    for (grid.items, 0..) |line, y| {
        for (line, 0..) |char, x| {
            if (char == 'O') {
                coord_sum += 100 * y + x;
            }
        }
    }

    std.debug.print("{d}", .{coord_sum});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn debugDrawGrid(grid: [][]const u8) void {
    for (grid) |line| {
        std.debug.print("{s}\n", .{line});
    }
}
