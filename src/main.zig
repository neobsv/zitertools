const std = @import("std");
const mem = std.mem;
const tallocator = std.testing.allocator;
const warn = std.debug.warn;
const assertEqual = std.testing.expectEqual;

pub fn reduce(
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.return_type.? 
) @typeInfo(@TypeOf(func)).Fn.return_type.? {
    var ans = init;
    for (iterable) | item | {
        ans = func(ans, item);
    }
    return ans;
}

fn add8(a: u8, b: u8) u8 { 
    return a + b; 
}
fn mul8(a: u8, b: u8) u8 { 
    return a * b; 
}

pub fn FunctionalIterator(comptime T: type) type {
    return struct {
        allocator: *std.mem.Allocator,
        items: []const T,
        index: usize = 0,
        len: usize,

        const Self = @This();

        fn incr(it: *Self) void {
            it.index += 1;
        }

        pub fn next(it: *Self) ?*const T {
            if(it.index < it.len) {
                defer it.incr();
                return &it.items[it.index];
            }
            return null;
        }

        pub fn init(alloc: *std.mem.Allocator, iter: []const T) Self {
            const temp: []T = alloc.dupe(T, iter) catch unreachable;
            return Self{
                .allocator = alloc,
                .items = temp,
                .len = iter.len
            };
        }

        pub fn deinit(it: *Self) void {
            it.allocator.free(it.items);
        }
    };
}

fn printTest(comptime T: type, iter: *FunctionalIterator(T), ans: []T) void{
    var i: usize = 0;
    while (iter.next()) | item | {
        //warn("\r\n ans: {} item: {} ", .{ans[i], item.*});
        //warn("{} \n", .{item.*});
        assertEqual(ans[i], item.*);
        i += 1;
    }
}

pub fn map(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    for(iterable) | item, i | {
        ans[i] =  func(item);
    }

    return FunctionalIterator(rtype).init(allocat, ans);
}

fn addOne(a: u8) u8 {
    return a + @intCast(u8, 1);
}

pub fn filter(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    var j: usize = 0;
    for (iterable) | item | {
        if (func(item) == true) {
            ans[j] = item;
            j += 1;
        }
    }

    _ = allocat.shrink(ans, j);
    ans.len = j;

    return FunctionalIterator(rtype).init(allocat, ans);
}

fn isLessThan10(a: u8) bool {
    if ( a < 10 ){
        return true;
    }
    return false;
}

pub fn accumulate(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    comptime init: @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.return_type.?) {
    const rtype = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    var ans: []rtype  = allocat.alloc(rtype, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    var i: usize = 0;
    ans[0] = func(init, iterable[0]);
    i += 1;
    while (i < iterable.len) : ( i += 1 ) {
        ans[i] =  func(ans[i-1], iterable[i]);
    }

    return FunctionalIterator(rtype).init(allocat, ans);
}

fn add(a: u32, b:u32) u32 {
    return a + b;
}

fn mul(a:u32, b:u32) u32 {
    return a * b;
}

pub fn chain(
    allocat: *std.mem.Allocator,
    comptime func: anytype,
    iterables: []const []const @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.return_type.?) {
    var totalLength: usize = 0;
    for (iterables) | iterable | { totalLength += iterable.len; }
    const rtype = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    var ans: []rtype  = allocat.alloc(rtype, totalLength) catch unreachable;
    defer allocat.destroy(ans.ptr);

    var index: usize = 0;
    for (iterables) | iterable | {
        for (iterable) | item | {
            ans[index] = func(item);
            index += 1; 
        }
    }
    return FunctionalIterator(rtype).init(allocat, ans);
}

fn addOne8(a: i32) i32 {
    return a+1;
}

pub fn min(
    allocat: *std.mem.Allocator,
    comptime func: anytype,
    iterables: []const []const @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.? {
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;

    var min_value: rtype = iterables[0][0];
    for (iterables) | iterable | {
        for (iterable) | item | {
            if ( func(item, min_value) == true ) {
                min_value = item;
            }
        }
    }
    return min_value;
}

fn compareFnMin(a: i32, b: i32) bool {
    if (a < b) {
        return true;
    }
    return false;
}

pub fn max(
    allocat: *std.mem.Allocator,
    comptime func: anytype,
    iterables: []const []const @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.? {
    return min(allocat, func, iterables);
}

fn compareFnMax(a: i32, b: i32) bool {
    if (a > b) {
        return true;
    }
    return false;
}

pub fn filterfalse(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, iterable.len) catch unreachable;
    defer allocat.destroy(ans.ptr);
    
    var j: usize = 0;
    for (iterable) | item, i | {
        if (func(item) == false) {
            ans[j] = item;
            j += 1;
        }
    }

    _ = allocat.shrink(ans, j);
    ans.len = j;

    return FunctionalIterator(rtype).init(allocat, ans);
}

pub fn dropwhile(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    var totalLength: usize = iterable.len;
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, totalLength) catch unreachable;
    defer allocat.destroy(ans.ptr);

    var i: usize = 0;
    while ( func(iterable[i]) == true ) : ( i += 1 ) {}

    var j: usize = 0;
    while ( i < totalLength ) : ({ j += 1; i += 1; }) {
        ans[j] = iterable[i];
    }

    _ = allocat.shrink(ans, j);
    ans.len = j;

    return FunctionalIterator(rtype).init(allocat, ans);
}

pub fn takewhile(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    var totalLength: usize = iterable.len;
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, totalLength) catch unreachable;
    defer allocat.destroy(ans.ptr);

    var i: usize = 0;
    while ( func(iterable[i]) == true ) : ( i += 1 ) {
        ans[i] = iterable[i];
    }

    _ = allocat.shrink(ans, i);
    ans.len = i;

    return FunctionalIterator(rtype).init(allocat, ans);
}

