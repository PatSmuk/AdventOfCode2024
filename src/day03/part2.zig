const std = @import("std");
const util = @import("util");
const regex = @import("regex");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var pattern = try regex.Regex.compile(allocator, "(mul\\(\\d{1,3},\\d{1,3}\\))|(do\\(\\))|(don't\\(\\))");
    defer pattern.deinit();

    // Extracts the numbers from the mul(X,Y) pattern
    var inner_pattern = try regex.Regex.compile(allocator, "mul\\((\\d{1,3}),(\\d{1,3})\\)");
    defer inner_pattern.deinit();

    const lines = try util.readInputFileLines([]u8, allocator, "day03.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var sum: u32 = 0;
    var multiply_enabled = true;

    for (lines) |line| {
        var current_line = line;
        var maybe_captures = try pattern.captures(current_line);

        while (maybe_captures) |*captures| {
            const substring = captures.sliceAt(0).?;
            const span = captures.boundsAt(0).?;

            if (std.mem.eql(u8, substring, "do()")) {
                multiply_enabled = true;
            } else if (std.mem.eql(u8, substring, "don't()")) {
                multiply_enabled = false;
            } else if (multiply_enabled) {
                var inner_capture = (try inner_pattern.captures(substring)).?;
                defer inner_capture.deinit();

                const first_arg = inner_capture.sliceAt(1).?;
                const second_arg = inner_capture.sliceAt(2).?;
                const first_num = try std.fmt.parseInt(u32, first_arg, 10);
                const second_num = try std.fmt.parseInt(u32, second_arg, 10);
                sum += first_num * second_num;
            }

            // Update line slice to remove everything up to end of current match
            // const span = captures.boundsAt(0).?;
            current_line = current_line[span.upper..];

            // Try to capture another match, if one exists
            captures.deinit();
            maybe_captures = try pattern.captures(current_line);
        }
    }

    std.debug.print("{d}", .{sum});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}
