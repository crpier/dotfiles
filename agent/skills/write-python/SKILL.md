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
- Use `get_` only for pure non-IO functions. Use `fetch_` for IO that returns a
  value.
- Prefer custom domain types over primitives for validated domain concepts.
- Prefer locality of behavior over aggressive DRY.
- Do not introduce an abstraction until there are at least two implementations.
- Do not create passthrough functions or tiny single-use helpers unless they
  clarify genuinely complex logic.
- Keep helpers local to their scope: one class -> private method/staticmethod;
  one method -> nested function or inline.
- Prefer context managers over manual resource management.
- Raise project/domain exceptions, never stdlib exceptions. Use
  `raise DomainError(...) from e` when wrapping another exception.
- Convert domain exceptions to HTTP exceptions at API boundaries.

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
- Private-helper docstrings should explain why the helper exists and what
  invariant it protects, not restate each line of code.
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
- Test names may omit `test_`; keep them short and descriptive.
- Use test function docstrings to explain the case.
- Define classes under test inside the test function when practical.
- Prefer fakes for external services and test databases for database behavior.
- Avoid `cast()` in tests; it usually indicates poor testability.

## References

- Open [REQUIREMENTS.md](REQUIREMENTS.md) for nuance and edge cases.
- Open [EXAMPLES.md](EXAMPLES.md) when applying an unfamiliar convention or
  reviewing ambiguous code.
