const std = @import("std");
const util = @import("util");

const NUM_STEPS = 75;

const Stone = u64;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]Stone, allocator, "day11.txt", parseLine);
    defer allocator.free(lines);
    defer allocator.free(lines[0]);

    var stone_counts = std.AutoHashMap(u64, u64).init(allocator);
    defer stone_counts.deinit();

    for (lines[0]) |num| {
        try util.mapInc(u64, u64, &stone_counts, num, 1);
    }

    var value_buf = [_]u8{0} ** 21;

    for (0..NUM_STEPS) |step| {
        _ = step; // autofix
        var new_stone_counts = std.AutoHashMap(u64, u64).init(allocator);

        var iter = stone_counts.iterator();
        while (iter.next()) |entry| {
            const value = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            if (value == 0) {
                try util.mapInc(u64, u64, &new_stone_counts, 1, count);
            } else {
                const value_str = std.fmt.bufPrintIntToSlice(&value_buf, value, 10, .lower, .{});

                if (value_str.len % 2 == 0) {
                    const left = try std.fmt.parseInt(Stone, value_str[0..(value_str.len / 2)], 10);
                    const right = try std.fmt.parseInt(Stone, value_str[(value_str.len / 2)..], 10);
                    try util.mapInc(u64, u64, &new_stone_counts, left, count);
                    try util.mapInc(u64, u64, &new_stone_counts, right, count);
                } else {
                    try util.mapInc(u64, u64, &new_stone_counts, value * 2024, count);
                }
            }
        }

        stone_counts.deinit();
        stone_counts = new_stone_counts;
    }

    std.debug.print("{d}", .{countStones(stone_counts)});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]Stone {
    var nums = std.ArrayList(Stone).init(allocator);

    var iter = std.mem.tokenizeScalar(u8, line, ' ');
    while (iter.next()) |token| {
        try nums.append(try std.fmt.parseInt(Stone, token, 10));
    }

    return nums.toOwnedSlice();
}

fn countStones(map: std.AutoHashMap(u64, u64)) u64 {
    var iter = map.valueIterator();
    var sum: u64 = 0;
    while (iter.next()) |count| {
        sum += count.*;
    }
    return sum;
}
