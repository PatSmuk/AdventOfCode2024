const std = @import("std");
const util = @import("util");

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]const u8 {
    return allocator.dupe(u8, line);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]const u8, allocator, "day01.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var leftNumbers = std.ArrayList(u32).init(allocator);
    defer leftNumbers.deinit();

    var rightNumberCounts = std.AutoHashMap(u32, u16).init(allocator);
    defer rightNumberCounts.deinit();

    for (lines) |line| {
        var pieces = std.mem.tokenizeAny(u8, line, " \r");
        const left = try std.fmt.parseInt(u32, pieces.next().?, 10);
        const right = try std.fmt.parseInt(u32, pieces.next().?, 10);

        try leftNumbers.append(left);

        const count = rightNumberCounts.get(right) orelse 0;
        try rightNumberCounts.put(right, count + 1);
    }

    var similarityScore: u32 = 0;

    for (leftNumbers.items) |n| {
        const count = rightNumberCounts.get(n) orelse 0;
        similarityScore += n * count;
    }

    std.debug.print("{d}\n", .{similarityScore});
}
