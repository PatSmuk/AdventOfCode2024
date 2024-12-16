const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([2]u32, allocator, "day01.txt", parseLine);
    defer allocator.free(lines);

    var leftNumbers = std.ArrayList(u32).init(allocator);
    defer leftNumbers.deinit();

    var rightNumberCounts = std.AutoHashMap(u32, u16).init(allocator);
    defer rightNumberCounts.deinit();

    for (lines) |line| {
        try leftNumbers.append(line[0]);

        const count = rightNumberCounts.get(line[1]) orelse 0;
        try rightNumberCounts.put(line[1], count + 1);
    }

    var similarityScore: u32 = 0;

    for (leftNumbers.items) |n| {
        const count = rightNumberCounts.get(n) orelse 0;
        similarityScore += n * count;
    }

    std.debug.print("{d}\n", .{similarityScore});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![2]u32 {
    _ = allocator; // autofix
    var pieces = std.mem.tokenizeAny(u8, line, " \r");
    const left = try std.fmt.parseInt(u32, pieces.next().?, 10);
    const right = try std.fmt.parseInt(u32, pieces.next().?, 10);
    return [2]u32{ left, right };
}
