#!/usr/bin/env python3
"""Materialize an exact Git commit tree for filesystem secret scanners."""

import hashlib
import os
from pathlib import Path, PurePosixPath
import subprocess
import sys
import tarfile


def git(*args):
    return subprocess.check_output(["git", *args])


def main(sha, target):
    if git("rev-parse", "--verify", "HEAD").decode().strip() != sha:
        raise ValueError("checkout does not match the event commit")
    wanted = {}
    for entry in git("ls-tree", "-rz", sha).split(b"\0"):
        if not entry:
            continue
        metadata, name = entry.split(b"\t", 1)
        mode, kind, oid = metadata.split()
        path = PurePosixPath(os.fsdecode(name))
        if (
            mode not in (b"100644", b"100755")
            or kind != b"blob"
            or path.is_absolute()
            or ".." in path.parts
            or path.as_posix() != os.fsdecode(name)
        ):
            raise ValueError("unsupported or unsafe tracked tree entry")
        wanted[path] = oid.decode("ascii")
    if not wanted:
        raise ValueError("checkout tree is empty")

    algorithm = git("rev-parse", "--show-object-format").decode().strip()
    target = Path(target)
    if any(target.iterdir()):
        raise ValueError("scan directory must be empty")

    # Verify every member against Git's tree before writing it. A missing file,
    # export-ignore, export-subst, or filter cannot silently alter coverage.
    with subprocess.Popen(
        ["git", "archive", "--format=tar", sha], stdout=subprocess.PIPE
    ) as proc:
        with tarfile.open(fileobj=proc.stdout, mode="r|") as archive:
            for item in archive:
                if item.isdir():
                    continue
                path = PurePosixPath(item.name)
                if not item.isfile() or path not in wanted:
                    raise ValueError("archive has an unexpected tracked entry")
                stream = archive.extractfile(item)
                if stream is None:
                    raise ValueError("archive member could not be read")
                data = stream.read()
                digest = hashlib.new(algorithm)
                digest.update(f"blob {len(data)}\0".encode("ascii"))
                digest.update(data)
                if digest.hexdigest() != wanted.pop(path):
                    raise ValueError("archive member differs from its Git blob")
                output = target.joinpath(*path.parts)
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_bytes(data)
        if proc.wait() != 0:
            raise ValueError("git archive failed")
    if wanted:
        raise ValueError("archive omitted tracked entries")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: export-ci-scan-tree.py EVENT_SHA EMPTY_DIRECTORY")
    try:
        main(*sys.argv[1:])
    except (OSError, ValueError, subprocess.CalledProcessError, tarfile.TarError):
        sys.exit("could not materialize the event commit's exact tracked tree")
