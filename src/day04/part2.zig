const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day04.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    const num_rows = lines.len;
    const num_cols = lines[0].len;

    var x_mas_count: u32 = 0;

    // For each row...
    var row: usize = 1;
    while (row < num_rows - 1) : (row += 1) {
        // ... and check column ...
        var col: usize = 1;
        while (col < num_cols - 1) : (col += 1) {
            // If this isn't a starting point, move along
            if (lines[row][col] != 'A') {
                continue;
            }

            var diagonal_mas_count: u8 = 0;
            if ((lines[row - 1][col - 1] == 'M' and lines[row + 1][col + 1] == 'S') or (lines[row - 1][col - 1] == 'S' and lines[row + 1][col + 1] == 'M')) {
                diagonal_mas_count += 1;
            }
            if ((lines[row - 1][col + 1] == 'M' and lines[row + 1][col - 1] == 'S') or (lines[row - 1][col + 1] == 'S' and lines[row + 1][col - 1] == 'M')) {
                diagonal_mas_count += 1;
            }

            if (diagonal_mas_count == 2) {
                // Live mas
                x_mas_count += 1;
            }
        }
    }

    std.debug.print("{d}", .{x_mas_count});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}
