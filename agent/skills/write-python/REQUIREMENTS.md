# Opinionated Python Requirements

This file adds nuance that is too detailed for `SKILL.md`. The rules are hard
requirements unless they use softer words like `should` or `prefer`.

## How to apply these requirements

Local consistency matters, but it never overrides a hard requirement. If a file
already violates a hard requirement, do not spread the pattern. Prefer the
smallest change that improves the touched code without forcing unrelated churn.

When requirements conflict, prioritize in this order:

1. Correctness and safety.
2. Public API compatibility.
3. Hard requirements in `SKILL.md`.
4. Local consistency.
5. Soft preferences.

## Type hints

Annotate private code too. Missing annotations are not acceptable just because a
function is private, nested, or test-only.

Prefer specific types over `Any`. If `Any` is necessary at a boundary, keep it
localized and convert it to domain types as soon as practical.

Avoid `cast()`. If it is necessary, add a nearby comment explaining why the cast
is safe and why a more precise type is not practical. Prefer `cast()` over a
broad `type: ignore`, but do not use either casually.

## Constants and docstrings

Constants should almost always have docstrings or be self-explanatory in a very
small local scope. Use a docstring when the value encodes policy, tuning,
protocol behavior, or a domain assumption.

Function and class docstrings should explain the `what` and/or `why`. Explain
implementation details only when behavior is surprising or easy to misuse.
Do not use generated-looking `Args:`, `Returns:`, or `Raises:` sections.

Wrapped docstring lines should be balanced rather than leaving one very long
line followed by a tiny fragment.

## Naming

Use explicit names over abbreviations. Prefer names that encode domain meaning,
such as `database_session`, `request_logger`, or `cluster_status`.

Avoid bare `id` when a more precise name exists, such as `user_id` or
`cluster_id`.

Conventional short names are allowed only in very small, conventional scopes,
such as `async with self.database as tx:`.

Use `get_` only for pure, non-IO functions. Use `fetch_` when returning a value
requires IO, even if the IO is hidden behind a client or repository object.

## Imports

Absolute imports make dependencies explicit and reduce ambiguity during
refactors. Do not use relative imports, including `from .module import Name`.

Prefer `from package import Name` because it makes used names explicit. Bare
`import module` is reserved for name conflicts and the approved stdlib modules
listed in `SKILL.md`.

Do not alias standard library imports. If a stdlib name conflicts with a
third-party name, alias the third-party import.

## Public APIs

Use package `__init__.py` files to define meaningful public APIs. If a package
has no curated public surface, keep `__init__.py` empty. Do not leave an
`__init__.py` containing only a docstring.

Keep `__all__` sorted lexically. Update it during renames, moves, and refactors,
not only when adding new exports.

## Async and IO

All IO must be async. This includes network calls, subprocesses, filesystem
work, database calls, and calls into SDKs that perform IO.

If a dependency has no async API, isolate the blocking call and run it through
an executor using `asyncio`. Do not hide blocking IO inside an `async def`.

Never perform IO at import time. Importing a module should not open files,
connect to services, read environment-dependent remote state, start background
tasks, or do expensive computation.

## Error handling

Raise project or domain exceptions instead of stdlib exceptions. Wrapping an
underlying exception is fine when it preserves useful causality:
`raise DomainError(...) from e`.

Catch exceptions at the level that has enough context to handle, log, retry, or
translate them. At API boundaries, translate domain exceptions into HTTP
exceptions or the framework's boundary type.

For Ruff TRY301 (`raise-within-try`), first restructure production code so the
raise does not happen inside the `try` block. If the surrounding control flow
really needs to raise inside `try`, ignore the raise line with
`# noqa: TRY301`. Do not create a passthrough or one-line helper that only
raises an error just to satisfy the rule.

Name caught exceptions `e`, unless that would shadow an existing name in the
same scope.

## Logging

Use structured logging with keyword arguments. Do not interpolate values into
messages with `%s` or f-strings when they should be searchable context.

Bind stable context in the callee when multiple log lines share the same
attributes. This keeps each log call focused on the event, not repeated context.

## Datetimes

Always use timezone-aware datetimes. Prefer `datetime.now(UTC)` from the stdlib.
Do not create new naive datetimes unless working with an API that explicitly
requires naive values, and document the boundary conversion.

## Ordering

At module scope, define private functions before public functions. Within those
groups, put called helpers before callers so readers encounter building blocks
before orchestration.

Inside classes, use the public reading order instead: callers before called
private helpers. This keeps the public behavior near the top of the class and
implementation details below it.

