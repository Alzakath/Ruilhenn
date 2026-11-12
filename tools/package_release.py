"""Validate the Retail artifact and optionally write a TOC-driven ZIP. No dependencies."""
import argparse
from pathlib import Path, PurePosixPath
import zipfile


def artifact_files(root):
    toc = root / "Ruilhenn.toc"
    lines = toc.read_text(encoding="utf-8-sig").splitlines()
    interfaces = next(line.split(":", 1)[1] for line in lines if line.startswith("## Interface:"))
    assert "120105" in [value.strip() for value in interfaces.split(",")], "12.1.5 interface missing"
    scripts = [line.strip().replace("\\", "/") for line in lines if line.strip() and not line.lstrip().startswith("#")]
    assert len(scripts) == len(set(scripts)), "duplicate TOC file"
    assert scripts[0] == "Core.lua" and scripts[-1] == "Main.lua", "invalid entrypoint order"
    for before, after in [("ItemData.lua", "MacroManager.lua"), ("ItemData.lua", "ActionBarsManager.lua"),
                          ("TalentImport.lua", "TalentManager.lua"), ("Validation.lua", "Main.lua"),
                          ("l10n/enUS.lua", "l10n/frFR.lua"), ("l10n/frFR.lua", "MacroManager.lua")]:
        assert scripts.index(before) < scripts.index(after), f"{before} must load before {after}"
    assert any(line.startswith("## SavedVariables:") and "RuilhennDB" in line for line in lines)
    paths = ["Ruilhenn.toc", *scripts, "icon.tga", "Readme.md", "CHANGELOG.md"]
    for relative in paths:
        parts = PurePosixPath(relative).parts
        assert not relative.startswith("/") and ".." not in parts, f"unsafe artifact path: {relative}"
        current = root
        for part in parts:
            assert part in {p.name for p in current.iterdir()}, f"missing file or case mismatch: {relative}"
            current /= part
        assert current.is_file(), f"not a file: {relative}"
    return paths


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate without writing an artifact")
    parser.add_argument("--output", type=Path, default=Path("dist/Ruilhenn-retail-12.1.5.zip"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    paths = artifact_files(root)
    if args.check:
        print(f"Retail artifact validated: {len(paths)} files, interface 120105, load order and case OK")
        return
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative in paths:
            archive.write(root / relative, "Ruilhenn/" + relative)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None, "corrupt ZIP entry"
        assert set(archive.namelist()) == {"Ruilhenn/" + p for p in paths}
    print(f"Created and verified {output} ({len(paths)} files)")


if __name__ == "__main__":
    main()
