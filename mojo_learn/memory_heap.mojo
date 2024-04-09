from mojo_learn.data_structures.stack import MyStack

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
