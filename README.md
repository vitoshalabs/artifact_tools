### Overview

This repository contains tools which help manage repository artifacts stored on our storage.

Artifacts are:

* all files which are either used as external input for some procedure (e.g. Images, Videos, Database dumps etc., that are later used in the release of a project)

* output from a build procedure (e.g. we have a project that we need to build a binary once a year, and its result is used by other projects on a daily basis)

These artifacts are stored out of repository as they'll bloat the repo (hello Git LFS), so we develop our tools to store the artifacts in our infrastructure.

### Example use case

Say we have a binary that we build/update once a year from external sources and we need to use that in one of our projects that is built several times a day.

So we allocate storage of our own to keep the versions of that binary, that has SSH access via some user and authorized key(s).

Since we want to track the changes to the binary, and some logs on the reasoning behind changing from one version to another we need also some plain text file to reflect those.

Using git based SCM presented as the best candidate for the job Git LFS, but we failed to find a straightforward way to use the system in a way that it allowed us full control on how many versions are kept on a binary and when they are deleted. Also we needed a bit more freedom in decisions where and when to upload the artifact files.

So we implemented a lightweight artifact_tool system, which relies on simple YAML-based configuration files, which contain:
- remote server to upload to/download from artifacts
- full path to remote dir, where artifacts are kept
- user used to access the server
- list of files each with
 - file name
 - file version, as sha1sum of currently used one or more artifact file(s)

And tools to read that configuration file and upload/download artifacts based on that:
```
$ artifact_upload
Usage: ~/artifact_tools/lib/artifact_tools/uploader.rb [options]
    -c, --configuration=FILE         Pass configuration file.
    -a, --append                     Append uploaded files to configuration file, if missing. Default: false.
    -h, --help                       Show this message
$ artifact_download
Usage: ~/artifact_tools/lib/artifact_tools/downloader.rb [options]
    -c, --configuration=FILE         Pass configuration file
    -d, --destination=DIR            Store files in directory
    -v, --[no-]verify                Verify hash on downloaded files. Default: true.
    -u, --user=USER                  Access server with this username
    -m, --match=REGEXP               Download only file which match regular expression
    -h, --help                       Show this message
```

#### Possible scenario

Imagine we have a provider of binary data that we get on monthly/yearly basis updates from. Each time we get an update we need to make sure that the binary data is compatible with our processing and delivers expected or better result than before.

- On first step we have a project structure
```
$ ls
file.bin include  lib  src
```

- Then we prepare the project for including the artifact in it
```
$ mkdir artifacts
$ mv file.bin artifacts/
$ sha1sum artifacts/file.bin
42f04ef6c7dbc6a176545d6fc272878b265d2e2f  artifacts/file.bin
$ vi artifacts.yaml
$ ls
artifacts  artifacts.yaml  include  lib  src
$ cat artifacts.yaml
---
server: server
dir: "/tmp/storage/"
user: user
files:
  artifacts/file.bin:
    hash: 42f04ef6c7dbc6a176545d6fc272878b265d2e2f
```

- Now that we are set and done let's upload the first version of the artifact
```
$ artifact_upload -c artifacts.yaml -a artifacts/file.bin
42f04ef6c7dbc6a176545d6fc272878b265d2e2f artifacts/file.bin
$ cat artifacts/file.bin
bindata1
$ ssh user@server 'find /tmp/storage_file_bin'
/tmp/storage_file_bin
/tmp/storage_file_bin/42f04ef6c7dbc6a176545d6fc272878b265d2e2f
/tmp/storage_file_bin/42f04ef6c7dbc6a176545d6fc272878b265d2e2f/file.bin

```

- We have tested the binary and it is ok so we add the artifact changes
```
$ git add artifacts.yaml
$ git commit -m "Nice binary integrated"

```

- A year has passed and we used the binary happily but got new one and decided to test it
```
$ cat artifacts/file.bin
bindata1
bindata2
$ artifact_upload -c artifacts.yaml -a artifacts/file.bin
60ce5566b2c63082bc032ba412a505993a5031ec artifacts/file.bin
$
$ ssh user@server 'find /tmp/storage'
/tmp/storage
/tmp/storage/42f04ef6c7dbc6a176545d6fc272878b265d2e2f
/tmp/storage/42f04ef6c7dbc6a176545d6fc272878b265d2e2f/file.bin
/tmp/storage/60ce5566b2c63082bc032ba412a505993a5031ec
/tmp/storage/60ce5566b2c63082bc032ba412a505993a5031ec/file.bin
$ cat artifacts.yaml
---
server: server
dir: "/tmp/storage/"
user: user
files:
  artifacts/file.bin:
    hash: 60ce5566b2c63082bc032ba412a505993a5031ec
$ git add artifacts.yaml
$ git commit -m "Better Faster Nicer file.bin"
```

- During that time our build procedures CI or manual require latest and greatest, so during build procedure we use the download tool
```
$ artifact_download -c artifacts.yaml  artifacts/file.bin -d build_target_dir/
```

- On another project or branch of the same project we might need still the older version of that binary, so it artifacts.yaml looks like this
```
$ cat artifacts.yaml
---
server: server
dir: "/tmp/storage/"
user: user
files:
  artifacts/file.bin:
    hash: 42f04ef6c7dbc6a176545d6fc272878b265d2e2f
```

- Regarding not keeping any waste, one possible custom solution is to have version file of the project listing:
 - its own version
 - and the artifact and  artifacts versions on which it depends.
 As long as this version is relevant (e.g. has customer deployments, has open bugs not resolved, etc) we keep the version on the storage server, otherwise drop it.


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


```
---
server: server
dir: "/tmp/storage/"
user: user
files:
  hello.txt:
    hash: 1d229271928d3f9e2bb0375bd6ce5db6c6d348d9
```
