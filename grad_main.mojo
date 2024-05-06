from mojo_learn.grad import F64Tens

fn main():
    var tens = F64Tens(2.0, 3.0, 4.0)
    var tens2 = tens + 10
    print(tens)
    print(tens2)

    var tens3 = tens2 * 5
    print(tens3)

    var tens4 = tens3 - 20
    print(tens4)

    fn func(x: Float64) -> Float64:
        return (x**3) + (2 * (x**2)) + 10
