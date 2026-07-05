---
name: write-python
description: Apply an opinionated Python style guide focused on typed, async-safe, testable, domain-rich code. Use when writing, modifying, refactoring, or reviewing Python code, especially when the user asks for Python style, conventions, tests, imports, logging, typing, or API boundaries.
---

# Write Python

Use this skill whenever producing or changing Python code. These rules are hard
requirements unless they use softer words like `should` or `prefer`. Prefer
consistency with surrounding code only where it does not conflict with a hard
requirement.

## Core requirements

- Add type hints to all functions, methods, and class attributes.
- Use Python 3.10+ type syntax: `str | int`, `list[str]`, `dict[str, int]`.
- Keep lines to 88 chars, except long log/error messages where `E501` is
  allowed.
- Start every non-empty module with a module docstring.
- Avoid import-time work. Never perform IO at import time.
- Use async APIs for all IO. If no async API exists, run blocking work in an
  executor.
- Use timezone-aware datetimes: `datetime.now(UTC)`, never bare
  `datetime.now()`.

## Naming, design, and errors

- Prefer explicit, domain-rich names: `attribute_index`, `database_session`,
  `cluster_status`; avoid abbreviations and one-letter names.
- A name should add information. If the receiving keyword already gives a value
  its meaning, do not create a temporary name just to repeat it.
- Do not introduce single-use local variables for simple literals or simple
  constructors when the value is immediately passed to a named argument. Inline
  the value instead. A temporary variable is appropriate only when it is reused,
  the expression is complex enough to obscure the call site, or the name adds
  domain meaning that is not already present in the destination parameter.
- Avoid generic single-use temporaries like `timestamp`, `data`, `result`,
  `value`, or `payload` when they only restate the type or shape of the value.
  Either inline the expression or use a domain name such as
  `event_happened_at`, `published_at`, or `retry_deadline`.
- Use `get_` only for pure non-IO functions. Use `fetch_` for IO that returns a
  value.
- Prefer custom domain types over primitives for validated domain concepts.
- Prefer locality of behavior over aggressive DRY.
- Do not introduce an abstraction until there are at least two implementations.
- Do not create passthrough, one-line, or tiny single-use functions unless
  they clarify genuinely complex logic. Never create a one-line helper solely
  to satisfy a lint rule.
- Keep helpers local to their scope: one class -> private method/staticmethod;
  one method -> nested function or inline.
- Prefer context managers over manual resource management.
- Raise project/domain exceptions, never stdlib exceptions. Use
  `raise DomainError(...) from e` when wrapping another exception.
- For Ruff TRY301 (`raise-within-try`), restructure production code to avoid
  raising inside `try`; if truly unavoidable, ignore the raise line with
  `# noqa: TRY301`. Do not create a one-line function that only raises.
- Convert domain exceptions to HTTP exceptions at API boundaries.

### Single-use temporaries

Prefer:

```python
pending_event = Event(
    enabled=True,
    happened_at=datetime(2026, 1, 2, 3, 4, 5, 678901, tzinfo=UTC),
    payload={"ok": True},
)
```

Avoid:

```python
timestamp = datetime(2026, 1, 2, 3, 4, 5, 678901, tzinfo=UTC)
pending_event = Event(
    enabled=True,
    happened_at=timestamp,
    payload={"ok": True},
)
```

## Imports and public APIs

- Use absolute imports only. Never use relative imports.
- Prefer `from package import Name` syntax.
- Use bare `import module` only for name conflicts or these stdlib modules:
  `os`, `sys`, `time`, `logging`, `asyncio`, `pathlib`, `subprocess`,
  `threading`, `contextlib`.
- Do not alias stdlib imports; alias third-party imports instead when needed.
- `__init__.py` files should either curate `__all__` or be empty.
- Keep `__all__` sorted lexically and update it when exports change, including
  renames and refactors.

## Ordering and classes

- At module scope, order functions as private functions, then public functions;
  within those groups, define called helpers before callers.
- In classes, order methods as `__init__`/`__new__`, ABC/protocol methods,
  public methods, private methods.
