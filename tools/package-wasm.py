import argparse
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory


def main():
    parser = argparse.ArgumentParser(description="Remove internal Wasm names from a distribution copy.")
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    source = args.source.resolve()
    destination = args.destination.absolute()
    if source == destination.resolve() or (destination.exists() and source.samefile(destination)):
        parser.error("source and destination must be different files")

    with TemporaryDirectory(dir=destination.parent) as directory:
        packaged = Path(directory) / destination.name
        subprocess.run([os.environ.get("LLVM_OBJCOPY", "llvm-objcopy"),
                        "--remove-section=name", str(source), str(packaged)], check=True)
        try:
            os.link(packaged, destination)
        except FileExistsError:
            parser.error("destination already exists; choose a new output path")


if __name__ == "__main__":
    main()
