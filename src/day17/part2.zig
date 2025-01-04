const std = @import("std");
const util = @import("util");
const Regex = @import("regex").Regex;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day17.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var candidates = std.ArrayList(u64).init(allocator);
    defer candidates.deinit();
    try candidates.append(0);

    for (0..program.len) |i| {
        const target = program[program.len - i - 1];
        var new_candidates = std.ArrayList(u64).init(allocator);

        for (candidates.items) |candidate| {
            for (0..8) |offset| {
                const new_candidate = (candidate << 3) + offset;
                const output = runProgram(new_candidate);
                if (output.len > 0 and output[0] == target) {
                    try new_candidates.append(new_candidate);
                }
            }
        }

        candidates.deinit();
        candidates = new_candidates;
    }

    if (candidates.items.len > 0) {
        std.debug.print("{d}", .{candidates.items[0]});
    }
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

const program = [_]u3{ 2, 4, 1, 5, 7, 5, 0, 3, 4, 1, 1, 6, 5, 5, 3, 0 };
var output_buf = [_]u3{0} ** program.len;

fn runProgram(input: u64) []u3 {
    var reg_a = input;
    var reg_b: u64 = 0;
    var reg_c: u64 = 0;
    var output_i: usize = 0;

    while (reg_a > 0) {
        reg_b = reg_a & 0b111;
        reg_b = reg_b ^ 0b101;
        reg_c = reg_a >> @as(u3, @intCast(reg_b));
        reg_a = reg_a >> 3;
        reg_b = reg_b ^ reg_c;
        reg_b = reg_b ^ 0b110;
        output_buf[output_i] = @as(u3, @intCast(reg_b & 0b111));
        output_i += 1;
    }

    return output_buf[0..output_i];
}
