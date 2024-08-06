# PREV_DATE=$(date -v -1d '+%Y-%m-%d')
PREV_DATE="2024-08-06"
echo "::set-output name=date::$PREV_DATE"
echo $PREV_DATE

git log enterprise/main  --since="$PREV_DATE 00:00" --until="$PREV_DATE 23:59" --grep="(CE)" --format="%H" --no-merges | while read sha; do
  AUTHOR_NAME=$(git log -1 --pretty=format:'%an' $sha)
  AUTHOR_EMAIL=$(git log -1 --pretty=format:'%ae' $sha)
  COMMIT_MESSAGE=$(git log -1 --pretty=format:'%s' $sha)
  BRANCH_NAME="cherry-pick-ce-commit-${sha}"
  git checkout -b $BRANCH_NAME
  git cherry-pick $sha || {
    echo "Conflict in commit $sha, resolving manually."
    git add .
    git commit -am "Resolve conflict in cherry-pick of $sha and change the commit message"
  }
  git push --force --set-upstream origin $BRANCH_NAME
  PR_TITLE="${COMMIT_MESSAGE}"
  PR_BODY="This PR cherry-picks the CE commit ${sha} from the Enterprise repository. Commit author: ${AUTHOR_NAME} (${AUTHOR_EMAIL})"
  AUTHOR_GH_USERNAME=$(gh api graphql -f query='query { search(query: "${AUTHOR_EMAIL}", type: USER, first: 1) { nodes { ... on User { login } } } }' -q '.data.search.nodes[0].login')
  if [ -n "$AUTHOR_GH_USERNAME" ]; then
    PR_BODY="${PR_BODY}\n\ncc @${AUTHOR_GH_USERNAME}"
    gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base main --head $BRANCH_NAME --assignee "$AUTHOR_GH_USERNAME"
  else
    gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base main --head $BRANCH_NAME
  fi
  git checkout main
  git branch -D $BRANCH_NAME
done