fn recurranceRelation(N: usize) !usize {
    switch (N) {
        0 => { return 1;  },
        1 => { return 2;  },
        2 => { return 4;  },
        3 => { return 12; },
        4 => { return 32; },
        5 => { return 80; },
        else => {}
    }
    var T: usize = 80;
    if ( N > 5 ) {
        var i: usize = 6;
        while (i < N+1) : ( i += 1 ) {
            T = (2 * i * T) / (i-1);
        }
    }
    return T;
}

pub fn powerset(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) !FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    // Total number of sets is pow(2, iterable.len)
    // the total number of elements can be calculated by (N*1) + ((N-1)*2) + ((N-2)*3) ... + (2*(N-1)) + (1*N)
    // this is given by the recurrance relation T(N) = 2*N*T(N-1)//(N-1) => should be the allocated length
    // a func needs to be constructed to get the result of the above recurrance relation.
    // Source: the recurrance relation is mine, and the powerset algorithm is from MITx: 6.00.2x
    const totalLength: usize =  @intCast(usize, 1) << @truncate(std.math.Log2Int(usize), iterable.len);
    const allocatLength: usize = recurranceRelation(iterable.len) catch unreachable;
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, allocatLength) catch unreachable;
    defer allocat.free(ans);

    var index: usize = 0;
    var i: usize = 0;
    while( i < totalLength ) : ( i += 1 ) {
        var j: usize = 0;
        while ( j < iterable.len ) : ( j += 1 ) {
            // Bit shift counter i of the array j bits to the right, this makes the 
            // last bit of i become the test bit to see if the index should be incl.
            if ( ( ( i >> @truncate(std.math.Log2Int(usize), j) ) % 2 ) == 1 ) {
                ans[index] = func(iterable[j]);
                index += 1;
            }
        }
    }

    return FunctionalIterator(rtype).init(allocat, ans);

}

fn mulOne32 (a: u32) u32 {
    return a * 1;
}

fn fact(N: u128) u128 {
    switch (N) {
        0 => { return 1; },
        1 => { return 1; },
        else => {}
    }

    var T: u128 = 1;
    var i: u128 = 2;

    while( i < N+1 ) : ( i += 1 ) {
        T = T * i;
    }
    return T;
}

pub fn permutations_lex(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) !FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    // There are N! possible permutations of a set of cardinality N
    // The number of elements of N! such sets is N! * N => should be allocated for the result
    const N: usize =  iterable.len;
    const allocatLength: usize = @intCast(usize, fact(N) * N);
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, allocatLength) catch unreachable;
    defer allocat.free(ans);

    var index: usize = 0;
    for (iterable) | item | {
        ans[index] = func(item);
        index += 1;
    }

    
    var c: u128 = 0;
    var numSets: u128 = fact(N) - 1;

    while ( c < numSets ) : ( c += 1 ) {
        var i: usize = N - 2;
        var j: usize = N - 1;

        while ( iterable[i] > iterable[i+1] ) : ( i -= 1 ) {}
        while ( iterable[j] < iterable[i] ) : ( j -= 1 ) {}

        mem.swap(rtype, &iterable[i], &iterable[j]);

        i += 1;
        j = N - 1;

        while ( i < j ) : ({ i += 1; j -= 1; }) {
            mem.swap(rtype, &iterable[i], &iterable[j]);
        }

        for (iterable) | item | {
            ans[index] = func(item);
            index += 1;
        }
    }

    return FunctionalIterator(rtype).init(allocat, ans);

}

