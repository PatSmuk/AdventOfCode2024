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
        if (findOperators(input.operands, input.final_value) != null) {
            // std.debug.print("{any} using {b} = {d}\n", .{ input.operands, operators, input.final_value });
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

fn findOperators(operands: []u16, final_value: u64) ?usize {
    std.debug.assert(operands.len < 17);
    const operands_len = @as(u16, @intCast(operands.len));

    for (0..std.math.pow(u16, 2, operands_len - 1)) |operator_bitfield| {
        var value: u64 = operands[0];

        for (1..operands_len) |i| {
            const bit = @as(u4, @intCast(i - 1));

            if ((operator_bitfield & @as(u16, 1) << bit) != 0) {
                value += operands[i];
            } else {
                value *= operands[i];
            }

            if (value > final_value) {
                break;
            }
        }

        if (value == final_value) {
            return operator_bitfield;
        }
    }

    return null;
}
