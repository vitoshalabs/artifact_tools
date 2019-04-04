### Overview

This repository contains tools which help manage repository artifacts stored on our storage.

Artifacts are:

* all files which are either used as external input for some procedure (e.g. Images, Videos, Database dumps etc., that are later used in the release of a project)

* output from a build procedure (e.g. we have a project that we need to build a binary once a year, and its result is used by other projects on a daily basis)

These artifacts are stored out of repository as they'll bloat the repo (hello Git LFS), so we develop our tools to store the artifacts in our infrastructure.