pub fn permutations(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?
) !FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    // There are N! possible permutations of a set of cardinality N
    // The number of elements of N! such sets is N! * N => should be allocated for the result
    const N: usize =  iterable.len;
    const allocatLength: usize = @intCast(usize, fact(N) * N);
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, allocatLength) catch unreachable;
    defer allocat.free(ans);

    var c: []usize = allocat.alloc(usize, N) catch unreachable;
    defer allocat.free(c);

    var i: usize = 0;
    var index: usize = 0;
    for (iterable) | item, x | {
        c[x] = 0;
        ans[index] = func(item);
        index += 1;
    }

    while ( i < N ) {

        if (c[i] < i) {
            if ( (i%2) == 0 ) {
                mem.swap(rtype, &iterable[0], &iterable[i]);
            } else {
                mem.swap(rtype, &iterable[c[i]], &iterable[i]);
            }

            for (iterable) | item | {
                ans[index] = func(item);
                index += 1;
            }

            c[i] += 1;
            i = 0;

        } else {
            c[i] = 0;
            i += 1;
        }

    }

    return FunctionalIterator(rtype).init(allocat, ans);

}

fn mulOne1 (a: u1) u1 {
    return a * 1;
}

pub fn combinations(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    choose: usize
) !FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    // Did not find a good answer to this problem.
    // Will be using permutation for this, and making a bit array of size iter.len (n)
    // Out of this we can set k bits to simulate n choose k, and generate all permutations
    // of the same to get the k-combination set of the iterable.

    // There will be nCk sets of k elements each, so the total memory that needs to be allocated
    // is nCk * k for all the elements. allocatLength = ( fact(N) / (fact(k) * fact(N-k)) ) * k

    const N: usize =  iterable.len;
    const k: usize = choose;
    const allocatLength: usize = @intCast(usize, ( fact(N) / (fact(k) * fact(N-k)) ) * k);
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, allocatLength) catch unreachable;
    defer allocat.free(ans);

    var c: []u1 = allocat.alloc(u1, N) catch unreachable;
    defer allocat.free(c);

    var i: usize = 0;
    while ( i < N ) : ( i += 1 ) {
        if ( i < k ) {
            c[i] = 1;
        } else {
            c[i] = 0;
        }
    }

    // Taking a bit array of n and choosing k bits, and getting all permutations
    // of such a configuration. We will use this to generate the k-combination set of the iterable.
    var res = permutations(allocat, mulOne1, c) catch unreachable;
    defer res.deinit();

    var bufset = std.StringHashMap(void).init(allocat);
    defer bufset.deinit();
    var buffer = std.ArrayList(u8).init(allocat);
    defer buffer.deinit();
    try buffer.ensureCapacity(N);
    
    i = 0;
    while ( res.next() ) | item | {
        if ( (i != 0) and (i % N) == 0 ) {
            if ( ! bufset.contains(buffer.items) ) {
                try bufset.put( buffer.toOwnedSlice(), .{} );
                try buffer.ensureCapacity(N);
            } else {
                buffer.shrinkRetainingCapacity(0);
            }
        }
        buffer.appendAssumeCapacity( @as(u8, (0x00|item.*) ) );
        i += 1;
    }
    

    i = 0;
    var j: usize = 0;
    var bit: u8 = 0x01;
    var index: usize = 0;
    var it = bufset.iterator();
    while ( it.next() ) | buf | {
        j = 0;
        while ( j < N ) {
            if ( (bit & buf.key[j]) >= 1 ) {
                ans[index] = func(iterable[j]);
                // warn(" {},", .{ans[index]});
                index += 1;
            }
            j += 1;
        }
        i += 1;
    }

    return FunctionalIterator(rtype).init(allocat, ans);

}

