const std = @import("std");
const util = @import("util");

const Input = struct {
    final_value: u64,
    operands: []u16,
};

const Operator = enum {
    add,
    multiply,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const inputs = try util.readInputFileLines(Input, allocator, "day07.txt", parseLine);
    defer allocator.free(inputs);
    defer {
        for (inputs) |input| {
            allocator.free(input.operands);
        }
    }

    var total_calibration_result: u64 = 0;

    for (inputs) |input| {
        if (findOperators(input.operands, input.final_value)) {
            total_calibration_result += input.final_value;
        }
    }

    std.debug.print("{d}", .{total_calibration_result});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) !Input {
    var token_iterator = std.mem.tokenizeAny(u8, line, ": ");

    const final_value_token = token_iterator.next().?;
    const final_value = try std.fmt.parseInt(u64, final_value_token, 10);

    var operands = std.ArrayList(u16).init(allocator);
    defer operands.deinit();

    while (token_iterator.next()) |token| {
        try operands.append(try std.fmt.parseInt(u16, token, 10));
    }

    return .{
        .final_value = final_value,
        .operands = try allocator.dupe(u16, operands.items),
    };
}

fn findOperators(operands: []u16, final_value: u64) bool {
    std.debug.assert(operands.len < 17);
    const operands_len = @as(u16, @intCast(operands.len));

    var buffer = [_]u8{0} ** 64;

    for (0..std.math.pow(u32, 3, operands_len - 1)) |operators| {
        var value: u64 = operands[0];
        var operators_copy = operators;

        for (1..operands_len) |i| {
            const operator = operators_copy % 3;
            operators_copy /= 3;

            value = switch (operator) {
                0 => value + operands[i],
                1 => value * operands[i],
                2 => concat: {
                    const combined = std.fmt.bufPrint(&buffer, "{d}{d}", .{ value, operands[i] }) catch unreachable;
                    break :concat std.fmt.parseInt(usize, combined, 10) catch unreachable;
                },
                else => unreachable,
            };

            if (value > final_value) {
                break;
            }
        }

        if (value == final_value) {
            return true;
        }
    }

    return false;
}
