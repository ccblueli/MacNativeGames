# macOS 15 / Metal 3 branch

This experimental branch starts at upstream `a8807a1a3098a1ec1ec6698932bdf92d9635f5e5`.
The Metal 3 compatibility layer is adapted from
[1918662410-ship-it/MacNativeGames, f71ea7b](https://github.com/1918662410-ship-it/MacNativeGames/tree/f71ea7b56eb1f7064d5e753428cc6b05a124241b).
It remains MIT-licensed; see LICENSE and THIRD_PARTY_NOTICES.md.

## Build

Use Apple silicon, macOS 15 or later, and the command line tools. Follow the normal
README prerequisites for Python, opus and libvpx. The switch is opt-in:

```sh
TOTK_M3=1 python3 build_app.py /path/to/base.nsp \
  --update /path/to/update.nsp -k /path/to/prod.keys \
  --firmware /path/to/firmware \
  --work /path/outside/source/TOTK_build_m3 \
  -o '/path/outside/source/Tears of the Kingdom M3 Test.app'
```

Use a separate work directory for Metal 3 and Metal 4 builds. The backend's objects
are separate, but the runtime binary names are shared by the packaging script.
Keep game inputs, keys, unpacked data, shaders, saves and generated apps outside
this repository. Do not overwrite a known working app before comparing the same
save and scene in the test app.

For a source-only compile, copy `games/totk` to a build directory outside this
checkout, then run there:

```sh
TOTK_M3=1 make -j4 PY=python3 binary-v143
```

That produces a runtime executable and shader manifests, not a playable app. The
current upstream runtime loads version-specific game tables from its data folder;
it cannot simply replace the executable in an older packaged app.

## Port and limitations

- Metal 3 uses command buffers from the command queue, separate blit/compute
  encoders, and immediate buffer/texture bindings. Metal 4 stays the default when
  `TOTK_M3` is absent. Compatibility changes are guarded by `DM_NVN_M3`.
- MetalFX spatial scaling uses the classic API. Frame interpolation is unavailable
  on macOS 15. The new optional MetalFX TAA path also stays off in this initial port;
  the game's original anti-aliasing is unchanged.
- The community layer's fixed 1024-entry GPU buffer registry silently dropped later
  registrations. It now grows under the existing lock. A real-Metal regression
  registers 1100 buffers and checks offsets, removal and re-registration. The old
  implementation fails this test; the new implementation passes.
- The inherited sampler MIN/MAX reduction fallback is still not equivalent to the
  Metal 4 path. It logs when encountered; visual equivalence is not claimed.
- No gameplay or screenshot comparison has been performed for this revision. The
  registry fix is a verified binding defect, not proof that it fixes every reported
  rainbow/striped texture artifact.

## Validation — 2026-10-27

Host: Apple M4, macOS 15.7, macOS SDK 15.5.

- `TOTK_M3=1 make -j4 PY=python3 binary-v143`: compile and link passed.
- Builder's `build_launcher` and `build_warm_tool`: passed.
- Runtime Mach-O minimum OS: 15.0; no undefined Metal 4 symbols.
- `python -m unittest discover -s tests`: 373 tests, passed, 4 skipped in the
  sandbox (including the real-Metal test; it was separately run with GPU access).
- Standalone `tests/m3_buffer_registry.m`: passed on the real GPU; original
  fixed-capacity implementation failed at lookup after registration.
- Metal 4 renderer preprocessing (`DM_NVN_M3=0`) matches the upstream renderer,
  normalizing only `__LINE__` diagnostic labels. This is not an SDK 26 compile.
- iOS / Metal 4 builds were not compiled: this host only has macOS SDK 15.5.
- Full game packaging and gameplay verification remain pending.

The visionOS stub test needs SDK 26's Metal 4 declarations. It failed on the
unmodified upstream tree with SDK 15.5 too, and now explicitly skips on older SDKs.

## Maintaining the branch

Keep `main` as an upstream reference and merge upstream changes into
`macos15-metal3`, reviewing graphics conflicts individually. Preserve upstream
texture lifetime and cache invalidation fixes when adapting API calls. Re-run the
source tests, real-Metal buffer probe and a same-save gameplay comparison before
replacing a working app. Game content never belongs in a commit.
