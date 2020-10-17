const std = @import("std");
const tallocator = std.testing.allocator;
const warn = std.debug.warn;
const exact = std.mem.Allocator.Exact;
const assertEqual = std.testing.expectEqual;

pub const Iterator = struct {
    allocator: *std.mem.Allocator,
    iterable: anytype,
    index: usize,
    length: usize,

    const Self = @This();

    pub fn next(it: *Self) *@TypeOf(iterable[0]) {
        defer it.allocator.destroy(iterable);

        if (it.length == 0) return undefined;

        while ( it.index < it.length ) : ( it.index += 1 ) {
            const item = it.iterable[it.index];
            return item;
        }

        return undefined;
    }

};


pub fn accumulate(
    allocat: *std.mem.Allocator,
    func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    init: ?@typeInfo(@TypeOf(func)).Fn.return_type.?
) *[]@typeInfo(@TypeOf(func)).Fn.return_type.?  {
    var i: usize = 0;
    var totalLength: usize = iterable.len;
    var ans  = allocat.alloc(@typeInfo(@TypeOf(func)).Fn.return_type.?, iterable.len) catch unreachable;
    errdefer allocat.destroy(ans);
    
    if (init) | int | {
        ans[i] = init.?;
    } else {
        ans[i] = iterable[0];
    }
    i += 1;
    while (i < totalLength) : ( i+=1 ) {
        ans[i] = func(ans[i], iterable[i]);
    }

    return &ans;
}

// pub fn accumulate(comptime func: anytype, 
//     iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
//     comptime init: @typeInfo(@TypeOf(func)).Fn.return_type.? )
// @typeInfo(@TypeOf(func)).Fn.return_type.? {
//     var ans = init;
//     for (iterable) | item | {
//         ans = func(ans, item);
//     }
//     return ans;
// }


pub fn add (a: u8, b: u8) u8 { 
    return a + b; 
}
pub fn mul (a: u8, b: u8) u8 { 
    return a * b; 
}
test "Accumulate" {
    var A = [_]u8{1, 2, 4};
    var res = accumulate(tallocator, add, &A, 0);
    warn ("item: {}" , .{res});
    tallocator.destroy(res.ptr);
    //tallocator.destroy(res);

    //tallocator.destroy(res);


    // while (accumulate(add, &A, 0).next()) | item | {
    //     warn("item: {}\r\n", .{item});
    // }

    // while (accumulate(mul, &A, 0).next()) | item | {
    //     warn("item: {}\r\n", .{item});
    // }

    // while (accumulate(mul, &A, 1).next()) | item | {
    //     warn("item: {}\r\n", .{item});
    // }

    // var A = [_]u8{1, 2, 4};
    // assertEqual(accumulate(add, &A, 0), 7);
    // assertEqual(accumulate(mul, &A, 0), 0);
    // assertEqual(accumulate(mul, &A, 1), 8);

}

// pub fn chain(comptime allocator: *std.mem.Allocator,
//     comptime func: anytype,
//     comptime iterables: [][]@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.? )
// @typeInfo(@TypeOf(func)).Fn.return_type.? {
//     var totalLength = 0;
//     inline for (iterables) | iterable | {
//         totalLength += iterable.len;
//     }

//     var ans  = try allocator.alloc(@typeInfo(@TypeOf(func)).Fn.return_type.?, totalLength);
//     var index = 0;
//     inline for (iterables) | iterable | {
//         inline for (iterable) | item | {
//             ans[index] = func(item);
//             index += 1; 
//         }
//     }
//     return ans;
// }

// fn addOne(a: u8) u8 {
//     return a+1;
// }
// test "Chain" {
//     comptime var A = [_][]i32{ 
//         [_]i32{1, 2}, 
//         [_]i32{3, 4}
//     };
//     assertEqual(chain(std.testing.allocator, addOne, &A), []i32{2,3,4,5});
// }