pub fn compress(
    allocat: *std.mem.Allocator,
    comptime func: anytype, 
    iterable: []@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?,
    selectors: []u1
) FunctionalIterator(@typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?) {
    const N: usize =  iterable.len;
    const rtype = @typeInfo(@TypeOf(func)).Fn.args[0].arg_type.?;
    var ans: []rtype  = allocat.alloc(rtype, N) catch unreachable;
    defer allocat.destroy(ans.ptr);

    var i: usize = 0;
    var index: usize = 0;
    while ( i < N ) : ( i += 1 ) {
        if (selectors[i] == 1) {
            ans[index] = func(iterable[i]);
            index += 1;
        }
    }

    _ = allocat.shrink(ans, index);
    ans.len = index;

    return FunctionalIterator(rtype).init(allocat, ans);
}

pub fn product(
    allocat: *std.mem.Allocator,
    comptime T: type,
    iterables: []const []const T
) !FunctionalIterator(T) {
    // My own, novel solution to generate the cartesian product of the iterables.
    // The total memeory required for this is the product of the length of each iterable
    // and the total number of iterables.
    const N: usize = iterables.len;
    var totalLength: usize = 1;
    var indices = std.ArrayList(usize).init(allocat);
    defer indices.deinit();

    for (iterables) | iterable | { 
        totalLength *= iterable.len;
        _ = try indices.append(0);
    }
    var ans: []T  = allocat.alloc(T, totalLength*N) catch unreachable;
    defer allocat.destroy(ans.ptr);

    var i: usize = 0;
    var j: usize = 0;
    var k: usize = N - 1;
    var flag: u1 = 1;
    var index: usize = 0;
    while( i < totalLength ) : ( i += 1 ) {
        j = 0;
        while ( j < N ) : ( j += 1 ) {
            ans[index] = iterables[j][indices.items[j]];
            index += 1;
        }

        k = N - 1;
        flag = 1;
        while ( k >= 0 and flag > 0 ) {
            indices.items[k] = (indices.items[k]+1) % iterables[k].len;
            if ( indices.items[k] != 0 ) {
                flag = 0;    
            }
            if ( k > 0 ) { 
                k -= 1; 
            }
        }

    }

    return FunctionalIterator(T).init(allocat, ans);
}


test "Reduce" {
    var A = [_]u8{1, 2, 4};
    assertEqual(reduce(add8, &A, 0), 7);
    assertEqual(reduce(mul8, &A, 0), 0);
    assertEqual(reduce(mul8, &A, 1), 8);
    warn("\r\n", .{});
}

test "FunctionalIterator" {

    var A: []u8 = tallocator.alloc(u8, 10) catch unreachable;
    defer tallocator.destroy(A.ptr);

    var i: u8 = 0;
    while ( i < 10 ) : ( i += 1 ) {
        A[i] = i;
    } 
    var iter = FunctionalIterator(u8).init(tallocator, A);
    defer iter.deinit();

    printTest(u8, &iter, A);

    var B = std.ArrayList(u8).init(tallocator);
    defer B.deinit();

    i =  0;
    while ( i < 10 ) : ( i += 1 ) {
        _ = try B.append(i*2);
    } 
    var iter2 = FunctionalIterator(u8).init(tallocator, B.items);
    defer iter2.deinit();

    printTest(u8, &iter2, B.items);
    warn("\r\n", .{});

}

