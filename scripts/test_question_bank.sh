#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/mathtop-catalog.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT

xcrun --sdk macosx swiftc -module-cache-path "$test_dir/cache" \
    "$project_dir/MathTop/Models/LearningModels.swift" \
    "$project_dir/MathTop/Content/MathContent.swift" \
    "$project_dir/MathTop/Content/LessonPractice.swift" \
    "$project_dir/MathTop/Content/PracticeBankPrimary.swift" \
    "$project_dir/MathTop/Content/PracticeBankJunior.swift" \
    "$project_dir/scripts/test_question_bank.swift" \
    -o "$test_dir/test-question-bank"
"$test_dir/test-question-bank"
