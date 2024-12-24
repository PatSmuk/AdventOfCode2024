const std = @import("std");
const util = @import("util");

const Direction = enum { up, right, down, left };

const DirectionVector = [2]i8;

const direction_vectors = [_]DirectionVector{
    .{ 0, -1 }, // up
    .{ 1, 0 }, // right
    .{ 0, 1 }, // down
    .{ -1, 0 }, // left
};

const Position = [2]usize;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day06.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    const max_row = lines.len;
    const max_col = lines[0].len;

    // Find starting location and direction
    var current_row: usize = undefined;
    var current_col: usize = undefined;
    var current_direction: usize = 0;

    for (0.., lines) |row, line| {
        for (0.., line) |col, char| {
            if (char == '^') {
                current_row = row;
                current_col = col;
            }
        }
    }

    var visited_positions = std.AutoHashMap(Position, void).init(allocator);
    defer visited_positions.deinit();

    while (true) {
        try visited_positions.put(Position{ current_row, current_col }, {});

        const next_col = @as(usize, @intCast(@as(isize, @intCast(current_col)) + direction_vectors[current_direction][0]));
        const next_row = @as(usize, @intCast(@as(isize, @intCast(current_row)) + direction_vectors[current_direction][1]));

        if (!isInBounds(next_row, next_col, max_row, max_col)) {
            break;
        }

        if (lines[next_row][next_col] == '#') {
            current_direction += 1;
            current_direction %= direction_vectors.len;
            continue;
        }

        current_row = next_row;
        current_col = next_col;
    }

    std.debug.print("\n{d}", .{visited_positions.count()});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn isInBounds(row: usize, col: usize, max_row: usize, max_col: usize) bool {
    if (col < 0 or row < 0 or col >= max_col or row >= max_row) {
        return false;
    }
    return true;
}
