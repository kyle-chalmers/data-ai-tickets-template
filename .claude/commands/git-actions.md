# Take Git Actions

## Merge PR: $ARGUMENTS

The $ARGUMENTS should be yes or no, and this can take many forms like y or n, etc. 
If it is yes, then merge the PR you create. After merging, delete the remote branch and the local branch, and switch back to the "main" branch and pull.
If it is no, then do not merge the PR you create.

## Execution Process
- Add all changes made in the repo
- Commit all changes with appropriate descriptive messaging
- Push changes to the repository
- Create a pull request with the proper semantic title and a concise description of what has been done (ideally less than 200 words)

In the case the user says yes, then:
- Merge the pull request
- Delete the remote branch and the local branch
- Switch back to the "main" branch and pull