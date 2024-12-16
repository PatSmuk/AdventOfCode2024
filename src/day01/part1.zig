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

    var leftNumbersArray = std.ArrayList(i32).init(allocator);
    defer leftNumbersArray.deinit();
    var rightNumbersArray = std.ArrayList(i32).init(allocator);
    defer rightNumbersArray.deinit();

    for (lines) |line| {
        var pieces = std.mem.tokenizeAny(u8, line, " \r");
        const left = try std.fmt.parseInt(i32, pieces.next().?, 10);
        const right = try std.fmt.parseInt(i32, pieces.next().?, 10);
        try leftNumbersArray.append(left);
        try rightNumbersArray.append(right);
    }

    const leftNumbers = try leftNumbersArray.toOwnedSlice();
    defer allocator.free(leftNumbers);
    const rightNumbers = try rightNumbersArray.toOwnedSlice();
    defer allocator.free(rightNumbers);

    std.mem.sortUnstable(i32, leftNumbers, {}, std.sort.asc(i32));
    std.mem.sortUnstable(i32, rightNumbers, {}, std.sort.asc(i32));

    var totalDistance: u32 = 0;
    for (leftNumbers, rightNumbers) |left, right| {
        totalDistance += @abs(left - right);
    }

    std.debug.print("{d}", .{totalDistance});
}
