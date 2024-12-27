const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day09.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var total_blocks: u32 = 0;
    for (lines[0]) |char| {
        total_blocks += char - '0';
    }

    // Each block is either the ID of the file or null for empty space
    const blocks = try allocator.alloc(?u16, total_blocks);
    defer allocator.free(blocks);
    {
        var block_index: usize = 0;
        var id: u16 = 0;
        var is_file: bool = true;

        for (lines[0]) |char| {
            const size = char - '0';
            if (is_file) {
                for (0..size) |_| {
                    blocks[block_index] = id;
                    block_index += 1;
                }
                id += 1;
            } else {
                for (0..size) |_| {
                    blocks[block_index] = null;
                    block_index += 1;
                }
            }
            is_file = !is_file;
        }

        // Assuming that we always end up with a file at the end and not empty space
        std.debug.assert(!is_file);
    }

    {
        var next_file_index = blocks.len - 1;
        var next_empty_index: usize = lines[0][0] - '0';

        while (next_file_index > next_empty_index) {
            blocks[next_empty_index] = blocks[next_file_index];
            blocks[next_file_index] = null;
            next_empty_index += 1;
            next_file_index -= 1;

            // Seek next_file_index to next file
            while (blocks[next_file_index] == null and next_file_index > next_empty_index) {
                next_file_index -= 1;
            }
            // Seek next_empty_index to next empty block
            while (blocks[next_empty_index] != null and next_file_index > next_empty_index) {
                next_empty_index += 1;
            }
        }
    }

    var checksum: usize = 0;

    for (0..blocks.len) |i| {
        if (blocks[i] == null) {
            break;
        }
        checksum += blocks[i].? * i;
    }

    std.debug.print("{d}", .{checksum});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}
