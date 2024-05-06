from python import Python


trait Default:
    @staticmethod
    fn default() -> Self:
        ...


@value
struct MyPet:
    var name: String
    var age: Int

    fn __init__(inout self, name: String):
        self.name = name
        self.age = 7


fn imp(name: StringRef) raises -> PythonObject:
    var mod = Python.import_module(name)
    return mod


def main():
    bns = imp("builtins")
    daak = imp("daak._process")

    aio = imp("asyncio")
    cmd = daak.Run("ls -al").run()
    aio.run(cmd)

    var pet = MyPet("sam", 10)
    print(pet.age)
    
    var dt = imp("datetime")
    var now = dt.datetime.now()
    print(now)