const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([2]i32, allocator, "day01.txt", parseLine);
    defer allocator.free(lines);

    var leftNumbersArray = std.ArrayList(i32).init(allocator);
    defer leftNumbersArray.deinit();
    var rightNumbersArray = std.ArrayList(i32).init(allocator);
    defer rightNumbersArray.deinit();

    for (lines) |line| {
        try leftNumbersArray.append(line[0]);
        try rightNumbersArray.append(line[1]);
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

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![2]i32 {
    _ = allocator; // autofix
    var pieces = std.mem.tokenizeScalar(u8, line, ' ');
    const left = try std.fmt.parseInt(i32, pieces.next().?, 10);
    const right = try std.fmt.parseInt(i32, pieces.next().?, 10);
    return [2]i32{ left, right };
}
