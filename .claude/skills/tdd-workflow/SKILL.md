---
name: tdd-workflow
description: Test-driven development methodology with RED-GREEN-REFACTOR cycle and 80%+ coverage. Activates when user explicitly requests TDD or test-first development.
origin: ECC-adapted
---

# Test-Driven Development Workflow

TDD methodology for when test-first development is explicitly requested.

Note: This skill complements CLAUDE-testing.md. The default testing policy is "run existing tests, do not write new ones unless explicitly requested." This skill activates only when TDD is explicitly requested.

## When to Activate

- User explicitly requests TDD or test-first development
- User says "write tests first" or "red green refactor"
- User wants comprehensive test coverage for new features

## Core Principles

### 1. Tests BEFORE Code
Write tests first, then implement code to make tests pass.

### 2. Coverage Requirements
- Minimum 80% coverage (unit + integration + E2E)
- All edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Types

| Type | Scope | Examples |
|------|-------|---------|
| Unit | Individual functions | Pure functions, utilities, helpers |
| Integration | Component interactions | API endpoints, database ops, service calls |
| E2E | Full user flows | Browser automation, complete workflows |

## TDD Workflow Steps

### Step 1: Write User Journeys
```
As a [role], I want to [action], so that [benefit]
```

### Step 2: Generate Test Cases

```typescript
describe("Search Feature", () => {
  it("returns relevant results for query", async () => {
    // Test implementation
  })

  it("handles empty query gracefully", async () => {
    // Test edge case
  })

  it("falls back when service unavailable", async () => {
    // Test fallback behavior
  })

  it("sorts results by relevance score", async () => {
    // Test sorting logic
  })
})
```

### Step 3: Run Tests (They Should Fail)
```bash
npm test       # TypeScript/JavaScript
pytest         # Python
```

### Step 4: Implement Code
Write minimal code to make tests pass.

### Step 5: Run Tests Again
```bash
npm test       # Should now pass
pytest         # Should now pass
```

### Step 6: Refactor
Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Optimize performance

### Step 7: Verify Coverage
```bash
npm run test:coverage
pytest --cov=mypackage --cov-report=term-missing
```

## Testing Patterns

### Unit Test (Jest/Vitest)
```typescript
import { render, screen, fireEvent } from "@testing-library/react"
import { Button } from "./Button"

describe("Button Component", () => {
  it("renders with correct text", () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText("Click me")).toBeInTheDocument()
  })

  it("calls onClick when clicked", () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click</Button>)
    fireEvent.click(screen.getByRole("button"))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it("is disabled when disabled prop is true", () => {
    render(<Button disabled>Click</Button>)
    expect(screen.getByRole("button")).toBeDisabled()
  })
})
```

### Unit Test (pytest)
```python
import pytest

class TestCalculator:
    @pytest.fixture
    def calculator(self):
        return Calculator()

    def test_add(self, calculator):
        assert calculator.add(2, 3) == 5

    def test_divide_by_zero(self, calculator):
        with pytest.raises(ZeroDivisionError):
            calculator.divide(10, 0)
```

### API Integration Test
```typescript
describe("GET /api/items", () => {
  it("returns items successfully", async () => {
    const request = new NextRequest("http://localhost/api/items")
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(Array.isArray(data.data)).toBe(true)
  })

  it("validates query parameters", async () => {
    const request = new NextRequest("http://localhost/api/items?limit=invalid")
    const response = await GET(request)
    expect(response.status).toBe(400)
  })
})
```

### E2E Test (Playwright)
```typescript
import { test, expect } from "@playwright/test"

test("user can search and filter items", async ({ page }) => {
  await page.goto("/")
  await page.click('a[href="/items"]')
  await expect(page.locator("h1")).toContainText("Items")

  await page.fill('input[placeholder="Search"]', "test")
  await page.waitForResponse(resp => resp.url().includes("/api/search"))

  const results = page.locator('[data-testid="item-card"]')
  await expect(results).toHaveCount(5, { timeout: 5000 })
})
```

## Test File Organization

```
src/
├── components/
│   └── Button/
│       ├── Button.tsx
│       └── Button.test.tsx
├── app/
│   └── api/
│       └── items/
│           ├── route.ts
│           └── route.test.ts
└── e2e/
    ├── search.spec.ts
    └── auth.spec.ts
```

## Mocking External Services

```typescript
jest.mock("@/lib/database", () => ({
  db: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => Promise.resolve({
          data: [{ id: 1, name: "Test Item" }],
          error: null
        }))
      }))
    }))
  }
}))
```

## Coverage Thresholds

```json
{
  "jest": {
    "coverageThresholds": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## Common Mistakes to Avoid

- Do not test implementation details; test user-visible behavior
- Do not use brittle CSS selectors; use semantic selectors or data-testid
- Do not share state between tests; each test should be independent
- Do not catch exceptions in tests; use `pytest.raises` or `expect().toThrow()`

## Best Practices

1. Write tests first (RED-GREEN-REFACTOR)
2. One assertion per test
3. Descriptive test names: `test_user_login_with_invalid_credentials_fails`
4. Use fixtures to eliminate duplication
5. Mock external dependencies
6. Test edge cases: null, undefined, empty, boundary values
7. Keep tests fast (unit tests < 50ms each)
8. Clean up after tests (no side effects)
