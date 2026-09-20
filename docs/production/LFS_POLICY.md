# Git LFS policy

Status: **ACTIVE — forward-only 3D LFS policy**.

## Purpose

Use Git LFS for future heavy 3D binary assets without rewriting the existing repository history.

The repository already contains a large ordinary-Git WAV history. Rewriting that history is destructive, changes commit SHAs across refs and is not required for the next production step. Existing audio therefore remains ordinary Git unless a later maintenance task explicitly migrates or removes historical audio blobs.

## Tracked through LFS

Current `.gitattributes` tracks these future file types with Git LFS:

```text
*.blend
*.glb
*.fbx
```

These extensions were not present in the repository tree when this policy was introduced, so the policy does not create "should have been pointer" inconsistencies for existing files.

## Not currently tracked through LFS

Existing source/runtime audio remains ordinary Git:

```text
*.wav
*.flac
*.mp3
*.ogg
```

Concept/reference images and source documents also remain ordinary Git unless a later measured need justifies changing the policy.

## Required client setup

Any environment that commits or checks out LFS-backed 3D files must have a working Git LFS client:

```bash
git lfs version
git lfs install
```

Before the first real 3D binary is merged, the producing environment must prove:

```bash
git lfs ls-files
git lfs fsck
```

and a fresh checkout must retrieve the binary payload successfully.

## First-binary gate

The first `.blend`, `.glb` or `.fbx` feature is not considered validated until all of the following are confirmed:

- the committed Git blob is an LFS pointer, not the raw binary;
- the corresponding LFS payload upload succeeds;
- a fresh clone/check-out downloads the payload;
- the downloaded file opens/imports correctly in Blender/Godot as applicable;
- ordinary repository smoke tests still pass.

If the environment can create a pointer but cannot upload or retrieve the LFS payload, stop with BLOCKER and do not merge that binary feature.

## Existing audio history

The old destructive `git lfs migrate import --everything` plan is no longer a prerequisite for 3D production.

A future audio-history cleanup may still be worthwhile because the repository is already large, but it is a separate maintenance optimization, not a production gate. Such a task must measure retained/obsolete audio history before any rewrite and must preserve a recoverable backup plus fresh-clone validation.

## Rationale

This policy minimizes current risk:

- no force-rewrite of public history;
- no invalidation of existing clones merely to start 3D work;
- no unnecessary LFS storage use for obsolete historical WAV revisions;
- all new heavy 3D production files are prevented from further bloating ordinary Git history.
