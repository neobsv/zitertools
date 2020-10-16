const std = @import("std");
const assertEqual = std.testing.expectEqual;
const tuple = std.meta.Tuple;

pub fn accumulate(comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.return_type.? )
@typeInfo(@TypeOf(func)).Fn.return_type.? {
    var ans = init;
    for (iterable) | item | {
        ans = func(ans, item);
    }
    return ans;
}

pub fn add (a: u8, b: u8) u8 { 
    return a + b; 
}
pub fn mul (a: u8, b: u8) u8 { 
    return a * b; 
}
test "Accumulate" {
    var A = [_]u8{1, 2, 4};
    assertEqual(accumulate(add, &A, 0), 7);
    assertEqual(accumulate(mul, &A, 0), 0);
    assertEqual(accumulate(mul, &A, 1), 8);
}

pub fn chain(comptime allocator: *std.mem.Allocator,
    comptime func: anytype,
    comptime iterables: [][]@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.? )
@typeInfo(@TypeOf(func)).Fn.return_type.? {
    var totalLength = 0;
    inline for (iterables) | iterable | {
        totalLength += iterable.len;
    }

    var ans  = try allocator.alloc(@typeInfo(@TypeOf(func)).Fn.return_type.?, totalLength);
    var index = 0;
    inline for (iterables) | iterable | {
        inline for (iterable) | item | {
            ans[index] = func(item);
            index += 1; 
        }
    }
    return ans;
}

fn addOne(a: u8) u8 {
    return a+1;
}
test "Chain" {
    var A = [2][2]i32{[_]i32{1, 2}, [_]i32{3, 4}};
    assertEqual(chain(std.testing.allocator, addOne, &A), []i32{2,3,4,5});
}