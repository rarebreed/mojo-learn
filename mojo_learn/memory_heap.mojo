
from utils import Variant
from collections import Optional

trait CE(CollectionElement, Stringable): ...

@value
struct MyStack[T: CE]:
    var size: Int
    var idx: Int  # where to pop, push
    var ptr: AnyPointer[T]

    fn __init__(inout self, size: Int):
        self.size = size
        self.idx = 0
        self.ptr = AnyPointer[T].alloc(size)

    fn __del__(owned self):
        self.ptr.free()

    fn __copyinit__(inout self, rhs: MyStack[T]):
        self = MyStack[T](rhs.size)
        for i in range(rhs.idx):
            self.push(rhs.ptr[i])
        
    fn __moveinit__(inout self, owned rhs: MyStack[T]):
        self.size = rhs.size
        self.idx = rhs.idx
        self.ptr = rhs.ptr

    fn _reallocate(owned self) -> Self:
        var new_size = self.size * 2
        var ms = MyStack[T](new_size)
        for i in range(self.size):
            var d = self.ptr[i]
            ms.push(d)
        return ms

    fn push(inout self, data: T):
        if self.idx >= self.size:
            self = self._reallocate()
        self.ptr[self.idx] = data
        self.idx += 1

    fn pop(inout self) -> Optional[T]:
        if self.idx >= 0:
            var data = self.ptr[self.idx - 1]
            self.idx -= 1
            return Optional(data)
        else:
            return None

    # def __getitem__(self, idx: Int) -> Optional[Reference[String, ]]:
    #     """Return a Reference."""
    #     if idx < (self.idx - 1):
    #         var ref = Reference(self.ptr[idx])
    #         return 

fn main() raises:
    var ms = MyStack[String](2)
    print("Address of ms on the stack ", Pointer.address_of(ms))
    ms.push("hi")
    ms.push("Sean")
    ms.push("how are you?")
    for i in range(ms.idx):
        print(ms.ptr[i])

    print("Address of ms on the stack ", Pointer.address_of(ms))
    test_copy(ms)

fn test_copy(orig: MyStack[String]):
    # orig is an immutable 
    var copy_ms = orig
    print("Address of copy_ms on the stack ", Pointer.address_of(copy_ms))
    var last = copy_ms.pop()
    if last:
        print(last.value())
