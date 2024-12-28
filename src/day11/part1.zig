const std = @import("std");
const util = @import("util");

const NUM_STEPS = 25;

const Stone = u64;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]Stone, allocator, "day11.txt", parseLine);
    defer allocator.free(lines);

    var stones = std.ArrayList(Stone).fromOwnedSlice(allocator, lines[0]);
    defer stones.deinit();

    var stone_buffer = [_]u8{0} ** 21;

    for (0..NUM_STEPS) |_| {
        var new_stones = try std.ArrayList(Stone).initCapacity(allocator, stones.items.len * 2);

        for (stones.items) |stone| {
            if (stone == 0) {
                new_stones.appendAssumeCapacity(1);
            } else {
                const stone_string = std.fmt.bufPrintIntToSlice(&stone_buffer, stone, 10, .lower, .{});

                if (stone_string.len % 2 == 0) {
                    const left = try std.fmt.parseInt(Stone, stone_string[0..(stone_string.len / 2)], 10);
                    const right = try std.fmt.parseInt(Stone, stone_string[(stone_string.len / 2)..], 10);
                    new_stones.appendAssumeCapacity(left);
                    new_stones.appendAssumeCapacity(right);
                } else {
                    new_stones.appendAssumeCapacity(stone * 2024);
                }
            }
        }

        stones.deinit();
        stones = new_stones;
    }

    std.debug.print("{d}", .{stones.items.len});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]Stone {
    var nums = std.ArrayList(Stone).init(allocator);

    var iter = std.mem.tokenizeScalar(u8, line, ' ');
    while (iter.next()) |token| {
        try nums.append(try std.fmt.parseInt(Stone, token, 10));
    }

    return nums.toOwnedSlice();
}
