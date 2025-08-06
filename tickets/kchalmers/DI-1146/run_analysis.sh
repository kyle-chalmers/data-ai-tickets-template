#!/bin/bash
# DI-1146: Mobile vs Desktop Application Analysis
# Execute queries and save results

echo "🔍 Running Full Analysis Query..."
snow sql -q "$(cat queries/1_full_analysis.sql)" --format=csv > final_deliverables/full_analysis_results.csv
echo "✅ Full analysis saved to final_deliverables/full_analysis_results.csv"

echo "📊 Running Summary Analysis Query..."
snow sql -q "$(cat queries/2_summary_analysis.sql)" --format=csv > final_deliverables/summary_results.csv
echo "✅ Summary analysis saved to final_deliverables/summary_results.csv"

echo "📈 Analysis complete! Results saved in final_deliverables/"
echo "📱 Slack message ready in slack_message.txt"