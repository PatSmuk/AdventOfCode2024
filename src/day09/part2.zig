const std = @import("std");
const util = @import("util");

const FreeBlocks = struct {
    offset: usize,
    size: usize,
};

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

    var free_list = std.ArrayList(FreeBlocks).init(allocator);
    defer free_list.deinit();
    {
        var block_index: usize = 0;
        var id: u16 = 0;
        var is_file: bool = true;

        for (lines[0]) |char| {
            const size = char - '0';
            if (is_file) {
                std.debug.assert(size > 0);

                for (0..size) |_| {
                    blocks[block_index] = id;
                    block_index += 1;
                }
                id += 1;
            } else {
                if (size > 0) {
                    try free_list.append(.{ .offset = block_index, .size = size });

                    for (0..size) |_| {
                        blocks[block_index] = null;
                        block_index += 1;
                    }
                }
            }
            is_file = !is_file;
        }

        // Assuming that we always end up with a file at the end and not empty space
        std.debug.assert(!is_file);
    }

    {
        var file_index: usize = blocks.len - 1;
        var current_file_id = blocks[file_index];
        var file_size: usize = 0;

        // While we can still potentially move a file towards the start...
        while (file_index > 1 and free_list.items.len > 0 and file_index > free_list.items[0].offset) {
            // Find the start of the file
            while (blocks[file_index] == current_file_id) {
                file_index -= 1;
                file_size += 1;
            }

            // Create slice of the entire file
            const file = blocks[(file_index + 1)..(file_index + 1 + file_size)];

            // Try to find a destination to copy the file to, if any
            var dest_index: ?usize = null;
            var free_list_index: usize = 0;

            while (free_list_index < free_list.items.len) : (free_list_index += 1) {
                // If free space is equal to or bigger than the file size...
                if (free_list.items[free_list_index].size >= file_size) {
                    dest_index = free_list.items[free_list_index].offset;

                    // If equal, free space is now gone, so remove it
                    if (free_list.items[free_list_index].size == file_size) {
                        _ = free_list.orderedRemove(free_list_index);
                    } else {
                        // Otherwise adjust offset and size of free space
                        free_list.items[free_list_index].size -= file_size;
                        free_list.items[free_list_index].offset += file_size;
                    }
                    break;
                }
            }

            // If there's a place to copy to, perform the copy
            if (dest_index != null and dest_index.? < file_index) {
                std.mem.copyForwards(?u16, blocks[dest_index.? .. dest_index.? + file_size], file);

                // Mark file source blocks as empty for checksum
                for (0..file_size) |i| {
                    blocks[file_index + 1 + i] = null;
                }
            }

            // Seek file index backwards to next file to potentially move
            while (blocks[file_index] == null) {
                file_index -= 1;
            }
            current_file_id = blocks[file_index];
            file_size = 0;
        }
    }

    var checksum: usize = 0;

    for (0..blocks.len) |i| {
        if (blocks[i] == null) {
            continue;
        }
        checksum += blocks[i].? * i;
    }

    std.debug.print("{d}", .{checksum});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}
