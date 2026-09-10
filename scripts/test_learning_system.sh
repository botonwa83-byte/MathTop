#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/mathtop-learning-system.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

xcrun --sdk macosx swiftc -module-cache-path "$test_dir/cache" \
    "$project_dir/MathTop/Models/LearningModels.swift" \
    "$project_dir/MathTop/Content/MathContent.swift" \
    "$project_dir/MathTop/Services/ReviewScheduler.swift" \
    "$project_dir/MathTop/Services/GrowthSummaryService.swift" \
    "$project_dir/MathTop/Services/DailyPlanService.swift" \
    "$project_dir/MathTop/Store/LearningStore.swift" \
    "$project_dir/scripts/test_learning_system.swift" \
    -o "$test_dir/test-learning-system"
"$test_dir/test-learning-system"