test "Map" {
    var A = [_]u8{'a', 'b', 'c'};
    var ans = [_]u8{'b', 'c', 'd'};

    var res = map(tallocator, addOne, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "Filter" {
    var A = [_]u8{1, 'a', 2, 'b', 3, 'c', 'd', 'e'};
    var ans = [_]u8{1, 2, 3};

    var res = filter(tallocator, isLessThan10, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "Accumulate" {
    var A = [_]u32{1, 2, 4};
    var ans1 = [_]u32{1, 3, 7};
    var ans2 = [_]u32{0, 0, 0};
    var ans3 = [_]u32{1, 2, 8};

    var res = accumulate(tallocator, add, &A, 0);
    defer res.deinit();

    var res2 = accumulate(tallocator, mul, &A, 0);
    defer res2.deinit();

    var res3 = accumulate(tallocator, mul, &A, 1);
    defer res3.deinit();

    printTest(u32, &res, &ans1);
    printTest(u32, &res2, &ans2);
    printTest(u32, &res3, &ans3);
    warn("\r\n", .{});
}

test "Chain" {
    var A = &[_][]const i32{ 
        &[_]i32{1, 2}, 
        &[_]i32{3, 4}
    };

    var ans = [_]i32{2,3,4,5};
    var res = chain(tallocator, addOne8, A);
    defer res.deinit();

    printTest(i32, &res, &ans);

    warn("\r\n", .{});
}

test "Min" {
    var A = &[_][]const i32{ 
        &[_]i32{1, 2}, 
        &[_]i32{3, 4}
    };
    assertEqual(min(tallocator, compareFnMin, A), 1);
    warn("\r\n", .{});
}

test "Max" {
    var A = &[_][]const i32{ 
        &[_]i32{1, 2}, 
        &[_]i32{3, 4}
    };
    assertEqual(max(tallocator, compareFnMax, A), 4);
    warn("\r\n", .{});
}

test "FilterFalse" {
    var A = [_]u8{1, 'a', 2, 'b', 3, 'c', 'd', 'e'};
    var ans = [_]u8{'a', 'b', 'c', 'd', 'e'};

    var res = filterfalse(tallocator, isLessThan10, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "Dropwhile" {
    var A = [_]u8{1, 2, 3, 5, 'a', 1, 'b', 2, 'c', 11, 'd', 'e', 1, 3, 4};
    var ans = [_]u8{'a', 1, 'b', 2, 'c', 11, 'd', 'e', 1, 3, 4};

    var res = dropwhile(tallocator, isLessThan10, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "Takewhile" {
    var A = [_]u8{1, 2, 3, 5, 'a', 1, 'b', 2, 'c', 11, 'd', 'e', 1, 3, 4};
    var ans = [_]u8{1, 2, 3, 5};

    var res = takewhile(tallocator, isLessThan10, &A);
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}

test "PowerSet" {
    var A = [_]u32{1, 2, 3, 4};
    var ans = [_]u32{1, 2, 1, 2, 3, 1, 3, 2, 3, 1, 2, 3, 4, 1, 4, 2, 4, 1, 2, 4, 3, 4, 1, 3, 4, 2, 3, 4, 1, 2, 3, 4};

    var res = powerset(tallocator, mulOne32, &A) catch unreachable;
    defer res.deinit();

    printTest(u32, &res, &ans);

    var A1 = [_]u32{1, 2, 3};
    var ans1 = [_]u32{1, 2, 1, 2, 3, 1, 3, 2, 3, 1, 2, 3};

    var res1 = powerset(tallocator, mulOne32, &A1) catch unreachable;
    defer res1.deinit();

    printTest(u32, &res1, &ans1);

    var A2 = [_]u32{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};

    var res2 = powerset(tallocator, mulOne32, &A2) catch unreachable;
    defer res2.deinit();

    const allocLength: usize = recurranceRelation(A2.len) catch unreachable;
    assertEqual(res2.len, allocLength);

    warn("\r\n", .{});
}

test "Permutations" {
    var ans: u128 = fact(3);
    assertEqual(ans, 6);
    

    var A = [_]u32{1, 2, 3};
    var ans1 = [_]u32{1, 2, 3, 1, 3, 2, 2, 1, 3, 2, 3, 1, 3, 1, 2, 3, 2, 1};

    var res = permutations_lex(tallocator, mulOne32, &A) catch unreachable;
    defer res.deinit();

    printTest(u32, &res, &ans1);

    var A2 = [_]u32{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    var res1 = permutations(tallocator, mulOne32, &A2) catch unreachable;
    defer res1.deinit();

   // printTest(u32, &res, &ans1);

    warn("\r\n", .{});
}

test "Combinations" {
    var ans: u128 = fact(3);
    assertEqual(ans, 6);
    
    var A = [_]u32{1, 2, 3, 4};
    var ans1 = [_]u32{2, 4, 1, 3, 1, 4, 1, 2, 2, 3, 3, 4};

    var res = combinations(tallocator, mulOne32, &A, 2) catch unreachable;
    defer res.deinit();

    printTest(u32, &res, &ans1);
    warn("\r\n", .{});
}

test "Compress" {
    var A = [_]u32{1, 2, 3, 4, 5, 6, 7, 8};
    var selectors = [_]u1{0, 1, 1, 1, 1, 0, 0, 0};
    var ans = [_]u32{2,3,4,5};

    var res = compress(tallocator, mulOne32, &A, &selectors);
    defer res.deinit();

    printTest(u32, &res, &ans);
    warn("\r\n", .{});
}

test "Cartesian Product" {
    var A = &[_][]const u8{ 
        &[_]u8{'a', 'b', 'c'},
        &[_]u8{'x', 'y'},
        &[_]u8{'d', 'e', 'f', 'l', 'm'},
        &[_]u8{'t', 'v', 'r'}
    };

    var ans = [_]u8{'a',  'x',  'd',  't',  'a',  'x',  'd',  'v',  'a',  'x',  'd',  'r',  'a',  'x',  'e',  't',  'a',  'x',  'e',  'v',  'a',  'x',  'e',  'r',  'a',  'x',  'f',  't',  'a',  'x',  'f',  'v',  'a',  'x',  'f',  'r',  'a',  'x',  'l',  't',  'a',  'x',  'l',  'v',  'a',  'x',  'l',  'r',  'a',  'x',  'm',  't',  'a',  'x',  'm',  'v',  'a',  'x',  'm',  'r',  'a',  'y',  'd',  't',  'a',  'y',  'd',  'v',  'a',  'y',  'd',  'r',  'a',  'y',  'e',  't',  'a',  'y',  'e',  'v',  'a',  'y',  'e',  'r',  'a',  'y',  'f',  't',  'a',  'y',  'f',  'v',  'a',  'y',  'f',  'r',  'a',  'y',  'l',  't',  'a',  'y',  'l',  'v',  'a',  'y',  'l',  'r',  'a',  'y',  'm',  't',  'a',  'y',  'm',  'v',  'a',  'y',  'm',  'r',  'b',  'x',  'd',  't',  'b',  'x',  'd',  'v',  'b',  'x',  'd',  'r',  'b',  'x',  'e',  't',  'b',  'x',  'e',  'v',  'b',  'x',  'e',  'r',  'b',  'x',  'f',  't',  'b',  'x',  'f',  'v',  'b',  'x',  'f',  'r',  'b',  'x',  'l',  't',  'b',  'x',  'l',  'v',  'b',  'x',  'l',  'r',  'b',  'x',  'm',  't',  'b',  'x',  'm',  'v',  'b',  'x',  'm',  'r',  'b',  'y',  'd',  't',  'b',  'y',  'd',  'v',  'b',  'y',  'd',  'r',  'b',  'y',  'e',  't',  'b',  'y',  'e',  'v',  'b',  'y',  'e',  'r',  'b',  'y',  'f',  't',  'b',  'y',  'f',  'v',  'b',  'y',  'f',  'r',  'b',  'y',  'l',  't',  'b',  'y',  'l',  'v',  'b',  'y',  'l',  'r',  'b',  'y',  'm',  't',  'b',  'y',  'm',  'v',  'b',  'y',  'm',  'r',  'c',  'x',  'd',  't',  'c',  'x',  'd',  'v',  'c',  'x',  'd',  'r',  'c',  'x',  'e',  't',  'c',  'x',  'e',  'v',  'c',  'x',  'e',  'r',  'c',  'x',  'f',  't',  'c',  'x',  'f',  'v',  'c',  'x',  'f',  'r',  'c',  'x',  'l',  't',  'c',  'x',  'l',  'v',  'c',  'x',  'l',  'r',  'c',  'x',  'm',  't',  'c',  'x',  'm',  'v',  'c',  'x',  'm',  'r',  'c',  'y',  'd',  't',  'c',  'y',  'd',  'v',  'c',  'y',  'd',  'r',  'c',  'y',  'e',  't',  'c',  'y',  'e',  'v',  'c',  'y',  'e',  'r',  'c',  'y',  'f',  't',  'c',  'y',  'f',  'v',  'c',  'y',  'f',  'r',  'c',  'y',  'l',  't',  'c',  'y',  'l',  'v',  'c',  'y',  'l',  'r',  'c',  'y',  'm',  't',  'c',  'y',  'm',  'v',  'c',  'y',  'm',  'r'};
    var res = product(tallocator, u8, A) catch unreachable;
    defer res.deinit();

    printTest(u8, &res, &ans);
    warn("\r\n", .{});
}


pub fn main() !void {
    var A2 = [_]u32{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15};
    var res1 = permutation(tallocator, mulOne32, &A2) catch unreachable;
    defer res1.deinit();
    warn("\r\n", .{});
    return;
}
