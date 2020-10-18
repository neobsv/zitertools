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

fn printTest(comptime T: type, iter: *Iterator(T), ans: []T) void{
    var i: usize = 0;
    while (iter.next()) | item | {
        assertEqual(ans[i], item.*);
        i += 1;
    }
    warn("\r\n", .{});
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

    printTest(u8, &iter, A);

    var B = std.ArrayList(u8).init(tallocator);
    defer B.deinit();

    i =  0;
    while ( i < 10 ) : ( i += 1 ) {
        _ = try B.append(i*2);
    } 
    var iter2 = Iterator(u8).init(tallocator, B.items);
    defer iter2.deinit();

    printTest(u8, &iter2, B.items);

}

pub fn accumulator(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) Iterator(@typeInfo(@TypeOf(func)).Fn.return_type.?) {
    const RType = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    var ans: []u8  = allocat.alloc(u8, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    for (ans) | _, i | { ans[i] = 0;}
    
    var i: usize = 0;
    ans[0] = func(init, iterable[0]);
    i += 1;
    while (i < iterable.len) : ( i += 1 ) {
        ans[i] =  func(ans[i-1], iterable[i]);
    }

    return Iterator(u8).init(allocat, ans);
}

fn add(a: u8, b:u8) u8 {
    return a + b;
}

fn mul(a:u8, b:u8) u8 {
    return a * b;
}

test "Accumulator" {
    var A = [_]u8{1, 2, 4};
    var ans1 = [_]u8{1, 3, 7};
    var ans2 = [_]u8{0, 0, 0};
    var ans3 = [_]u8{1, 2, 8};

    var res = accumulator(tallocator, add, &A, 0);
    defer res.deinit();

    var res2 = accumulator(tallocator, mul, &A, 0);
    defer res2.deinit();

    var res3 = accumulator(tallocator, mul, &A, 1);
    defer res3.deinit();

    printTest(u8, &res, &ans1);
    printTest(u8, &res2, &ans2);
    printTest(u8, &res3, &ans3);

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