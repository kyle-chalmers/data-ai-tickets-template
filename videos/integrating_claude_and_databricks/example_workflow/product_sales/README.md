# Databricks Job Troubleshooting Workflow

Step-by-step demonstration of the exact commands used to publish a Databricks job, encounter an error, diagnose it, fix it, and verify successful execution.

---

## Step 1: Create and Publish the Failing Job

### 1.1 Create Job Configuration with Intentional Error

**Created file:** `failing_job_config.json` with intentional error - references non-existent notebook path

```json
{
  "name": "Product Sales Analysis Job - Failing Version",
  "tasks": [
    {
      "task_key": "product_sales_analysis_task",
      "notebook_task": {
        "notebook_path": "/Users/[INSERT_USERNAME]/nonexistent_notebook",
        "source": "WORKSPACE"
      },
      "timeout_seconds": 3600
    }
  ],
  "schedule": {
    "quartz_cron_expression": "0 0 9 * * ?",
    "timezone_id": "America/Los_Angeles"
  },
  "max_concurrent_runs": 1,
  "email_notifications": {
    "on_failure": ["[INSERT_EMAIL]"]
  }
}
```

### 1.2 Create the Job

**Command Issued:**
```bash
databricks jobs create --json @failing_job_config.json --output json
```

**Output Received:**
```json
{
  "job_id": 395741627466738
}
```

**Observation:** Job was created successfully. Databricks doesn't validate notebook existence at job creation time - only at execution time.

---

## Step 2: Run the Job and Observe Failure

### 2.1 Execute the Job

**Command Issued:**
```bash
databricks jobs run-now 395741627466738 --output json
```

**Error Received:**
```
Exit code 1
Error: failed to reach TERMINATED or SKIPPED, got INTERNAL_ERROR:
Task product_sales_analysis_task failed with message:
Unable to access the notebook "/Users/[INSERT_USERNAME]/nonexistent_notebook"
in the workspace. Either it does not exist, or the identity used to run this job,
[INSERT_USERNAME], lacks the required permissions.
```

**Analysis:** The job failed immediately with INTERNAL_ERROR and a clear message about the notebook not being accessible.

---

## Step 3: Investigate the Error (Exact Commands Used)

### 3.1 Get Detailed Run Information

**First Command - Retrieve run details:**
```bash
databricks jobs list-runs --job-id 395741627466738 --limit 1 --output json
```

**Relevant Output:**
```json
[
  {
    "job_id": 395741627466738,
    "run_id": 463553466662806,
    "run_name": "Product Sales Analysis Job - Failing Version",
    "state": {
      "life_cycle_state": "INTERNAL_ERROR",
      "result_state": "FAILED",
      "state_message": "Task product_sales_analysis_task failed with message: Unable to access the notebook \"/Users/[INSERT_USERNAME]/nonexistent_notebook\" in the workspace. Either it does not exist, or the identity used to run this job, [INSERT_USERNAME], lacks the required permissions."
    },
    "status": {
      "state": "TERMINATED",
      "termination_details": {
        "code": "RESOURCE_NOT_FOUND",
        "message": "Task product_sales_analysis_task failed with message: Unable to access the notebook \"/Users/[INSERT_USERNAME]/nonexistent_notebook\" in the workspace...",
        "type": "CLIENT_ERROR"
      }
    },
    "execution_duration": 0,
    "run_duration": 875
  }
]
```

**Key Information Extracted:**
- **Error Code:** `RESOURCE_NOT_FOUND`
- **Error Type:** `CLIENT_ERROR`
- **Problem:** Notebook path `/Users/[INSERT_USERNAME]/nonexistent_notebook` doesn't exist
- **Life Cycle State:** `INTERNAL_ERROR`
- **Result State:** `FAILED`

---

### 3.2 Verify What Notebooks Actually Exist

**Second Command - List available notebooks:**
```bash
databricks workspace list /Users/[INSERT_USERNAME]/ --output json | jq -r '.[] | select(.object_type == "NOTEBOOK") | .path'
```

**Output Received:**
```
/Users/[INSERT_USERNAME]/Build your first AI agent
/Users/[INSERT_USERNAME]/customer_analysis
/Users/[INSERT_USERNAME]/product_sales_analysis
/Users/[INSERT_USERNAME]/product_sales_analysis_failing
```

