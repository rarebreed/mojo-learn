from tensor import Tensor, TensorSpec, TensorShape

trait Reader:
    def read(self):
        ...

def main():
    alias type = DType.int64
    var spec = TensorSpec(type,5)
    var s = Tensor[type](spec)
    var t = Tensor[type](spec)
    var u = Tensor[type](spec)
    var slist = List(1,2,3,4,5)
    var tlist = List(2,3,5,7,11)
    for i in range(5):
        s[i] = slist[i]
        t[i] = tlist[i]
    # calls version of s.load -> load[width: Int](self: Self, index: Int) -> SIMD[dtype, width]
    # so s.load[5](0) will return 1
    # u.store will call store[width: Int](inout self: Self, index: Int, val: SIMD[dtype, width])
    # so u will end up with
    var v = s.load[width=5](0)
    u.store[5](0,s.load[5](0))
    print(u)


struct Foo:
    fn blast(self, x: Int) -> Int:
        return x * 2

