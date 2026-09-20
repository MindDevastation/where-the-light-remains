# 3D production pipeline

Status: **approved production pipeline** for source modeling, runtime export and Godot integration.

This pipeline exists alongside gameplay implementation. 3D assets provide geometry/material presentation; GDScript provides behavior. Neither replaces the other.

## 1. Source of truth

For every asset use this precedence:
1. latest explicit owner instruction;
2. master document / canonical repository docs;
3. `docs/design/REQUIRED_ASSET_TABLE.md`;
4. `docs/production/ASSET_INDEX.md`;
5. approved concept art;
6. older reference material.

Concept art controls visual language, silhouette, mood and proportion targets, but never overrides puzzle mechanics, narrative canon, accessibility or performance constraints.

If a concept image does not provide enough information to model an object without inventing important geometry/function, pause that asset and request a decision.

## 2. Repository split

```text
assets/3d/                  # DCC/source side
├── blender/               # .blend sources
├── textures_source/       # source textures / paint files
├── reference/             # approved modeling reference packages
└── export_staging/        # temporary export staging; do not ship directly

game/art/                  # Godot runtime side
├── meshes/                # imported runtime GLB/GLTF-derived meshes
├── materials/
├── textures/
├── shaders/
├── vfx/
└── animations/
```

World assembly lives under `game/worlds/`; reusable gameplay objects live under `game/gameplay/`. Do not place puzzle logic inside art source files.

## 3. Branch model

Epic:

```text
epic/03-art-foundation
```

Foundation features:

```text
feature/03-art-foundation/pipeline-spec
feature/03-art-foundation/blender-export
feature/03-art-foundation/material-library
feature/03-art-foundation/modular-archive-kit
feature/03-art-foundation/import-validation
```

Later production epics may split environment/hero/memory work into their own asset features. One independently reviewable asset family = one feature branch when practical.

## 4. DCC baseline

Primary DCC: **Blender**.

Before production modeling begins, Astra must verify the actual Blender version and available CLI/export capabilities on the working machine. Do not invent a Blender baseline from documentation alone.

Coordinate/scale rules:
- Godot runtime uses meters; model to real-world meter scale;
- apply object transforms before export unless a deliberate rig/export reason exists;
- keep forward/up orientation consistent with the verified Blender→Godot export test;
- pivots/origins must be authored for the gameplay operation: hinge, rotating ring, sliding element, pickup center, door pivot, etc.;
- moving puzzle sub-parts should be separate objects/nodes when independent motion is required.

## 5. Modeling strategy

Target style: stylized realism matching the approved observatory/archive references.

Use modularity aggressively for architecture:
- reusable wall/floor/trim/arch/railing/door modules;
- shared material families;
- reusable brass/stone/wood/glass parts;
- hero props receive unique silhouette/detail only where it materially improves readability.

Do not reproduce proprietary game meshes, armor, logos or extracted assets. Character/environment references are for original reinterpretation only.

Gameplay readability outranks decorative fidelity. A player must understand an interactive hero prop in roughly 2–3 seconds through silhouette, contrast, emissive state, lighting and/or animation.

## 6. Geometry budgets

Use the Technical Baseline and profiler as authority. Current scene-level guideline is roughly 0.5–1.5M visible triangles typical, not a per-asset entitlement.

Asset-level budgets are assigned during breakdown based on screen size and reuse. Do not spend geometry uniformly.

Rules:
- architecture modules: efficient topology, bevel/detail where silhouette needs it;
- hero puzzle mechanism: higher local detail allowed, but preserve clean deformation/pivot behavior;
- small repeated props: aggressively optimized;
- unseen backfaces/interiors: remove unless needed for shadows/reflections/camera access;
- avoid subdivision left active in runtime exports unless explicitly justified and profiled.

If meeting the concept requires violating the scene performance budget, pause and escalate the tradeoff instead of silently exceeding it.

## 7. UV and textures

General rules:
- consistent texel density inside an asset family;
- reuse tileables/trim sheets for Archive architecture;
- unique baked maps only for hero assets that need them;
- avoid unique 4K textures for minor props;
- texture resolution is chosen by on-screen size, not by source concept resolution;
- pack channels where the Godot material setup benefits and readability is preserved.

Texture names follow the runtime naming convention, e.g. `t_<family>_<map>`.

## 8. Materials

Runtime materials are owned by Godot under `game/art/materials/` and follow `m_<name>` naming.

Prefer a compact shared material library:
- pale observatory stone;
- aged brass;
- polished/dark wood;
- frosted/memory glass;
- crystal/glass;
- emissive magical light variants;
- limited cloth/character materials where required.

Do not create a one-off material for decoration if an existing family can represent it without damaging the approved art direction.

## 9. LOD and visibility

