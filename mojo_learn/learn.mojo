from mojo_learn.functional.option import Option

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