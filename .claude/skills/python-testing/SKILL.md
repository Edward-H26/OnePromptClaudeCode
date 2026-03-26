---
name: python-testing
description: Python testing strategies using pytest, TDD methodology, fixtures, mocking, parametrization, and coverage requirements.
origin: ECC-adapted
---

# Python Testing Patterns

Comprehensive testing strategies for Python applications using pytest.

## When to Activate

- Writing tests for Python code
- Designing test suites for Python projects
- Reviewing Python test coverage
- Setting up testing infrastructure

## Core Testing Philosophy

### Test-Driven Development (TDD)

Follow the TDD cycle when tests are explicitly requested:

1. **RED**: Write a failing test for the desired behavior
2. **GREEN**: Write minimal code to make the test pass
3. **REFACTOR**: Improve code while keeping tests green

### Coverage Requirements

- **Target**: 80%+ code coverage
- **Critical paths**: 100% coverage required

```bash
pytest --cov=mypackage --cov-report=term-missing --cov-report=html
```

## pytest Fundamentals

### Basic Test Structure

```python
import pytest

def test_addition():
    assert 2 + 2 == 4

def test_string_uppercase():
    text = "hello"
    assert text.upper() == "HELLO"

def test_list_append():
    items = [1, 2, 3]
    items.append(4)
    assert 4 in items
    assert len(items) == 4
```

### Assertions

```python
assert result == expected
assert result != unexpected
assert result is None
assert item in collection
assert isinstance(result, str)

with pytest.raises(ValueError):
    raise ValueError("error message")

with pytest.raises(ValueError, match="invalid input"):
    raise ValueError("invalid input provided")

with pytest.raises(ValueError) as exc_info:
    raise ValueError("error message")
assert str(exc_info.value) == "error message"
```

## Fixtures

### Basic Fixture Usage

```python
@pytest.fixture
def sample_data():
    return {"name": "Alice", "age": 30}

def test_sample_data(sample_data):
    assert sample_data["name"] == "Alice"
    assert sample_data["age"] == 30
```

### Fixture with Setup/Teardown

```python
@pytest.fixture
def database():
    db = Database(":memory:")
    db.create_tables()
    db.insert_test_data()
    yield db
    db.close()

def test_database_query(database):
    result = database.query("SELECT * FROM users")
    assert len(result) > 0
```

### Fixture Scopes

```python
@pytest.fixture(scope="module")
def module_db():
    db = Database(":memory:")
    db.create_tables()
    yield db
    db.close()

@pytest.fixture(scope="session")
def shared_resource():
    resource = ExpensiveResource()
    yield resource
    resource.cleanup()
```

### Autouse Fixtures

```python
@pytest.fixture(autouse=True)
def reset_config():
    Config.reset()
    yield
    Config.cleanup()
```

### Conftest.py for Shared Fixtures

```python
# tests/conftest.py
@pytest.fixture
def client():
    app = create_app(testing=True)
    with app.test_client() as client:
        yield client

@pytest.fixture
def auth_headers(client):
    response = client.post("/api/login", json={
        "username": "test",
        "password": "test"
    })
    token = response.json["token"]
    return {"Authorization": f"Bearer {token}"}
```

## Parametrization

```python
@pytest.mark.parametrize("input_val,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
    ("PyThOn", "PYTHON"),
])
def test_uppercase(input_val, expected):
    assert input_val.upper() == expected

@pytest.mark.parametrize("a,b,expected", [
    (2, 3, 5),
    (0, 0, 0),
    (-1, 1, 0),
    (100, 200, 300),
])
def test_add(a, b, expected):
    assert add(a, b) == expected

@pytest.mark.parametrize("input_val,expected", [
    ("valid@email.com", True),
    ("invalid", False),
    ("@no-domain.com", False),
], ids=["valid-email", "missing-at", "missing-domain"])
def test_email_validation(input_val, expected):
    assert is_valid_email(input_val) is expected
```

