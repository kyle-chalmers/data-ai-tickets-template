# TO-DOS

## Add Source Video Relations and Timestamps to Shorts - 2026-02-11 23:04

- ~~**Map Source Video relations for all 46 Shorts**~~ DONE (2026-02-12) - All 46 shorts mapped to 8 source videos using YouTube API description links for validation. Mapping: Snowflake (6), 5 Lessons (6), Jira (3), Databricks Easy (7), Cursor vs Claude (2), FUTURE PROOF (8), Data Skills (12), Skip S3/Athena (2). Note: 4-Phase Workflow has 0 shorts despite "Posted" status in Content Calendar.

- **Get Clip Timestamps for all 46 Shorts** - PARTIAL. Only 1 timestamp extracted from YouTube descriptions: "One Trick SQL Accuracy" at 26:12 in Snowflake video. YouTube description `&t=` parameters are "start watching here" points, not clip origins. Remaining 45 need manual review or transcript-based matching.

- ~~**Update TikTok platform tags on applicable Shorts**~~ DONE (2026-02-12) - 10 shorts updated with `["YouTube Shorts", "TikTok"]`: Realistic Timeline, Hack to Setting Up Snowflake, Future of Data Analytics, Folder Structure, Snowflake CLI vs MCP, Unlock Claude Code Success, Revealing the Claude Code Hack, Learn and Thrive in Data, ATTENTION Data Professionals, LLM Compaction.

- ~~**Add YouTube descriptions to Shorts database**~~ DONE (2026-02-12) - Pulled descriptions and tags from YouTube Data API v3 for all 46 shorts and added to Notion page bodies.

- ~~**Update Date Posted with full datetimes from YouTube API**~~ DONE (2026-02-12) - All 46 shorts updated with exact publish times (hour:minute:second) from YouTube Data API v3 `publishedAt` field. Previously only had date-level granularity.