Any asset that can materially affect performance must be reviewed for:
- LOD need;
- visibility range;
- occlusion opportunity;
- shadow casting necessity;
- material complexity;
- transparency cost.

Hero props close to the player may remain single-LOD when measured cost is acceptable. Large/repeated environment assets should use LOD/visibility strategy where it produces real savings.

Geometry reduction is not the first optimization lever; shadows, volumetrics, transparency, reflections, particles, draw calls and material cost are evaluated first where applicable.

## 10. Collision

Do not use render mesh collision by default.

Use:
- simple primitives for floors/walls/large blockers;
- authored convex/simple collision for props;
- dedicated interaction areas/rays for interaction readability;
- detailed collision only where gameplay truly requires it.

Puzzle collision and interaction logic belong in Godot scenes/scripts, not Blender logic.

## 11. Animation and movable mechanisms

Author mechanical parts around gameplay pivots from the beginning.

Examples:
- Wing I rings: separate rotatable ring objects;
- focus wheel: independent pivot/control object;
- Wing III mobile/counterweights: separate controllable components;
- Wing IV discs/moons: discrete movable state objects;
- Wing V viewers/crystal/filter elements: separate readable components;
- Egg sequence props/hazards: authored for scripted movement and collision needs.

Use Blender animation only where it improves authored motion workflow. Runtime state ownership remains in Godot through AnimationPlayer/Tween/scripted sequencing unless the canonical implementation requires imported animation.

## 12. Export

Runtime interchange target: **GLB/glTF 2.0** unless a verified asset-specific reason requires another route.

Before export:
- apply required transforms;
- verify scale;
- remove unused objects/data;
- verify normals/tangents;
- verify UVs;
- verify material slots;
- verify pivots;
- name objects intentionally;
- exclude DCC-only guides/reference meshes;
- check animation ranges if exported.

Runtime static mesh naming: `sm_<name>`.

Source `.blend` and final `.glb/.gltf` are large binary assets and must be covered by the repository LFS policy before bulk production begins.

## 13. Godot import and scene assembly

Import validation must check:
- scale and orientation;
- normals/tangents;
- material assignment;
- pivot behavior;
- collision setup;
- animation playback where relevant;
- shadow behavior;
- draw calls/material count;
- texture memory;
- obvious import warnings.

Do not put gameplay code directly into imported GLB scenes. Wrap imported art in authored `.tscn` scenes and attach behavior to the wrapper/subcomponents.

Example:

```text
sm_wing01_ring_outer.glb      # geometry
wing01_optics_puzzle.tscn     # assembled Godot scene
wing01_optics_controller.gd   # behavior/state
optical_ring.gd               # reusable ring behavior if justified
```

## 14. Asset acceptance checklist

An asset family is not production-ready until:
- [ ] canonical reference package identified;
- [ ] modeling ambiguity resolved;
- [ ] source file committed through LFS policy;
- [ ] naming/scale/pivots validated;
- [ ] UV/material plan validated;
- [ ] export imports successfully in Godot;
- [ ] collisions/interactions are appropriate;
- [ ] performance cost measured in representative scene;
- [ ] visual match accepted against concept/art bible;
- [ ] `ASSET_INDEX.md` updated with runtime path/status;
- [ ] relevant Godot smoke test still passes.

## 15. Recommended production order

Do not model the entire game before validating the pipeline.

First art vertical slice:
1. one Archive modular kit sample;
2. one representative shared material set;
3. one hero mechanism from Wing I;
4. Blender→GLB→Godot import test;
5. collision/pivot/material validation;
6. representative performance check;
7. only then expand to the full Archive kit and remaining hero mechanisms.

This minimizes the risk of producing many assets with incorrect scale, pivots, material assumptions or import settings.

## 16. Reasoning level policy for 3D work

Default for 3D production work: **High** reasoning.

Routine execution after the pipeline and asset brief are unambiguous may continue on High.

Astra must **pause and warn the owner to switch to Extra High / the highest available reasoning level before continuing** when a 3D task requires one or more of the following:
- designing or materially changing the cross-project Blender→Godot pipeline;
- deciding modular architecture that affects multiple stages;
- changing scene/asset performance budgets;
- designing procedural Blender tooling or nontrivial export automation;
- resolving conflicting concept-art/mechanics constraints with architectural consequences;
- choosing a character rig/animation strategy that affects several memories;
- designing a complex LOD/material/shader strategy across many assets;
- diagnosing a persistent import/render/performance problem after normal High-level attempts fail;
- making a destructive repository/history migration related to binary assets.

Required warning format:

```text
REASONING ESCALATION REQUIRED
Task: <task>
Why High is insufficient: <specific architectural/technical risk>
Requested level: Extra High / highest available
Blocked work: <what will not proceed until switched>
```

Astra must not claim it changed the reasoning level itself. It must wait for the owner to switch it and confirm continuation.
