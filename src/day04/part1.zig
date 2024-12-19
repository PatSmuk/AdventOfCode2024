const std = @import("std");
const util = @import("util");
const regex = @import("regex");

const RowColOffset = struct {
    row: i8,
    col: i8,
};

const offsets = [_]RowColOffset{
    .{ .row = -1, .col = 0 }, // up
    .{ .row = -1, .col = -1 }, // up-left
    .{ .row = -1, .col = 1 }, // up-right
    .{ .row = 1, .col = 0 }, // down
    .{ .row = 1, .col = -1 }, // down-left
    .{ .row = 1, .col = 1 }, // down-right
    .{ .row = 0, .col = -1 }, // left
    .{ .row = 0, .col = 1 }, // right
};

const expected_letters = [_]u8{ 'X', 'M', 'A', 'S' };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var pattern = try regex.Regex.compile(allocator, "mul\\((\\d{1,3}),(\\d{1,3})\\)");
    defer pattern.deinit();

    const lines = try util.readInputFileLines([]u8, allocator, "day04.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    const num_rows = lines.len;
    const num_cols = lines[0].len;

    var xmas_count: u32 = 0;

    // For each row...
    var row: usize = 0;
    while (row < num_rows) : (row += 1) {
        const check_up = row >= 3;
        const check_down = row <= num_rows - 4;

        // ... and check column ...
        var col: usize = 0;
        while (col < num_cols) : (col += 1) {
            // If this isn't a starting point, move along
            if (lines[row][col] != expected_letters[0]) {
                continue;
            }

            const check_left = col >= 3;
            const check_right = col <= num_cols - 4;

            // Create a table of directions to check
            const check_table = [_]bool{
                check_up,
                check_up and check_left,
                check_up and check_right,
                check_down,
                check_down and check_left,
                check_down and check_right,
                check_left,
                check_right,
            };
            std.debug.assert(check_table.len == offsets.len);

            for (check_table, offsets) |should_check, offsets_for_direction| {
                if (!should_check) {
                    continue;
                }

                var i: isize = 1; // X is already checked above so skip it
                while (i < expected_letters.len) : (i += 1) {
                    const r = @as(usize, @intCast(@as(isize, @intCast(row)) + offsets_for_direction.row * i));
                    const c = @as(usize, @intCast(@as(isize, @intCast(col)) + offsets_for_direction.col * i));

                    // If any letters don't match break the loop, skipping the else branch
                    if (lines[r][c] != expected_letters[@as(usize, @intCast(i))]) {
                        break;
                    }
                } else {
                    // All letters matched (no break happened)
                    xmas_count += 1;
                }
            }
        }
    }

    std.debug.print("{d}", .{xmas_count});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}
