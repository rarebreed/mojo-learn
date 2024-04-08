
from python import Python

fn imp(name: StringRef) raises -> PythonObject:
    var mod = Python.import_module(name)
    return mod

def main():
    bns = imp("builtins")
    daak = imp("daak._process")
    
    aio = imp("asyncio")
    cmd = daak.Run("ls -al").run()
    aio.run(cmd)
