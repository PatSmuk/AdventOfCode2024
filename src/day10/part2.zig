const std = @import("std");
const util = @import("util");

const DirectionVector = [2]i8;

const direction_vectors = [_]DirectionVector{
    .{ 0, -1 }, // up
    .{ 1, 0 }, // right
    .{ 0, 1 }, // down
    .{ -1, 0 }, // left
};

const Coord = [2]usize;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = try util.readInputFileLines([]u4, allocator, "day10.txt", parseLine);
    defer allocator.free(grid);
    defer {
        for (grid) |row| {
            allocator.free(row);
        }
    }

    var score_sum: u16 = 0;
    for (grid, 0..) |heights, row| {
        for (heights, 0..) |height, col| {
            if (height == 0) {
                var peaks_seen = std.AutoHashMap(Coord, void).init(allocator);
                defer peaks_seen.deinit();

                score_sum += try calculateTrailheadScore(grid, row, col, &peaks_seen);
            }
        }
    }

    std.debug.print("{d}", .{score_sum});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u4 {
    const heights = try allocator.alloc(u4, line.len);

    for (line, 0..) |char, i| {
        heights[i] = try std.fmt.parseInt(u4, &[_]u8{char}, 10);
    }

    return heights;
}

fn calculateTrailheadScore(grid: [][]const u4, row: usize, col: usize, peaks_seen: *std.AutoHashMap(Coord, void)) !u8 {
    var score: u8 = 0;

    for (direction_vectors) |direction| {
        const maybe_new_row = @as(isize, @intCast(row)) + direction[1];
        const maybe_new_col = @as(isize, @intCast(col)) + direction[0];

        if (!isInBounds(grid, maybe_new_row, maybe_new_col)) {
            continue;
        }

        const new_row = @as(usize, @intCast(maybe_new_row));
        const new_col = @as(usize, @intCast(maybe_new_col));

        if (grid[new_row][new_col] != grid[row][col] + 1) {
            continue;
        }

        if (grid[new_row][new_col] == 9) {
            score += 1;
        } else {
            score += try calculateTrailheadScore(grid, new_row, new_col, peaks_seen);
        }
    }

    return score;
}

fn isInBounds(grid: [][]const u4, row: isize, col: isize) bool {
    return row >= 0 and row < grid.len and col >= 0 and col < grid[0].len;
}
