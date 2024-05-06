from tensor import Tensor, TensorShape, TensorSpec


@register_passable
struct Tensor1d[dtype: DType, size: Int](Stringable):
    var reg: SIMD[dtype, size]

    fn __init__(inout self):
        self.reg = SIMD[dtype, size]()

    fn __init__(inout self, val: SIMD[dtype, 1]):
        self.reg = SIMD[dtype, size](val)

    fn __init__(inout self, *val: SIMD[dtype, 1]):
        self.reg = SIMD[dtype, size]()
        var idx = 0
        for i in range(len(val)):
            if idx < size:
                self.reg[i] = val[i]
            idx += 1

    fn __init__(inout self, reg: SIMD[dtype, size]):
        self.reg = reg

    fn __copyinit__(inout self, rhs: Self):
        self.reg = rhs.reg

    fn __add__(self, rhs: SIMD[dtype, 1]) -> Self:
        """Scalar add across elements."""
        var multiplier = SIMD[dtype, 1](1.0)
        var new = self.reg.fma(multiplier, rhs)
        return Self(new)

    fn __sub__(self, rhs: SIMD[dtype, 1]) -> Self:
        """Scalar add across elements."""
        var multiplier = SIMD[dtype, 1](1.0)
        var nrhs = rhs * -1
        var new = self.reg.fma(multiplier, nrhs)
        return Self(new)

    fn __mul__(self, rhs: SIMD[dtype, 1]) -> Self:
        var accum = SIMD[dtype, 1](0.0)
        var new = self.reg.fma(rhs, accum)
        return Self(new)

    fn __str__(self) -> String:
        return str(self.reg)


alias F64Tens = Tensor1d[DType.float64, 8]


fn derive(f: fn (F64Tens) -> F64Tens, inp: F64Tens, delta: Float64) -> F64Tens:
    """Calculates the derivative of a function."""
    var f1 = f(inp + delta)
    var f2 = f(inp - delta)
    var num = Tensor1d(f1.reg - f2.reg)
    var derivative = num.reg / delta
    return Tensor1d(derivative)

