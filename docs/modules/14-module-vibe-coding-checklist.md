# Module Vibe-Coding Checklist

Use this checklist whenever we implement one module from the module contracts.

## Before Coding

- [ ] Read the module's MD contract.
- [ ] Inspect existing models/providers/widgets for the module.
- [ ] Identify persisted models and Hive type IDs.
- [ ] Identify existing UI that must be preserved/migrated.
- [ ] Identify all inbound/outbound references.
- [ ] Confirm which shared systems the module consumes.
- [ ] Do not invent a parallel architecture.

## During Coding

- [ ] Domain logic is outside widgets.
- [ ] Persistence is behind repository/application boundaries where practical.
- [ ] Existing project scoping remains intact.
- [ ] Links use canonical entity references.
- [ ] Destructive changes have integrity checks.
- [ ] Empty/loading/error states exist.
- [ ] Keyboard/mouse workflows work on desktop.
- [ ] UI uses the established design system.
- [ ] No placeholder data masquerades as persisted functionality.

## After Coding

- [ ] `dart analyze` clean.
- [ ] Unit tests for new domain logic.
- [ ] Widget tests for important interactions.
- [ ] Persistence survives restart.
- [ ] Existing data still loads.
- [ ] Linked entities navigate both ways.
- [ ] Delete/archive behavior is safe.
- [ ] Performance is acceptable with realistic data volume.
- [ ] Documentation updated if behavior changed.

## Vibe-Coding Prompt Pattern

When asking an AI coding agent to implement a module, provide:

```text
Read docs/modules/<module>.md first.
Inspect the existing Lore Keeper implementation before changing anything.
Implement the module according to the document and existing architecture.
Reuse shared components and models where they already exist.
Do not invent duplicate data models or mock functionality.
Preserve persisted data and add migrations when required.
Implement the domain behavior first, then the UI.
Run analyzer/tests and fix all errors before finishing.
```

The module MD is the source of product behavior; the repository is the source of current implementation reality.
