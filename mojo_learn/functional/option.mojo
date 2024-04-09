from utils.variant import Variant

alias CE = CollectionElement

# Ideally, there would be a trait Functor, that has a method `map` and Option would implememt
# it.  But mojo's traits don't support parameters yet
trait Functor:
    fn map[T: CE, R: AnyType](self, f: fn(T) -> R) -> Self: ...

@value
struct Option[T: CE]:
    var data: Variant[T, NoneType]

    fn map[R: CE](
        self,
        f: fn(T) -> R
    ) -> Option[R]:
        """Applies self.data to an fn that returns an R returning an Option[R].
        
        If self.data is None, then the Option[R] will also take on the None variant.  Otherwise, it will apply the T
        value from self.data and apply to f.
        """
        if self.data.isa[NoneType]():
            return Option[R](None)
        else:
            var r = f(self.data.take[T]())
            return Option[R](r)

    fn map(inout self, f: fn(T) -> T) -> Self:
        """More efficient map, when we map over the same type.
        
        Does not require allocating a new Option, since we can reuse self.data. 
        """
        if self.data.isa[T]():
            self.data = f(self.data.take[T]())
        return self

    fn flat_map[R: CE](
        self, 
        f: fn(T) -> Option[R]
    ) -> Option[R]:
        if self.data.isa[NoneType]():
            return Option[R](None)
        return f(self.data.take[T]())

    fn flat_map(inout self, f: fn(T) -> Self) -> Self:
        if self.data.isa[T]():
            self.data = f(self.data.take[T]())
        return self

    fn chain[R: CE](
        self, 
        f: fn(Option[T]) -> Option[R]
    ) -> Option[R]:
        """Applies self.data to a fn that can take an Option[T] and return Option[R]."""
        return f(self)

    fn do(self, f: fn(T) -> None) -> Option[T]:
        """Applies self.data a fn that performs side effect and returns self."""
        if self.data.isa[T]():
            f(self.data.take[T]())
        else:
            print("None")
        return self

    fn unwrap(self) raises -> T:
        if self.data.isa[NoneType]():
            raise Error("Data was None")
        else:
            return self.data.take[T]()