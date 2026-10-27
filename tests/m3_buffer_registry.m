// Regression: large scenes must not silently lose buffer bindings after entry 1024.
#import <Metal/Metal.h>
#include <assert.h>
#include <stdio.h>
#include "m3_compat.h"
int main(void) {
    @autoreleasepool {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) { fprintf(stderr, "Metal device unavailable\n"); return 77; }
        NSMutableArray *buffers = [NSMutableArray array];
        for (int i = 0; i < 1100; ++i) {
            id<MTLBuffer> buffer = [device newBufferWithLength:256 options:MTLResourceStorageModeShared];
            assert(buffer); [buffers addObject:buffer]; m3_buf_add(buffer);
        }
        for (id<MTLBuffer> buffer in buffers) {
            NSUInteger offset = 0;
            if (m3_buf(buffer.gpuAddress + 32, &offset) != buffer || offset != 32) {
                fprintf(stderr, "registered buffer could not be bound\n"); return 1;
            }
        }
        id<MTLBuffer> removed = buffers[550];
        m3_buf_del(removed);
        NSUInteger offset = 0;
        assert(m3_buf(removed.gpuAddress, &offset) == nil);
        m3_buf_add(removed);
        assert(m3_buf(removed.gpuAddress + 255, &offset) == removed && offset == 255);
        for (id<MTLBuffer> buffer in buffers) m3_buf_del(buffer);
        assert(m3_buf(removed.gpuAddress, &offset) == nil);
        puts("PASS: 1100 buffers, offsets, removal and re-registration");
    }
    return 0;
}
