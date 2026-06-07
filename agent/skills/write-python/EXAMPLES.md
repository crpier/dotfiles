# Python Requirements Examples

Use these examples when a convention is unfamiliar or ambiguous. They are not a
complete restatement of the requirements.

## Docstrings

Good:

```python
"""Given a task function, dynamically build a
pydantic model that can validate its payload."""
```

Bad:

```python
"""Given a task function, dynamically build a pydantic model that can validate
its payload."""
```

## Structured logging

Good:

```python
logger.error("Failed to delete cluster.", cluster_name=cluster_name)
```

Bad:

```python
logger.error("Failed to delete cluster %s", cluster_name)
```

Bind repeated context once.

Good:

```python
logger = logger.bind(cluster_id=cluster_id, user_id=user_id)
logger.info("Starting provisioning")
logger.info("Provisioning finished")
```

Bad:

```python
logger.info("Starting provisioning", cluster_id=cluster_id, user_id=user_id)
logger.info("Provisioning finished", cluster_id=cluster_id, user_id=user_id)
```

## Imports

Use absolute imports.

Good:

```python
from package.module import function
```

Bad:

```python
from .module import function
from ..package import function
```

Alias third-party imports instead of stdlib imports.

Bad:

```python
from dataclasses import dataclass as std_dataclass
from pydantic.dataclasses import dataclass
```

Good:

```python
from dataclasses import dataclass
from pydantic.dataclasses import dataclass as pydantic_dataclass
```

## Timezone-aware datetimes

Good:

```python
from datetime import UTC, datetime, timedelta

expires_at = datetime.now(UTC) + timedelta(hours=DEFAULT_TTL_HOURS)
```

Bad:

```python
expires_at = datetime.now() + timedelta(hours=DEFAULT_TTL_HOURS)
```

## Domain types

Bad:

```python
def add_domain(domain: str) -> None:
    ...
```

Good:

```python
from annotations import ASCIIDomain

def add_domain(domain: ASCIIDomain) -> None:
    ...
```

## Regular class attributes

Bad:

```python
class MyClass:
    name: str

    def __init__(self, name: str) -> None:
        self.name = name
```

Good:

```python
class MyClass:
    def __init__(self, name: str) -> None:
        self.name: str = name
```

## Tests with local classes

Bad:

```python
class ClassUnderTest(Base):
    __table_name__: ClassVar[str] = "clusters"

@test()
def ClassUnderTest_is_validated() -> None:
    ...
```

Good:

```python
@test()
def ClassUnderTest_is_validated() -> None:
    class ClassUnderTest(Base):
        __table_name__: ClassVar[str] = "clusters"

    ...
```

## Fixture acquisition order

Good:

```python
@test()
def QueryBuilder_compiles_explicit_filters() -> None:
    """Compile explicit filters without merging them with runtime behavior."""
    fixture = load_fixture("query_builder_explicit_filters")

    class QueryBuilderUnderTest(QueryBuilder):
        ...

    result = QueryBuilderUnderTest(fixture).compile()

    assert result == fixture.expected_sql
```

Bad:

```python
@test()
def QueryBuilder_compiles_filters_and_sqlite_runtime() -> None:
    """Compile filters and check SQLite runtime behavior."""
    class QueryBuilderUnderTest(QueryBuilder):
        ...

    query_builder = QueryBuilderUnderTest()
    filter_fixture = load_fixture("query_builder_explicit_filters")
    runtime_fixture = load_fixture("sqlite_runtime")

    assert query_builder.compile(filter_fixture) == filter_fixture.expected_sql
    assert sqlite_runtime_accepts(runtime_fixture)
```

## Arrange/Act/Assert separation

Good:

```python
@test()
async def UserRepository_updates_selected_users() -> None:
    """Update matching users without testing unrelated result-shape behavior."""
    database = await load_fixture(database_with_seeded_users())

    async with database.transaction() as tx:
        await tx.execute(update(User).set(active=False).where(User.age < 18))

    async with database.transaction() as tx:
        rows = await tx.fetch_all(select(User.id, User.active).all())

    assert_eq(rows, [("ada", True), ("grace", False)])
```

Bad:

```python
@test()
async def UserRepository_full_insert_update_and_select_surface() -> None:
    """Insert, update, fetch result shape, and assert lifecycle behavior."""
    async with database.transaction() as tx:
        await tx.execute(insert(User).values(id="grace", age=17))
        await tx.execute(update(User).set(active=False).where(User.age < 18))
        rows = await tx.fetch_all(select(User.id, User.active).all())

        assert_eq(rows, [("grace", False)])
        assert await tx.fetch_one(select(count()).from_(User)) == 1
```

## Lint suppressions

Good:

```python
def method(self, unused_argument: str) -> None:  # noqa: ARG002 - protocol
    ...
```

For TRY301 in tests, suppress the line instead of extracting a raise-only
helper.

Good:

```python
@test()
def DatabaseUnavailableError_is_caught() -> None:
    caught_error: DatabaseUnavailableError | None = None

    try:
        raise DatabaseUnavailableError("down")  # noqa: TRY301
    except DatabaseUnavailableError as e:
        caught_error = e

    assert caught_error is not None
```

Bad:

```python
def raise_database_unavailable_error() -> None:
    raise DatabaseUnavailableError("down")

@test()
def DatabaseUnavailableError_is_caught() -> None:
    caught_error: DatabaseUnavailableError | None = None

    try:
        raise_database_unavailable_error()
    except DatabaseUnavailableError as e:
        caught_error = e

    assert caught_error is not None
```

## Pydantic

Good:

```python
from typing import ClassVar

from pydantic import BaseModel

class MyModel(BaseModel):
    name: str

    model_config = {
        "extra": "forbid",
    }
```