- Only inside classes, define caller methods before called methods.
- In regular classes, declare instance attributes in `__init__` with explicit
  types: `self.name: str = name`.
- Do not declare regular instance attributes in the class body unless using a
  dataclass, Pydantic model, or similar declarative structure.
- Sort fields alphabetically in dataclasses, Pydantic models, and similar
  structures unless semantic grouping is clearer.

## Docstrings, comments, and logging

- Most functions and classes should have docstrings. Constants should almost
  always have docstrings.
- Public functions and classes, especially classes, should have runnable Python
  usage examples in docstrings.
- Private helpers should have docstrings when they encode non-obvious behavior,
  domain rules, validation rules, state transitions, SQL/query compilation,
  concurrency behavior, or error translation.
- Do not require docstrings for tiny local helpers whose name fully explains
  their behavior.
- Docstrings target markdown, not rst: quote inline code with single backticks
  (`loose`), not rst double backticks (``loose``); avoid rst roles/directives.
- Private-helper docstrings should explain why the helper exists and what
  invariant it protects, not restate each line of code.
- Do not reference external project-management or decision-tracking artifacts in
  docstrings or comments: issue/ticket numbers, ADR numbers, story or acceptance
  -criterion numbers, "slice", "epic", "vertical slice", sprint or milestone
  names. State the domain rule or invariant directly. The code is the source of
  truth, not a pointer into a tracker; such references rot and mean nothing to a
  reader without the tracker. Domain vocabulary and the real reasoning stay;
  only the citation goes.
- Prefer this shape for internal helpers:

  ```python
  def _compile_predicates_sql(...) -> ...:
      """Compile accumulated where() predicates as AND-ed SQL fragments.

      Query builders store repeated where() calls as separate predicates so the
      explicit-filter intent remains observable until compilation.
      """
  ```

- Explain the `what` and/or `why`; explain the `how` only if surprising.
- Do not include `Args:`, `Returns:`, or `Raises:` sections.
- Use triple double quotes; no blank line after opening quotes or before
  closing quotes.
- Avoid comments that restate code. Comments should tell a story.
- TODO forms: `# TODO:` may merge; `# FIXME:` may commit but not merge;
  `# XXX:` must be fixed before committing.
- Use structured logging with keyword context, not `%s` interpolation.
- Bind stable logging context once when multiple log lines share attributes.

## Testing

- Use `snektest` with `@test()` and typed test functions.
- Tests must verify one behavior at a time. Do not write “full surface”,
  “end-to-end everything”, or umbrella tests that combine multiple independent
  behaviors like insert + select result shapes + update + delete in one test.
  Split them into focused tests with names that state the single behavior under
  test.
- Setup may use supporting operations, but assertions should target one
  behavior. If a test has unrelated assertion groups, split it.
- Tests must not mix setup, behavior under test, and assertions in the same
  logical block. Use fixtures or clearly separated helper setup when setup is
  non-trivial, especially for database state.
- If a test name contains words like “full”, “surface”, “and”, or lists
  multiple verbs, challenge whether it should be multiple tests.
- Prefer separate tests for result-shape behavior, mutation behavior, error
  behavior, lifecycle behavior, and backend policy behavior.
- Use test function docstrings to explain the case.
- Load fixtures at the top of the test body, immediately after the docstring.
  Mid-test `load_fixture(...)` is a smell; move it up or split the test.
- Use fixtures to create external resources and seed prerequisite state.
- The test body should make the behavior under test obvious.
- Avoid doing setup inserts, the mutation under test, and result
  fetching/assertion all inside one transaction/block unless the transaction
  boundary itself is the behavior under test.
- Define local classes under test after external fixture acquisition.
- Prefer fakes for external services and test databases for database behavior.
- In tests, ignore Ruff TRY301 violations on the same line with
  `# noqa: TRY301`; do not extract a one-line raising helper.
- Avoid `cast()` in tests; it usually indicates poor testability.

## References

- Open [REQUIREMENTS.md](REQUIREMENTS.md) for nuance and edge cases.
- Open [EXAMPLES.md](EXAMPLES.md) when applying an unfamiliar convention or
  reviewing ambiguous code.
