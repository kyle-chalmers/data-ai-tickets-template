-- Test transformation logic for VW_LOAN_BANKRUPTCY
-- Testing status field normalization and data source logic

-- Test Chapter Normalization
SELECT 
    CHAPTER as original_chapter,
    CASE 
        WHEN CHAPTER LIKE '%chapter13%' THEN 'Chapter 13'
        WHEN CHAPTER LIKE '%chapter7%' THEN 'Chapter 7' 
        WHEN CHAPTER LIKE '%chapter11%' THEN 'Chapter 11'
        ELSE CHAPTER 
    END as BANKRUPTCY_CHAPTER_CLEAN,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANKRUPTCY_ENTITY_CURRENT 
WHERE ACTIVE = 1 AND DELETED = 0
GROUP BY CHAPTER, BANKRUPTCY_CHAPTER_CLEAN
ORDER BY record_count DESC;