import os, re, sys

gen_bp = "vendor/xiaomi/myron/Android.bp"
skip_dirs = {".repo", "out", "vendor/xiaomi/myron"}
search_dirs = ["hardware", "vendor", "system", "device", "external", "packages", "frameworks"]

# Find all generated modules
generated = set()
with open(gen_bp) as f:
    for line in f:
        m = re.search(r'name:\s*"([^"]+)"', line)
        if m: generated.add(m.group(1))

print(f"Loaded {len(generated)} generated modules.")

found_overlaps = set()

mod_re = re.compile(r'(?:name:\s*"([^"]+)")|(?:LOCAL_MODULE\s*:=\s*([^\s]+))|(?:LOCAL_PACKAGE_NAME\s*:=\s*([^\s]+))')

for sdir in search_dirs:
    for root, dirs, files in os.walk(sdir):
        # Prune dirs
        dirs[:] = [d for d in dirs if not os.path.join(root, d) in skip_dirs and not d.startswith(".")]
        for file in files:
            if file == "Android.bp" or file == "Android.mk":
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', errors='ignore') as f:
                        for line in f:
                            for match in mod_re.finditer(line):
                                name = match.group(1) or match.group(2) or match.group(3)
                                if name in generated:
                                    found_overlaps.add(name)
                                    # print(f"Overlap found: {name} in {path}")
                except Exception as e:
                    pass

print("\n--- OVERLAPS ---")
for o in sorted(found_overlaps):
    print(o)
