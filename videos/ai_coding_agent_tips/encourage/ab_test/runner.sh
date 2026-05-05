#!/bin/bash
# A/B test runner for the /encourage skill
# 3 trials x 2 variants x 2 scenarios = 12 invocations
# Captures one JSON file per trial so we can extract cost + result text
#
# Idempotent: if outputs/<name>.json already exists AND is non-empty, the
# trial is skipped. Delete the file to re-run.

set -u
cd "$(dirname "$0")"

declare -a JOBS=(
  "s1_variant_a"
  "s1_variant_b"
  "s2_variant_a"
  "s2_variant_b"
)

START=$(date +%s)
RAN=0
SKIPPED=0

for prompt_name in "${JOBS[@]}"; do
  for trial in 1 2 3; do
    out="outputs/${prompt_name}_trial${trial}.json"

    if [ -s "${out}" ]; then
      cost=$(grep -o '"total_cost_usd":[0-9.]*' "${out}" | tail -1 | cut -d: -f2)
      echo "[$(date +%H:%M:%S)] SKIP  ${prompt_name} trial ${trial} (already ran, cost \$${cost})"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    echo "[$(date +%H:%M:%S)] RUN   ${prompt_name} trial ${trial}..."
    claude -p "$(cat ${prompt_name}.txt)" \
      --model claude-sonnet-4-6 \
      --max-budget-usd 0.50 \
      --output-format json \
      > "${out}" 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "        ! exit ${rc}"
    fi
    cost=$(grep -o '"total_cost_usd":[0-9.]*' "${out}" | tail -1 | cut -d: -f2)
    echo "        cost: \$${cost:-(parse-failed)}"
    RAN=$((RAN + 1))
  done
done

END=$(date +%s)
echo ""
echo "Trials run: ${RAN}, skipped: ${SKIPPED}, elapsed: $((END - START))s"
echo ""
echo "Output files:"
ls -la outputs/