For dataclasses, Pydantic models, and similar declarative structures, sort
fields alphabetically unless semantic grouping is intentionally clearer. If a
non-alphabetical order could look accidental, add a brief comment.

## Classes

Regular classes should not declare instance attributes in the class body. Put
instance attributes in `__init__` and annotate every assignment explicitly, even
when the type is obvious from the constructor parameter.

This rule does not apply to dataclasses, Pydantic models, attrs classes, or
other declarative class systems where class-body fields are the API.

## Tests

Use `snektest` with `@test()`. The decorated function name is the test name, so
it may omit `test_` even though test files still use `test_*.py`.

Tests must verify one behavior at a time. Do not write “full surface”,
“end-to-end everything”, or umbrella tests that combine multiple independent
behaviors like insert + select result shapes + update + delete in one test.
Split them into focused tests with names that state the single behavior under
test.

Setup may use supporting operations, but assertions should target one behavior.
For example, a select test may insert records as setup, but the assertions
should verify only the selected result-shape behavior. If a test has unrelated
assertion groups or naturally has two independent assertion branches, split it
into focused tests with names that describe each behavior.

Tests must not mix setup, behavior under test, and assertions in the same
logical block. Use fixtures or clearly separated helper setup when setup is
non-trivial, especially for database state. The test body should make the
behavior under test obvious.

Avoid doing setup inserts, the mutation under test, and result
fetching/assertion all inside one transaction or block unless the transaction
boundary itself is the behavior under test. Prefer this shape:

```python
database = await load_fixture(database_with_seeded_users())

async with database.transaction() as tx:
    await tx.execute(update(User).set(...).where(...))

async with database.transaction() as tx:
    rows = await tx.fetch_all(select(...).all())

assert_eq(rows, expected)
```

Avoid tests that exercise unrelated runtimes, backends, adapters, or policies in
the same test. For example, SQLite runtime behavior and MariaDB runtime behavior
should be separate tests.

Prefer separate tests for result-shape behavior, mutation behavior, error
behavior, lifecycle behavior, and backend policy behavior.

Keep test names short and descriptive. Prefer names that state the single
behavior under test, not umbrella names like `covers X, Y, and Z`. If a test
name contains words like “full”, “surface”, “and”, or lists multiple verbs,
challenge whether it should be multiple tests. Use the test function docstring
for the case description or scenario details.

Fixture loading should happen at the top of the test body, immediately after the
docstring and before local classes, setup logic, or assertions. Use fixtures to
create external resources and seed prerequisite state. Mid-test
`load_fixture(...)` is a smell: either move fixture acquisition to the top, or
split the test so each test has its own clear setup and behavior.

When a class or module exists only to exercise behavior under test, define it
inside the test function when practical. External fixtures should be acquired
first so the test's dependencies are visible immediately.

Use test databases for database behavior and fake services for external systems.
Clean up test data after tests.

Do not mark TDD phases with comments like `RED` or `GREEN`.

If a test violates Ruff TRY301 (`raise-within-try`), ignore it on the same line
with `# noqa: TRY301`. Do not extract a one-line helper whose only behavior is
raising the error.

Avoid `cast()` in tests even more strongly than in library code. It usually
means the production code is hard to test or the test is reaching through the
wrong interface.

## Comments and suppressions

Do not write comments that merely narrate the next line of code. Comments should
explain non-obvious constraints, tradeoffs, ordering, invariants, or history
that affects the code.

Use suppression comments sparingly and scope them to the smallest possible
surface. Most suppressions must include a short reason inline or in the comment
immediately above.

TODO levels:

- `# TODO:` can be merged to `main`.
- `# FIXME:` can be committed on a branch, but should not merge to `main`.
- `# XXX:` should be fixed before committing.

## Function size, helper locality, and abstractions

There is no default preference for short functions. Prefer deep modules: narrow
interfaces with substantial implementation behind them.

Avoid passthrough, one-line, and single-use functions unless they clarify
genuinely complex logic. Never add a function whose only purpose is to move a
single expression, raise statement, or lint violation somewhere else. A function
may handle multiple related responsibilities when that keeps behavior local and
easier to understand.

Keep helpers local to their scope. If a private helper is only used by one
class, make it a private method or staticmethod on that class. If it is only
used by one method, define it inside that method or inline it.

Locality of behavior and DRY often conflict. Prefer locality when removing
repetition would scatter the behavior or create a premature abstraction.

Do not create an abstraction until there are at least two implementations.

## Pydantic

Use `model_config` as a dictionary. It doesn't need to be typed, as the
`pydantic` model already has a type annotation.
