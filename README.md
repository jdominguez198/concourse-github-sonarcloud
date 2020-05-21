# Concourse Github Sonarcloud

This image is used to work with Concourse and allow the user to analyze a Pull Request with Coverage test in SonarCloud, integrating it
with Github. This requires to use [Github PullRequest Resource](https://github.com/telia-oss/github-pr-resource)
in the Pipeline as a resource to listen Pull Request creation/updates.

Optimized for use with [Concourse CI](http://concourse.ci/).

The image is Alpine based, and includes Docker, Docker Compose, and Docker Squash, as well as Bash.

Image published to Docker Hub: [jdominguez198/concourse-github-sonarcloud](https://hub.docker.com/r/jdominguez198/concourse-github-sonarcloud/).

Inspired by [karlkfi/concourse-dcind](https://github.com/karlkfi/concourse-dcind).

## Build

```
docker build -t jdominguez198/concourse-github-sonarcloud .
```

## Example

Here is an example of a Concourse [job](http://concourse.ci/concepts.html) that uses ```jdominguez198/concourse-github-sonarcloud``` image to run the sonarcloud analysis tool.

```yaml
resources:
- name: pullrequest
  type: pull-request
  icon: github-circle
  source:
    repository: my-repo
    access_token: ((my-token))
  check_every: 3m

jobs:
- name: sonar-scanner
  plan:
    - get: pullrequest
      trigger: true
    - put: pullrequest
      params:
        state: INPROGRESS
        name: pullrequest-sonarcloud
        path: pullrequest
    - task: execute-sonarcloud-tool
      privileged: true
      config:
        platform: linux
        image_resource:
          type: docker-image
          source:
            repository: jdominguez198/concourse-bitbucket-sonarcloud
        inputs:
          - name: pullrequest
        run:
          path: entrypoint.sh
        params:
          INPUT_FOLDER: "pullrequest"
          REPOSITORY_GIT_NAME: "my-organization/my-repo"
          REPOSITORY_EXCLUSIONS: "**/test/**,**/vendor/**,**/component-**/**"
          REPOSITORY_SOURCES: "src/"
          REPOSITORY_JS_LCOV: "test/unit/coverage/lcov.info" # Optional
          REPOSITORY_CPD_EXCLUSIONS: "test/**/a*.js" # Optional
          SONAR_PROJECT_KEY: ((sonar_project_key))
          SONAR_PROJECT_NAME: ((sonar_project_name))
          SONAR_PROJECT_ORGANIZATION: ((sonar_project_organization))
          SONAR_TOKEN: ((sonar_token))
```
