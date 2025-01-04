const std = @import("std");
const util = @import("util");
const Regex = @import("regex").Regex;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var register_regex = try Regex.compile(allocator, "Register ([A-C]): (\\d+)");
    defer register_regex.deinit();
    var program_regex = try Regex.compile(allocator, "Program: ((\\d|,)+)");
    defer program_regex.deinit();

    const lines = try util.readInputFileLines([]u8, allocator, "day17.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var reg_a: u32 = undefined;
    var reg_b: u32 = undefined;
    var reg_c: u32 = undefined;
    var program = std.ArrayList(u3).init(allocator);
    defer program.deinit();

    for (lines) |line| {
        var maybe_captures = try register_regex.captures(line);
        if (maybe_captures) |captures| {
            defer maybe_captures.?.deinit();
            const register = captures.sliceAt(1).?;
            const value = try std.fmt.parseInt(u32, captures.sliceAt(2).?, 10);

            switch (register[0]) {
                'A' => reg_a = value,
                'B' => reg_b = value,
                'C' => reg_c = value,
                else => unreachable,
            }

            continue;
        }

        maybe_captures = try program_regex.captures(line);
        std.debug.assert(maybe_captures != null);
        defer maybe_captures.?.deinit();

        var instruction_iter = std.mem.tokenizeScalar(u8, maybe_captures.?.sliceAt(1).?, ',');
        while (instruction_iter.next()) |instruction_str| {
            std.debug.assert(instruction_str[0] >= '0' and instruction_str[0] <= '7');
            const instruction = @as(u3, @intCast(instruction_str[0] - '0'));
            try program.append(instruction);
        }
    }

    var ip: u8 = 0;
    var output_buf = [_]u8{0} ** 16;
    var output = std.ArrayList([]const u8).init(allocator);
    defer output.deinit();
    defer {
        for (output.items) |piece| {
            allocator.free(piece);
        }
    }

    if (debug_output) {
        std.debug.print("ins |    operand | ip | A register | B register | C register\n", .{});
        std.debug.print("------------------------------------------------------------\n", .{});
    }

    while (ip < program.items.len) {
        const inst = program.items[ip];
        switch (inst) {
            // adv
            0 => {
                const operand = combo(program.items[ip + 1], reg_a, reg_b, reg_c);
                reg_a /= @as(u32, 1) << @as(u5, @intCast(operand));
                ip += 2;
                debug(inst, operand, ip, reg_a, reg_b, reg_c);
            },
            // bxl
            1 => {
                const operand = program.items[ip + 1];
                reg_b ^= operand;
                ip += 2;
                debug(inst, operand, ip, reg_a, reg_b, reg_c);
            },
            // bst
            2 => {
                const operand = combo(program.items[ip + 1], reg_a, reg_b, reg_c);
                reg_b = operand & 0b111;
                ip += 2;
                debug(inst, operand, ip, reg_a, reg_b, reg_c);
            },
            // jnz
            3 => {
                if (reg_a != 0) {
                    ip = program.items[ip + 1];
                } else {
                    ip += 2;
                }
                debug(inst, 0, ip, reg_a, reg_b, reg_c);
            },
            // bxc
            4 => {
                reg_b ^= reg_c;
                ip += 2;
                debug(inst, 0, ip, reg_a, reg_b, reg_c);
            },
            // out
            5 => {
                const operand = combo(program.items[ip + 1], reg_a, reg_b, reg_c);
                const result = std.fmt.bufPrintIntToSlice(&output_buf, operand & 0b111, 10, .lower, .{});
                try output.append(try allocator.dupe(u8, result));
                ip += 2;
                debug(inst, operand, ip, reg_a, reg_b, reg_c);
            },
            // bdv
            6 => {
                const operand = combo(program.items[ip + 1], reg_a, reg_b, reg_c);
                reg_b = reg_a / (@as(u32, 1) << @as(u5, @intCast(operand)));
                ip += 2;
                debug(inst, operand, ip, reg_a, reg_b, reg_c);
            },
            // cdv
            7 => {
                const operand = combo(program.items[ip + 1], reg_a, reg_b, reg_c);
                reg_c = reg_a / (@as(u32, 1) << @as(u5, @intCast(operand)));
                ip += 2;
                debug(inst, operand, ip, reg_a, reg_b, reg_c);
            },
        }
    }

    const output_str = try std.mem.join(allocator, ",", output.items);
    defer allocator.free(output_str);
    std.debug.print("{s}", .{output_str});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn combo(operand: u3, reg_a: u32, reg_b: u32, reg_c: u32) u32 {
    return switch (operand) {
        0...3 => operand,
        4 => reg_a,
        5 => reg_b,
        6 => reg_c,
        7 => unreachable,
    };
}

const debug_output = true;

fn debug(inst: u3, operand: u32, ip: u8, reg_a: u32, reg_b: u32, reg_c: u32) void {
    const inst_str = switch (inst) {
        0 => "adv",
        1 => "bxl",
        2 => "bst",
        3 => "jnz",
        4 => "bxc",
        5 => "out",
        6 => "bdv",
        7 => "cdv",
    };

    if (debug_output) {
        std.debug.print("{s} | {d:10} | {d:2} | {d:10} | {d:10} | {d:10}\n", .{ inst_str, operand, ip, reg_a, reg_b, reg_c });
    }
}
