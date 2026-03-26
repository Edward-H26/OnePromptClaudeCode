---
name: security-review
description: Use this skill when adding authentication, handling user input, working with secrets, creating API endpoints, or implementing sensitive features. Provides comprehensive security checklist and patterns.
origin: ECC-adapted
---

# Security Review Skill

Ensures all code follows security best practices and identifies potential vulnerabilities.

**See Also**: `security-scan` skill for auditing Claude Code configuration (hooks, settings, permissions) rather than application code.

## When to Activate

- Implementing authentication or authorization
- Handling user input or file uploads
- Creating new API endpoints
- Working with secrets or credentials
- Storing or transmitting sensitive data
- Integrating third-party APIs

## Security Checklist

### 1. Secrets Management

```typescript
const apiKey = process.env.OPENAI_API_KEY
const dbUrl = process.env.DATABASE_URL

if (!apiKey) {
  throw new Error("OPENAI_API_KEY not configured")
}
```

```python
import os

api_key = os.environ["OPENAI_API_KEY"]
db_url = os.environ["DATABASE_URL"]
```

#### Verification Steps
- [ ] No hardcoded API keys, tokens, or passwords
- [ ] All secrets in environment variables
- [ ] `.env.local` in .gitignore
- [ ] No secrets in git history
- [ ] Production secrets in hosting platform

### 2. Input Validation

#### TypeScript (Zod)
```typescript
import { z } from "zod"

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150)
})

export async function createUser(input: unknown) {
  const validated = CreateUserSchema.parse(input)
  return await db.users.create(validated)
}
```

#### Python (Pydantic)
```python
from pydantic import BaseModel, EmailStr, Field

class CreateUserInput(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    age: int = Field(ge=0, le=150)
```

#### File Upload Validation
```typescript
function validateFileUpload(file: File) {
  const MAX_SIZE = 5 * 1024 * 1024
  if (file.size > MAX_SIZE) {
    throw new Error("File too large (max 5MB)")
  }

  const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/gif"]
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error("Invalid file type")
  }

  return true
}
```

#### Verification Steps
- [ ] All user inputs validated with schemas
- [ ] File uploads restricted (size, type, extension)
- [ ] No direct use of user input in queries
- [ ] Whitelist validation (not blacklist)
- [ ] Error messages do not leak sensitive info

### 3. SQL Injection Prevention

```typescript
const { data } = await supabase
  .from("users")
  .select("*")
  .eq("email", userEmail)

await db.query(
  "SELECT * FROM users WHERE email = $1",
  [userEmail]
)
```

```python
cursor.execute(
    "SELECT * FROM users WHERE email = %s",
    (user_email,)
)
```

#### Verification Steps
- [ ] All database queries use parameterized queries
- [ ] No string concatenation in SQL
- [ ] ORM/query builder used correctly

### 4. Authentication and Authorization

#### JWT Token Handling
```typescript
res.setHeader("Set-Cookie",
  `token=${token}; HttpOnly; Secure; SameSite=Strict; Max-Age=3600`)
```

#### Authorization Checks
```typescript
export async function deleteUser(userId: string, requesterId: string) {
  const requester = await db.users.findUnique({
    where: { id: requesterId }
  })

  if (requester.role !== "admin") {
    return NextResponse.json(
      { error: "Unauthorized" },
      { status: 403 }
    )
  }

  await db.users.delete({ where: { id: userId } })
}
```

#### Verification Steps
- [ ] Tokens stored in httpOnly cookies (not localStorage)
- [ ] Authorization checks before sensitive operations
- [ ] Role-based access control implemented
- [ ] Session management secure

### 5. XSS Prevention

#### Sanitize HTML
```typescript
import DOMPurify from "isomorphic-dompurify"

function renderUserContent(html: string) {
  const clean = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ["b", "i", "em", "strong", "p"],
    ALLOWED_ATTR: []
  })
  return <div dangerouslySetInnerHTML={{ __html: clean }} />
}
```

#### Content Security Policy
```typescript
const securityHeaders = [
  {
    key: "Content-Security-Policy",
    value: `
      default-src 'self';
      script-src 'self' 'unsafe-eval' 'unsafe-inline';
      style-src 'self' 'unsafe-inline';
      img-src 'self' data: https:;
      connect-src 'self' https://api.example.com;
    `.replace(/\s{2,}/g, " ").trim()
  }
]
```

#### Verification Steps
- [ ] User-provided HTML sanitized
- [ ] CSP headers configured
- [ ] No unvalidated dynamic content rendering

### 6. CSRF Protection

```typescript
export async function POST(request: Request) {
  const token = request.headers.get("X-CSRF-Token")

  if (!csrf.verify(token)) {
    return NextResponse.json(
      { error: "Invalid CSRF token" },
      { status: 403 }
    )
  }
}
```

#### Verification Steps
- [ ] CSRF tokens on state-changing operations
- [ ] SameSite=Strict on all cookies

### 7. Rate Limiting

```typescript
import rateLimit from "express-rate-limit"

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: "Too many requests"
})

app.use("/api/", limiter)
```

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.get("/api/search")
@limiter.limit("10/minute")
async def search(request: Request):
    pass
```

#### Verification Steps
- [ ] Rate limiting on all API endpoints
- [ ] Stricter limits on expensive operations
- [ ] IP-based and user-based rate limiting

### 8. Sensitive Data Exposure

```typescript
logger.info("User login:", { email, userId })
logger.info("Payment:", { last4: card.last4, userId })
```

```typescript
catch (error) {
  logger.error("Internal error:", error)
  return NextResponse.json(
    { error: "An error occurred. Please try again." },
    { status: 500 }
  )
}
```

#### Verification Steps
- [ ] No passwords, tokens, or secrets in logs
- [ ] Error messages generic for users
- [ ] No stack traces exposed to users

### 9. Dependency Security

```bash
npm audit
npm audit fix
npm outdated

pip-audit
safety check
```

#### Verification Steps
- [ ] Dependencies up to date
- [ ] No known vulnerabilities
- [ ] Lock files committed
- [ ] Regular security updates

## Security Testing

```typescript
test("requires authentication", async () => {
  const response = await fetch("/api/protected")
  expect(response.status).toBe(401)
})

test("requires admin role", async () => {
  const response = await fetch("/api/admin", {
    headers: { Authorization: `Bearer ${userToken}` }
  })
  expect(response.status).toBe(403)
})

test("rejects invalid input", async () => {
  const response = await fetch("/api/users", {
    method: "POST",
    body: JSON.stringify({ email: "not-an-email" })
  })
  expect(response.status).toBe(400)
})
```

## Pre-Deployment Security Checklist

- [ ] **Secrets**: No hardcoded secrets, all in env vars
- [ ] **Input Validation**: All user inputs validated
- [ ] **SQL Injection**: All queries parameterized
- [ ] **XSS**: User content sanitized
- [ ] **CSRF**: Protection enabled
- [ ] **Authentication**: Proper token handling
- [ ] **Authorization**: Role checks in place
- [ ] **Rate Limiting**: Enabled on all endpoints
- [ ] **HTTPS**: Enforced in production
- [ ] **Security Headers**: CSP, X-Frame-Options configured
- [ ] **Error Handling**: No sensitive data in errors
- [ ] **Logging**: No sensitive data logged
- [ ] **Dependencies**: Up to date, no vulnerabilities
- [ ] **CORS**: Properly configured
- [ ] **File Uploads**: Validated (size, type)

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Web Security Academy](https://portswigger.net/web-security)
