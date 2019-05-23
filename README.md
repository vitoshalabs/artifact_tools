### Overview

This repository contains tools which help manage repository artifacts stored on our storage.

Artifacts are:

* all files which are either used as external input for some procedure (e.g. Images, Videos, Database dumps etc., that are later used in the release of a project)

* output from a build procedure (e.g. we have a project that we need to build a binary once a year, and its result is used by other projects on a daily basis)

These artifacts are stored out of repository as they'll bloat the repo (hello Git LFS), so we develop our tools to store the artifacts in our infrastructure.

### Configuration file

The tools use configuration file where they store meta information about the stored files. The file is in YAML format and contains these first level keys:

* `server` - which storage server to use. It has to support SSH access. *Required* field.

* `dir` - directory on the server to store the files. *Required* field.

* `user` - username with which to connect to the server. *Optional* field.

* `files` - contains meta information of the artifact files. *Required* field.

    The value is again a hash where:

    * The key is the path of the file relative to `dir` on the `server`. The path is expected to be relative to the configuration file's path.
    * The value is a hash with one required key - `hash`. For now there aren't any other keys, but they could freely be extended in the future.

Example:

```yaml
---
server: server
dir: "/tmp/storage/"
user: user
files:
  hello.txt:
    hash: 1d229271928d3f9e2bb0375bd6ce5db6c6d348d9
```