**Analysis:**
- ❌ `/Users/[INSERT_USERNAME]/nonexistent_notebook` - NOT in the list
- ✅ `/Users/[INSERT_USERNAME]/product_sales_analysis` - EXISTS and is the correct notebook

---

### 3.3 Confirm Current Job Configuration

**Third Command - Check what the job is currently configured with:**
```bash
databricks jobs get 395741627466738 --output json | jq '{job_id, name: .settings.name, notebook_path: .settings.tasks[0].notebook_task.notebook_path}'
```

**Output Received:**
```json
{
  "job_id": 395741627466738,
  "name": "Product Sales Analysis Job - Failing Version",
  "notebook_path": "/Users/[INSERT_USERNAME]/nonexistent_notebook"
}
```

**Confirmation:** The job is indeed configured with the wrong notebook path.

---

### 3.4 Root Cause Diagnosis

**Problem:** Job configuration references notebook `/Users/[INSERT_USERNAME]/nonexistent_notebook` which doesn't exist

**Solution:** Update job configuration to reference `/Users/[INSERT_USERNAME]/product_sales_analysis` which does exist

**Error Classification:**
- **Type:** Configuration error (CLIENT_ERROR)
- **Code:** RESOURCE_NOT_FOUND
- **Severity:** Blocking - job cannot run until fixed
- **Fix Method:** Update job configuration with correct path

---

## Step 4: Fix the Configuration

### 4.1 Create Update Configuration

**Created file:** `update_job_config.json` with corrected notebook path

```json
{
  "job_id": 395741627466738,
  "new_settings": {
    "name": "Product Sales Analysis Job - Fixed Version",
    "tasks": [
      {
        "task_key": "product_sales_analysis_task",
        "notebook_task": {
          "notebook_path": "/Users/[INSERT_USERNAME]/product_sales_analysis",
          "source": "WORKSPACE"
        },
        "timeout_seconds": 3600
      }
    ],
    "schedule": {
      "quartz_cron_expression": "0 0 9 * * ?",
      "timezone_id": "America/Los_Angeles"
    },
    "max_concurrent_runs": 1,
    "email_notifications": {
      "on_failure": ["[INSERT_EMAIL]"]
    }
  }
}
```

**Key Change:** Updated `notebook_path` from `nonexistent_notebook` to `product_sales_analysis`

### 4.2 Apply the Fix

**Command Issued:**
```bash
databricks jobs update --json @update_job_config.json
```

**Output:** Command completed without errors (no output means success)

---

## Step 5: Verify the Fix

### 5.1 Confirm Configuration Update

**Command Issued:**
```bash
databricks jobs get 395741627466738 --output json | jq '{job_id, name: .settings.name, notebook_path: .settings.tasks[0].notebook_task.notebook_path}'
```

**Output Received:**
```json
{
  "job_id": 395741627466738,
  "name": "Product Sales Analysis Job - Fixed Version",
  "notebook_path": "/Users/[INSERT_USERNAME]/product_sales_analysis"
}
```

**Verification:** ✅
- Notebook path is now correct
- Job name updated to "Fixed Version"
- Configuration change successfully applied

---

## Step 6: Run the Fixed Job

### 6.1 Execute the Corrected Job

**Command Issued:**
```bash
databricks jobs run-now 395741627466738 --output json
```

**Output Received:**
```json
{
  "cleanup_duration": 0,
  "creator_user_name": "[INSERT_USERNAME]",
  "effective_performance_target": "PERFORMANCE_OPTIMIZED",
  "end_time": 1763362310595,
  "execution_duration": 41000,
  "job_id": 395741627466738,
  "job_run_id": 552487372528579,
  "run_id": 552487372528579,
  "run_name": "Product Sales Analysis Job - Fixed Version",
  "run_duration": 44965,
  "state": {
    "life_cycle_state": "TERMINATED",
    "result_state": "SUCCESS",
    "state_message": "",
    "user_cancelled_or_timedout": false
  },
  "status": {
    "state": "TERMINATED",
    "termination_details": {
      "code": "SUCCESS",
      "message": "",
      "type": "SUCCESS"
    }
  }
}
```

**Success Metrics:**
- ✅ **State:** TERMINATED
- ✅ **Result:** SUCCESS
- ✅ **Execution Duration:** 41 seconds
- ✅ **Total Duration:** 44.965 seconds
- ✅ **Termination Code:** SUCCESS

---

