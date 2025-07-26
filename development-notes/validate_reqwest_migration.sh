#!/run/current-system/sw/bin/bash

echo "=== Validating reqwest migration ==="

SOURCE_DIR="/home/connerohnesorge/Documents/001Repos/clewdr-flake/clewdr-source/src"

echo "Checking for any remaining wreq references..."
if grep -r "wreq::" "$SOURCE_DIR" 2>/dev/null; then
    echo "❌ Found remaining wreq:: references"
else
    echo "✅ No wreq:: references found"
fi

echo "Checking for problematic method calls..."
if grep -r "\.set_cookie\|\.header_append" "$SOURCE_DIR" 2>/dev/null; then
    echo "❌ Found problematic method calls"
else
    echo "✅ No problematic method calls found"
fi

echo "Checking proxy usage..."
if grep -r "\.proxy(" "$SOURCE_DIR" | grep -v "reqwest::Proxy\|Option<Proxy>" >/dev/null 2>&1; then
    echo "⚠️  Check proxy usage manually"
    grep -r "\.proxy(" "$SOURCE_DIR"
else
    echo "✅ Proxy usage looks correct"
fi

echo "Validation complete!"