## Markers and Test Selection

```python
@pytest.mark.slow
def test_slow_operation():
    time.sleep(5)

@pytest.mark.integration
def test_api_integration():
    response = requests.get("https://api.example.com")
    assert response.status_code == 200
```

```bash
pytest -m "not slow"
pytest -m integration
pytest -m "unit and not slow"
```

## Mocking and Patching

### Mocking Functions

```python
from unittest.mock import patch, Mock

@patch("mypackage.external_api_call")
def test_with_mock(api_call_mock):
    api_call_mock.return_value = {"status": "success"}
    result = my_function()
    api_call_mock.assert_called_once()
    assert result["status"] == "success"
```

### Mocking Exceptions

```python
@patch("mypackage.api_call")
def test_api_error_handling(api_call_mock):
    api_call_mock.side_effect = ConnectionError("Network error")
    with pytest.raises(ConnectionError):
        api_call()
```

### Using Autospec

```python
@patch("mypackage.DBConnection", autospec=True)
def test_autospec(db_mock):
    db = db_mock.return_value
    db.query("SELECT * FROM users")
    db_mock.assert_called_once()
```

### Mock Class Instances

```python
class TestUserService:
    @patch("mypackage.UserRepository")
    def test_create_user(self, repo_mock):
        repo_mock.return_value.save.return_value = User(id=1, name="Alice")
        service = UserService(repo_mock.return_value)
        user = service.create_user(name="Alice")
        assert user.name == "Alice"
        repo_mock.return_value.save.assert_called_once()
```

## Testing Async Code

```python
@pytest.mark.asyncio
async def test_async_function():
    result = await async_add(2, 3)
    assert result == 5

@pytest.mark.asyncio
@patch("mypackage.async_api_call")
async def test_async_mock(api_call_mock):
    api_call_mock.return_value = {"status": "ok"}
    result = await my_async_function()
    api_call_mock.assert_awaited_once()
    assert result["status"] == "ok"
```

## Testing with tmp_path

```python
def test_with_tmp_path(tmp_path):
    test_file = tmp_path / "test.txt"
    test_file.write_text("hello world")
    result = process_file(str(test_file))
    assert result == "hello world"
```

## Test Organization

```
tests/
├── conftest.py
├── unit/
│   ├── test_models.py
│   ├── test_utils.py
│   └── test_services.py
├── integration/
│   ├── test_api.py
│   └── test_database.py
└── e2e/
    └── test_user_flow.py
```

### Test Classes

```python
class TestUserService:
    @pytest.fixture(autouse=True)
    def setup(self):
        self.service = UserService()

    def test_create_user(self):
        user = self.service.create_user("Alice")
        assert user.name == "Alice"

    def test_delete_user(self):
        user = User(id=1, name="Bob")
        self.service.delete_user(user)
        assert not self.service.user_exists(1)
```

## pytest Configuration (pyproject.toml)

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--cov=mypackage",
    "--cov-report=term-missing",
]
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]
```

## Running Tests

```bash
pytest                                    # Run all tests
pytest tests/test_utils.py                # Specific file
pytest tests/test_utils.py::test_function # Specific test
pytest -v                                 # Verbose output
pytest --cov=mypackage --cov-report=html  # With coverage
pytest -m "not slow"                      # Skip slow tests
pytest -x                                 # Stop on first failure
pytest --lf                               # Run last failed
pytest -k "test_user"                     # Pattern match
pytest --pdb                              # Debugger on failure
```

## Quick Reference

| Pattern | Usage |
|---------|-------|
| `pytest.raises()` | Test expected exceptions |
| `@pytest.fixture()` | Create reusable test fixtures |
| `@pytest.mark.parametrize()` | Run tests with multiple inputs |
| `@pytest.mark.slow` | Mark slow tests |
| `@patch()` | Mock functions and classes |
| `tmp_path` fixture | Automatic temp directory |
| `pytest --cov` | Generate coverage report |
