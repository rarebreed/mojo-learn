from mojo_learn.learn.learn import Character, Characters

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
