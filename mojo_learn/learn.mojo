from utils.variant import Variant

alias CE = CollectionElement

# Ideally, there would be a trait Functor, that has a method `map` and Option would implememt
# it.  But mojo's traits don't support parameters yet
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
        
        Does not require creating a new Option, since we can reuse self.data
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

@value 
struct Character(Stringable):
    var strength: Int
    var agility: Int
    var intelligence: Int
    var insight: Int

    fn __str__(self) -> String:
        var sb = "strength = " + str(self.strength)
        sb += "\nagility = " + str(self.agility)
        sb += "\nintelligence = " + str(self.intelligence)
        sb += "\ninsight = " + str(self.insight)
        return sb

struct Characters:
    var count: Int
    var used: Int
    var chars: AnyPointer[Character]

    fn __init__(inout self):
        self.used = 0
        self.count = 0
        self.chars = AnyPointer[Character]()

    fn __init__(inout self, count: Int):
        self.used = 0
        self.count = count
        self.chars = AnyPointer[Character].alloc(count)

    fn __del__(owned self):
        self.chars.free()

    fn add_character(inout self, char: Character):
        if self.used == self.count:
            print("Unable to add.  resize the buffer")
            return
        
        self.chars[self.used] = char
        self.used += 1

    fn get_character(inout self) -> Option[Character]:
        if self.used == 0:
            return Option[Character](None)
        
        self.used -= 1
        var ch = self.chars[self.used]
        return Option[Character](ch)


fn main() raises:
    var ch1 = Character(10, 12, 11, 14)
    var ch2 = Character(13, 9, 12, 11)
    var characters = Characters(4)
    characters.add_character(ch1)
    characters.add_character(ch2)

    var ch_1 = characters.get_character()

    fn pr(c: Character):
        print(c)

    fn add_to_agi(c: Character) -> Character:
        var copy = c
        copy.agility += 1
        return copy

    var u = ch_1.do(pr)
    u = characters.get_character().map(add_to_agi).do(pr)