## Summary: Complete Command Sequence

### Error Detection & Investigation
```bash
# 1. Create failing job
databricks jobs create --json @failing_job_config.json --output json
# → Job created: 395741627466738

# 2. Run and observe failure
databricks jobs run-now 395741627466738 --output json
# → Error: INTERNAL_ERROR - RESOURCE_NOT_FOUND

# 3. Get detailed error information
databricks jobs list-runs --job-id 395741627466738 --limit 1 --output json
# → Found: termination_code = "RESOURCE_NOT_FOUND"
# → Found: error message about nonexistent_notebook

# 4. List available notebooks
databricks workspace list /Users/[INSERT_USERNAME]/ --output json | \
  jq -r '.[] | select(.object_type == "NOTEBOOK") | .path'
# → Found: product_sales_analysis exists
# → Confirmed: nonexistent_notebook does NOT exist

# 5. Verify current job config
databricks jobs get 395741627466738 --output json | \
  jq '{job_id, name: .settings.name, notebook_path: .settings.tasks[0].notebook_task.notebook_path}'
# → Confirmed: job points to wrong notebook path
```

### Fix & Verification
```bash
# 6. Update job with correct configuration
databricks jobs update --json @update_job_config.json
# → Update successful (no errors)

# 7. Verify the fix was applied
databricks jobs get 395741627466738 --output json | \
  jq '{job_id, name: .settings.name, notebook_path: .settings.tasks[0].notebook_task.notebook_path}'
# → Confirmed: notebook_path now correct

# 8. Run fixed job
databricks jobs run-now 395741627466738 --output json
# → Result: SUCCESS ✅
# → Execution: 41 seconds
# → Status: TERMINATED with SUCCESS code
```

---

## Troubleshooting Methodology Applied

### 1. **Capture the Error**
- Used `databricks jobs run-now` to execute and immediately saw failure
- Error message provided initial clue about notebook path issue

### 2. **Get Detailed Information**
- Used `databricks jobs list-runs` to get structured error data
- Extracted error code (`RESOURCE_NOT_FOUND`) and type (`CLIENT_ERROR`)
- Identified exact problem: notebook path doesn't exist

### 3. **Verify Resource Availability**
- Used `databricks workspace list` with `jq` to list all available notebooks
- Confirmed the referenced notebook doesn't exist
- Found the correct notebook that should be used

### 4. **Inspect Current Configuration**
- Used `databricks jobs get` to see exactly what the job is configured with
- Confirmed the misconfiguration

### 5. **Apply Fix**
- Created corrected configuration file
- Used `databricks jobs update` to apply changes
- No need to delete and recreate the job

### 6. **Verify Fix**
- Used `databricks jobs get` again to confirm changes applied
- Checked that notebook path is now correct

### 7. **Test**
- Ran job again with `databricks jobs run-now`
- Confirmed SUCCESS state and completion

---

## Key Learnings

### Commands for Error Investigation
1. **`databricks jobs list-runs --job-id <ID> --limit 1 --output json`** - First command to run when a job fails - gives you error codes and messages
2. **`databricks workspace list <PATH> --output json`** - Verify resources exist before referencing them
3. **`databricks jobs get <JOB_ID> --output json`** - Inspect current configuration to understand what's wrong

### Commands for Resolution
1. **`databricks jobs update --json @config.json`** - Fix jobs without deleting them
2. **`databricks jobs get <JOB_ID>`** - Always verify your fix was applied
3. **`databricks jobs run-now <JOB_ID>`** - Test the fixed configuration

### Error Analysis Pattern
1. Read the error message carefully - it often tells you exactly what's wrong
2. Extract error codes (`RESOURCE_NOT_FOUND`, `CLIENT_ERROR`, etc.)
3. List/verify resources mentioned in the error
4. Compare job configuration to actual available resources
5. Update configuration and verify before re-running

### Best Practices
- Job creation doesn't validate resource existence
- Always test notebooks with one-time runs before creating jobs
- Use `--output json` with `jq` for programmatic analysis
- Jobs can be updated without deletion/recreation
- Always verify configuration changes before re-running

---

**Job ID:** 395741627466738
**Final Status:** SUCCESS ✅
**Execution Time:** 41 seconds
**Run URL:** https://dbc-9fd4b6c0-3c0e.cloud.databricks.com/?o=4275927686467451#job/395741627466738/run/552487372528579
