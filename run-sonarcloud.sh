#!/usr/bin/env bash

: "${INPUT_FOLDER:?}"
: "${REPOSITORY_SSH_KEY:?}"
: "${REPOSITORY_GIT_NAME:?}"
: "${REPOSITORY_EXCLUSIONS:?}"
: "${REPOSITORY_SOURCES:?}"
: "${SONAR_PROJECT_KEY:?}"
: "${SONAR_PROJECT_NAME:?}"
: "${SONAR_PROJECT_ORGANIZATION:?}"
: "${SONAR_TOKEN:?}"

call_sonarcloud_docker_run () {
  SONAR_COMMAND=(
    "docker run -ti -v $(pwd)/${INPUT_FOLDER}:/var/www"
    "newtmitch/sonar-scanner:alpine"
    "-Dsonar.projectBaseDir=/var/www"
    "-Dsonar.projectKey=${SONAR_PROJECT_KEY}"
    "-Dsonar.projectName=${SONAR_PROJECT_NAME}"
    "-Dsonar.organization=${SONAR_PROJECT_ORGANIZATION}"
    "-Dsonar.sources=${REPOSITORY_SOURCES}"
    "-Dsonar.host.url=https://sonarcloud.io"
    "-Dsonar.login=${SONAR_TOKEN}"
    "-Dsonar.exclusions=${REPOSITORY_EXCLUSIONS}"
  )
  if [[ ! -z "$PR_ID" && ! -z "$PR_BASE" && ! -z "$PR_BRANCH" ]]; then
    SONAR_COMMAND+=(
      "-Dsonar.pullrequest.provider=GitHub"
      "-Dsonar.pullrequest.github.repository=${REPOSITORY_GIT_NAME}"
      "-Dsonar.pullrequest.key=${PR_ID}"
      "-Dsonar.pullrequest.branch=${PR_BRANCH}"
      "-Dsonar.pullrequest.base=${PR_BASE}"
    )
    if [[ ! -z "$REPOSITORY_JS_LCOV"]]; then
      SONAR_COMMAND+=(
        "-Dsonar.javascript.lcov.reportPaths=${REPOSITORY_JS_LCOV}"
      )
    fi
    if [[ ! -z "$REPOSITORY_CPD_EXCLUSIONS"]]; then
      SONAR_COMMAND+=(
        "-Dsonar.cpd.exclusions=${REPOSITORY_CPD_EXCLUSIONS}"
      )
    fi
  fi
  eval "${SONAR_COMMAND[@]}"
}

echo ">>>> Loading repository credentials..."
mkdir -p /root/.ssh && \
    chmod 0700 /root/.ssh && \
    ssh-keyscan github.com > /root/.ssh/known_hosts && \
    echo "$REPOSITORY_SSH_KEY" > /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa

echo ">>>> Getting Pull Request info if exists..."
if [[ -f "$INPUT_FOLDER/.git/resource/pr" ]]; then
  echo ">>>> Fetching data from Pull Request"
  export PR_ID=$(cat $INPUT_FOLDER/.git/resource/pr)
  export PR_BASE=$(cat $INPUT_FOLDER/.git/resource/base_name)
  export PR_BRANCH=$(cat $INPUT_FOLDER/.git/resource/head_name)
  echo ">>>> Fetching files from \"$PR_BASE\" branch..."
  SOURCE_DIR=$(pwd)
  cd $INPUT_FOLDER
  git remote add origin "git@github.com:${REPOSITORY_GIT_NAME}.git"
  git fetch origin '+refs/heads/'"$PR_BASE"':refs/remotes/origin/'"$PR_BASE"''
  cd $SOURCE_DIR
fi

echo ">>>> Running SonarCloud tests..."
call_sonarcloud_docker_run

