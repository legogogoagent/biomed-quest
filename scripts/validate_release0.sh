#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ok=0
fail=0

pass() { echo "✅ $1"; ok=$((ok + 1)); }
fault() { echo "❌ $1"; fail=$((fail + 1)); }

check_file() {
  if [[ -f "$1" ]]; then pass "file $1"; else fault "missing file $1"; fi
}

check_contains() {
  if [[ -f "$1" ]] && grep -qF "$2" "$1"; then
    pass "$1 contains '$2'"
  else
    fault "$1 missing '$2'"
  fi
}

check_file "README.md"
check_file "MAP.md"
check_file "PROGRESS.md"
check_file ".gitignore"
check_file "_quarto.yml"
check_file "biomed-quest.Rproj"
check_file "data/README.md"
check_file "journal/ai-log.md"
check_file "00_setup/README.md"
check_file "00_setup/preview.qmd"
check_file "00_setup/verify_environment.R"
check_file "data-raw/generate_preview_data.R"
check_file "data/raw/preview_counts.csv"
check_file "data/raw/preview_metadata.csv"
check_file "R/preview_analysis.R"
check_file "01_overworld/level-01-hello/README.md"
check_file "01_overworld/level-01-hello/concepts.qmd"
check_file "01_overworld/level-01-hello/warmup.R"
check_file "01_overworld/level-01-hello/quest.R"
check_file "01_overworld/level-01-hello/check_level_01.R"
check_file "01_overworld/level-01-hello/journal.md"
check_file "01_overworld/level-01-hello/hello.qmd"
check_file "solutions/level-01-hello.R"
check_file "templates/quest-card.md"
check_file "templates/journal.md"
check_file "templates/ai-log.md"
check_file "templates/code-review.md"
check_file "templates/boss-report.md"
check_file "docs/README.md"

check_contains "README.md" "BiomedCraft"
check_contains "README.md" "世界地图"
check_contains "README.md" "成就墙"
check_contains "README.md" "快速开始"
check_contains "README.md" "Minecraft-inspired"
check_contains "MAP.md" "flowchart"
check_contains "MAP.md" "L12"
check_contains "PROGRESS.md" "2700"
check_contains "PROGRESS.md" "A13"
check_contains "01_overworld/level-01-hello/README.md" "5 句话"

badges=$(find assets/badges -maxdepth 1 -name '*.svg' | wc -l | tr -d ' ')
if [[ "$badges" -ge 6 ]]; then
  pass "at least 6 SVG badges ($badges)"
else
  fault "expected at least 6 SVG badges, found $badges"
fi

if grep -RIn --exclude-dir=.git --exclude-dir=renv --exclude='*.svg' "TBD" \
  README.md MAP.md PROGRESS.md 00_setup 01_overworld templates 2>/dev/null; then
  fault "found TBD placeholder"
else
  pass "no TBD placeholder in Release 0 content"
fi

if grep -RIn --exclude-dir=.git --exclude-dir=renv "/home/" \
  R 00_setup 01_overworld 2>/dev/null; then
  fault "found absolute /home/ path in R or Quarto content"
else
  pass "no absolute /home/ paths"
fi

echo
echo "Passed: $ok  Failed: $fail"
if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
echo "✅ Release 0 static validation passed"
