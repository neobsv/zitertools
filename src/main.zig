const std = @import("std");
const tallocator = std.testing.allocator;
const warn = std.debug.warn;
const assertEqual = std.testing.expectEqual;

pub fn Iterator(comptime T: type) type {
    return struct {
        allocator: *std.mem.Allocator,
        iterable: []T,
        index: usize = 0,
        len: usize,

        const Self = @This();

        fn incr(it: *Self) void {
            it.index += 1;
        }

        pub fn next(it: *Self) ?*const T {
            if(it.index < it.len) {
                defer it.incr();
                return &it.iterable[it.index];
            }
            return null;
        }

        pub fn init(alloc: *std.mem.Allocator, iter: []T) Self {
            var temp: []T = alloc.dupe(T, iter) catch unreachable;
            return Self{
                .allocator = alloc,
                .iterable = temp,
                .len = iter.len
            };
        }

        pub fn deinit(it: *Self) void {
            it.allocator.free(it.iterable);
        }
    };
}


test "Iterator" {

    var A: []u8 = tallocator.alloc(u8, 10) catch unreachable;
    defer tallocator.destroy(A.ptr);

    var i: u8 = 0;
    while ( i < 10 ) : ( i += 1 ) {
        A[i] = i;
    } 
    var iter = Iterator(u8).init(tallocator, A);
    defer iter.deinit();

    i = 0;
    while (iter.next()) | item | {
        assertEqual(A[i], item.*);
        i += 1;
    }

    warn("\r\n", .{});

    var B = std.ArrayList(u8).init(tallocator);
    defer B.deinit();

    i =  0;
    while ( i < 10 ) : ( i += 1 ) {
        _ = try B.append(i*2);
    } 
    var iter2 = Iterator(u8).init(tallocator, B.items);
    defer iter2.deinit();

    i = 0;
    while (iter2.next()) | item2 | {
        assertEqual(B.items[i], item2.*);
        i += 1;
    }

}

pub fn accumulate(
    allocat: *std.mem.Allocator,
    func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    init: ?@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.return_type.?) {
    const RType = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    var ans: []RType  = allocat.alloc(RType, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    var i: usize = 0;
    if (init) | int | {
        ans[i] = init.?;
    } else {
        ans[i] = iterable[0];
    }
    i += 1;
    while (i < iterable.len) : ( i+=1 ) {
        ans[i] = ans[i] + iterable[i];
        warn("ans: {}", .{ans[i]});
    }

    return Iterator(RType).init(allocat, ans);
}

pub fn add (a: u8, b: u8) u8 { 
    return a + b; 
}
pub fn mul (a: u8, b: u8) u8 { 
    return a * b; 
}

test "Accumulator" {
    var A = [_]u8{1, 2, 4};
    var ans = [_]u8{1, 3, 7};
    var res = accumulate(tallocator, add, A, 0);
    defer res.deinit();

    var i: usize = 0;
    while( res.next() ) | item | {
        warn("item: {}\n", .{item.*});
        assertEqual(A[i], item.*);
        i += 1;
    }
    warn ("\r\n" , .{});

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