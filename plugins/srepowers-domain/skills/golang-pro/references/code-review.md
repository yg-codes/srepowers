# Go Code Review

## Review Checklist

Apply in order. Each category maps to a section below with examples.

| # | Category | Focus |
|---|----------|-------|
| 1 | Error handling | Returned errors ignored, swallowed, or misclassified |
| 2 | Concurrency | Goroutine leaks, race conditions, missing context cancellation |
| 3 | Interface design | Over-abstraction, fat interfaces, interface returned where struct suffices |
| 4 | Package structure | Circular imports, `internal/` violations, coupling direction |
| 5 | Performance | Escape analysis, allocation hotspots, unnecessary copying |
| 6 | Testing | Missing edge cases, brittle tests, untested error paths |
| 7 | Security | SQL injection, unvalidated input, secret exposure |

---

## Error Handling

### Ignored return values

```go
// BAD — error silently discarded
rows, _ := db.QueryContext(ctx, "SELECT ...")
defer rows.Close()

// GOOD — always check errors
rows, err := db.QueryContext(ctx, "SELECT ...")
if err != nil {
    return fmt.Errorf("querying users: %w", err)
}
defer rows.Close()
```

### Lost error context

```go
// BAD — wraps with generic message, discards original
return fmt.Errorf("failed to process: %v", err)

// GOOD — wraps preserving chain for errors.Is/As
return fmt.Errorf("process user %q: %w", userID, err)
```

### Sentinel vs custom error types

```go
// BAD — string comparison for error matching
if err.Error() == "not found" { ... }

// GOOD — sentinel errors with errors.Is
if errors.Is(err, ErrNotFound) { ... }

// GOOD — custom error type with errors.As
var timeoutErr *TimeoutError
if errors.As(err, &timeoutErr) {
    return timeoutErr.RetryAfter
}
```

### Recover used as error handling

```go
// BAD — panic/recover for flow control
func divide(a, b int) (result int, err error) {
    defer func() {
        if r := recover(); r != nil {
            err = fmt.Errorf("division failed: %v", r)
        }
    }()
    return a / b, nil // panics on b == 0
}

// GOOD — explicit check, no panic
func divide(a, b int) (int, error) {
    if b == 0 {
        return 0, ErrDivisionByZero
    }
    return a / b, nil
}
```

### Indent error flow — guard clauses over if/else

```go
// BAD — normal path buried in else block
func process(data []byte) error {
    if len(data) > 0 {
        // 50 lines of normal logic deeply indented
        return nil
    } else {
        return errors.New("empty data")
    }
}

// GOOD — handle error first, keep normal path at minimal indentation
func process(data []byte) error {
    if len(data) == 0 {
        return errors.New("empty data")
    }
    // Normal logic at top level, easy to scan
    return nil
}
```

### In-band errors — sentinel values instead of proper error returns

```go
// BAD — caller must remember to check for empty string
func Lookup(key string) string

result := Lookup(key)
Parse(result) // Compiles silently — empty string causes confusing downstream error

// GOOD — separate ok/error return forces caller to handle the missing case
func Lookup(key string) (value string, ok bool)

value, ok := Lookup(key)
if !ok {
    return fmt.Errorf("no value for %q", key)
}
return Parse(value)
```

### Error string style

```go
// BAD — capitalized, ends with punctuation
return fmt.Errorf("Failed to connect to database.")
return fmt.Errorf("User not found!")

// GOOD — lowercase, no trailing punctuation (error is usually wrapped in context)
return fmt.Errorf("failed to connect to database")
return fmt.Errorf("user not found")
// So that log.Printf("reading %s: %v", path, err) reads naturally
```

---

## Concurrency Issues

### Goroutine leak — unbounded lifecycle

```go
// BAD — goroutine never exits if channel never closes
go func() {
    for val := range ch {
        process(val)
    }
}()

// GOOD — context cancellation + explicit done
go func() {
    defer close(done)
    for {
        select {
        case val, ok := <-ch:
            if !ok {
                return
            }
            process(val)
        case <-ctx.Done():
            return
        }
    }
}()
```

### Goroutine leak — WaitGroup Add inside goroutine

```go
// BAD — race on wg.Add, goroutine may run before Add
for _, item := range items {
    go func(it Item) {
        wg.Add(1)         // Too late — Wait() may have already returned
        defer wg.Done()
        process(it)
    }(item)
}
wg.Wait()

// GOOD — Add before goroutine starts
for _, item := range items {
    wg.Add(1)
    go func(it Item) {
        defer wg.Done()
        process(it)
    }(item)
}
wg.Wait()
```

### Missing mutex — shared state without synchronization

```go
// BAD — concurrent map write (will panic in practice)
var cache = make(map[string]string)

func set(key, val string) {
    cache[key] = val
}

// GOOD — protect with sync.RWMutex
type SafeCache struct {
    mu    sync.RWMutex
    items map[string]string
}

func (c *SafeCache) Set(key, val string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[key] = val
}

func (c *SafeCache) Get(key string) (string, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    val, ok := c.items[key]
    return val, ok
}
```

### Context not propagated

```go
// BAD — creates detached context, parent cancellation ignored
func process(ctx context.Context) error {
    ctx = context.Background() // Discards parent timeout/cancel
    return doWork(ctx)
}

// GOOD — derive from parent, add only what's needed
func process(ctx context.Context) error {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    return doWork(ctx)
}
```

### Context stored in struct

```go
// BAD — context as struct field, hides lifecycle from callers
type Service struct {
    ctx context.Context
}

func (s *Service) DoWork() error {
    return doSomething(s.ctx)  // Which context? What deadline?
}

// GOOD — context passed as first parameter to each method
type Service struct {
    db *sql.DB
}

func (s *Service) DoWork(ctx context.Context) error {
    return doSomething(ctx)
}
```

### HTTP handler concurrency — not thread-safe

```go
// BAD — shared mutable state in handler, HTTP handlers run concurrently
type Handler struct {
    counter int // Accessed by multiple goroutines without sync
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    h.counter++ // Data race!
    fmt.Fprintf(w, "count: %d", h.counter)
}

// GOOD — use atomic or mutex for shared state
type Handler struct {
    counter atomic.Int64
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    count := h.counter.Add(1)
    fmt.Fprintf(w, "count: %d", count)
}
```

### Returning pointer to mutex-protected structure

```go
// BAD — returns pointer to protected data, caller bypasses mutex
type Counters struct {
    mu   sync.Mutex
    vals map[Key]*Counter
}

func (c *Counters) GetCounter(k Key) *Counter {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.vals[k] // Caller now has unprotected pointer!
}

// GOOD — return a copy, not a pointer
type Counters struct {
    mu   sync.Mutex
    vals map[Key]Counter // Store values, not pointers
}

func (c *Counters) GetCounter(k Key) (Counter, bool) {
    c.mu.Lock()
    defer c.mu.Unlock()
    val, ok := c.vals[k]
    return val, ok // Copy returned, safe
}
```

### sync.Map Load/Store race

```go
// BAD — check-then-act is racy with concurrent writers
func DoSomething(k Key, v Value) {
    _, ok := m.Load(k)
    if !ok {
        m.Store(k, v) // Two goroutines can both pass the Load check
    }
}

// GOOD — use atomic LoadOrStore
func DoSomething(k Key, v Value) {
    m.LoadOrStore(k, v) // Single atomic operation
}
```

### time.Ticker not stopped — memory leak

```go
// BAD — ticker never stopped, goroutine leaks
func poll(ctx context.Context) {
    ticker := time.NewTicker(5 * time.Second)
    for {
        select {
        case <-ticker.C:
            doPoll()
        case <-ctx.Done():
            return // ticker.Goroutine still running
        }
    }
}

// GOOD — always stop the ticker
func poll(ctx context.Context) {
    ticker := time.NewTicker(5 * time.Second)
    defer ticker.Stop()
    for {
        select {
        case <-ticker.C:
            doPoll()
        case <-ctx.Done():
            return
        }
    }
}
```

### time.Time comparison

```go
// BAD — == compares Location and monotonic clock, not just the instant
if startTime == endTime { ... }

// BAD — time.Since() can return negative duration if monotonic component stripped
elapsed := time.Since(startTime.UTC())

// GOOD — use Equal() for time instant comparison
if startTime.Equal(endTime) { ... }

// GOOD — keep monotonic component for Since()
elapsed := time.Since(startTime) // Don't call .UTC() or .Round(0) on startTime first

// GOOD — strip monotonic only when comparing system times (e.g., for storage/network)
if lastSent.Before(time.Now().Round(0)) { ... }
```

### Zero-capacity channel as accidental bottleneck

```go
// BAD — unbuffered channel in a producer that should be asynchronous
ch := make(chan Event) // Blocks producer until consumer receives

// GOOD — buffered if producer should not block on slow consumer
ch := make(chan Event, 100) // Producer can send up to 100 ahead

// GOOD — unbuffered is intentional when you need handoff synchronization
// (document why zero-capacity is deliberate)
ch := make(chan Event) // Unbuffered: ensures consumer has received before producer continues
```

---

## Interface Design Issues

### Interface returned where struct suffices

```go
// BAD — unnecessary abstraction, consumer can't access fields without assertion
type UserGetter interface {
    GetUser(id string) (*User, error)
}

func NewUserGetter(db *sql.DB) UserGetter {  // Returns interface
    return &userGetter{db: db}
}

// GOOD — return concrete type, accept interface where polymorphism is needed
func NewUserGetter(db *sql.DB) *UserGetter {  // Returns struct
    return &userGetter{db: db}
}
```

### Fat interface — too many methods

```go
// BAD — forces all implementations to satisfy everything
type UserManager interface {
    Create(ctx context.Context, u *User) error
    Get(ctx context.Context, id string) (*User, error)
    Update(ctx context.Context, u *User) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, filter Filter) ([]*User, error)
    SendWelcomeEmail(ctx context.Context, u *User) error
    ResetPassword(ctx context.Context, id string) error
    AuditLog(ctx context.Context, action string) error
}

// GOOD — small, focused interfaces composed at the call site
type UserReader interface {
    Get(ctx context.Context, id string) (*User, error)
    List(ctx context.Context, filter Filter) ([]*User, error)
}

type UserWriter interface {
    Create(ctx context.Context, u *User) error
    Update(ctx context.Context, u *User) error
    Delete(ctx context.Context, id string) error
}

// Consumer takes only what it needs
func RenderProfile(r UserReader) error { ... }
```

### Premature interface — only one implementation exists

```go
// BAD — interface created "for future flexibility" with one impl
type ConfigLoader interface {
    Load(path string) (*Config, error)
}

type fileConfigLoader struct{}

// GOOD — extract interface when the second implementation appears
// Start with a concrete type:
func LoadConfig(path string) (*Config, error) { ... }

// Extract interface later when you need a mock or alternative:
// type ConfigLoader interface {
//     Load(path string) (*Config, error)
// }
```

---

## Package Structure Issues

### Circular import dependency

```go
// BAD — circular: user package imports auth, auth imports user
package user

import "myapp/auth" // user → auth

type User struct {
    Permissions auth.Permissions
}

package auth

import "myapp/user" // auth → user → auth (cycle!)

func Authorize(u *user.User) bool { ... }

// GOOD — extract shared types to a separate package
package permissions  // New package with no deps on user or auth

type Permissions []string

package user

import "myapp/permissions"

type User struct {
    Permissions permissions.Permissions
}

package auth

import "myapp/permissions"

func Authorize(perms permissions.Permissions) bool { ... }
```

### Package level state — global mutation

```go
// BAD — global mutable state, untestable, race-prone
var db *sql.DB

func Init(connStr string) error {
    var err error
    db, err = sql.Open("postgres", connStr)
    return err
}

func GetUser(id string) (*User, error) {
    return db.QueryRowContext(...)  // Which DB? When was it set?
}

// GOOD — explicit dependency injection
type UserService struct {
    db *sql.DB
}

func NewUserService(db *sql.DB) *UserService {
    return &UserService{db: db}
}

func (s *UserService) GetUser(ctx context.Context, id string) (*User, error) {
    return s.db.QueryRowContext(ctx, ...)
}
```

### init() abuse

```go
// BAD — hidden side effects, order-dependent, untestable
func init() {
    config = loadConfig()          // Fails silently if file missing
    db = connectDB(config.DBURL)   // Panics if DB unreachable
    registerMetrics()              // Global registration, can't undo
}

// GOOD — explicit initialization called from main
func main() {
    cfg, err := config.Load("config.yaml")
    if err != nil {
        log.Fatalf("loading config: %v", err)
    }

    db, err := sql.Open("postgres", cfg.DBURL)
    if err != nil {
        log.Fatalf("connecting to DB: %v", err)
    }
    defer db.Close()

    svc := NewService(db, cfg)
    svc.Run()
}
```

---

## Performance Issues

### Heap escape — pointer returned for small values

```go
// BAD — escapes to heap for a 2-field struct
type Point struct{ X, Y float64 }

func NewPoint(x, y float64) *Point {
    return &Point{x, y}  // Compiler must allocate on heap
}

// GOOD — return by value, let caller decide
func NewPoint(x, y float64) Point {
    return Point{x, y}  // Can stay on stack
}
```

### Unnecessary []byte ↔ string conversion

```go
// BAD — allocates on every call in a hot loop
func processHeader(header string) []byte {
    return []byte(header)  // New allocation each time
}

// GOOD — use unsafe for read-only conversion in hot paths (with benchmark proof)
//
// Only do this if profiling shows the allocation matters.
// For most code, []byte(s) is fine and clearer.

// GOOD — avoid conversion entirely when possible
func processHeader(header string) string {
    // Work with string directly if you only need to read
    return strings.TrimSpace(header)
}
```

### Slice growth — unpreallocated slices in loops

```go
// BAD — repeated allocation as slice grows
var results []string
for _, item := range items {
    results = append(results, transform(item))  // May realloc many times
}

// GOOD — preallocate if size is known
results := make([]string, 0, len(items))
for _, item := range items {
    results = append(results, transform(item))
}

// GOOD — direct index assignment if transform has no error
results := make([]string, len(items))
for i, item := range items {
    results[i] = transform(item)
}
```

### Defer in hot loops

```go
// BAD — defer overhead per iteration
func processAll(items []Item) error {
    for _, item := range items {
        mu.Lock()
        defer mu.Unlock()  // All defers run when function returns, not per iteration
        process(item)      // Also: mutex held for entire loop, not per item
    }
    return nil
}

// GOOD — explicit unlock per iteration
func processAll(items []Item) error {
    for _, item := range items {
        mu.Lock()
        process(item)
        mu.Unlock()
    }
    return nil
}

// BETTER — process in bulk under a single lock
func processAll(items []Item) error {
    mu.Lock()
    defer mu.Unlock()
    for _, item := range items {
        process(item)
    }
    return nil
}
```

### Profiling commands for review

```bash
# CPU profile during tests
go test -cpuprofile=cpu.out ./...
go tool pprof -top cpu.out

# Memory profile
go test -memprofile=mem.out ./...
go tool pprof -top mem.out

# Compare benchmarks before/after change
go test -bench=. -count=5 ./... > old.txt
# ... make changes ...
go test -bench=. -count=5 ./... > new.txt
benchstat old.txt new.txt

# Escape analysis — find heap allocations
go build -gcflags="-m -m" ./... 2>&1 | grep "escapes to heap"

# Check inlining decisions
go build -gcflags="-m" ./... 2>&1 | grep "can inline\|too complex"
```

---

## Testing Gaps

### Untested error paths

```go
// BAD — only the happy path tested
func TestGetUser(t *testing.T) {
    u, err := svc.GetUser(ctx, "123")
    assert.NoError(t, err)
    assert.Equal(t, "123", u.ID)
}

// GOOD — test error paths explicitly
func TestGetUser(t *testing.T) {
    t.Run("found", func(t *testing.T) {
        u, err := svc.GetUser(ctx, "123")
        require.NoError(t, err)
        assert.Equal(t, "123", u.ID)
    })

    t.Run("not found", func(t *testing.T) {
        _, err := svc.GetUser(ctx, "nonexistent")
        assert.ErrorIs(t, err, ErrNotFound)
    })

    t.Run("cancelled context", func(t *testing.T) {
        ctx, cancel := context.WithCancel(context.Background())
        cancel()
        _, err := svc.GetUser(ctx, "123")
        assert.ErrorIs(t, err, context.Canceled)
    })
}
```

### Brittle tests — testing implementation details

```go
// BAD — coupled to internal representation
func TestUser(t *testing.T) {
    u := User{Name: "Alice"}
    assert.Equal(t, "Alice", u.fields["name"])  // Breaks if fields map renamed
}

// GOOD — test through public API
func TestUser(t *testing.T) {
    u := NewUser("Alice")
    assert.Equal(t, "Alice", u.Name())  // Tests behavior, not storage
}
```

### Missing test isolation — shared state between tests

```go
// BAD — tests depend on execution order
var db *sql.DB  // Shared across all tests

func TestInsert(t *testing.T) {
    db.Exec("INSERT INTO users ...")  // Leaves data for next test
}

func TestCount(t *testing.T) {
    // Assumes TestInsert ran first
    count := getCount(db)
    assert.Equal(t, 1, count)  // Fails if run alone or in parallel
}

// GOOD — each test sets up and tears down its own state
func TestCount(t *testing.T) {
    db := setupTestDB(t)       // Fresh DB per test
    defer cleanupTestDB(t, db)

    db.Exec("INSERT INTO users ...")  // Known state
    count := getCount(db)
    assert.Equal(t, 1, count)
}
```

---

## Security Issues

### SQL injection

```go
// BAD — string interpolation
query := fmt.Sprintf("SELECT * FROM users WHERE id = '%s'", userID)
rows, err := db.Query(query)

// GOOD — parameterized query
rows, err := db.QueryContext(ctx, "SELECT * FROM users WHERE id = $1", userID)
```

### Command injection

```go
// BAD — user input passed directly to shell
cmd := exec.Command("sh", "-c", "ping -c 1 "+hostname)
output, err := cmd.Output()

// GOOD — pass arguments separately, no shell interpretation
cmd := exec.Command("ping", "-c", "1", hostname)
output, err := cmd.Output()
```

### Unvalidated input

```go
// BAD — trusts client-supplied values
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
    var req CreateRequest
    json.NewDecoder(r.Body).Decode(&req)
    // req.Role could be "admin" — never validated
    h.service.Create(req)
}

// GOOD — explicit validation before use
func (r CreateRequest) Validate() error {
    if r.Name == "" {
        return ErrNameRequired
    }
    if r.Role != "viewer" && r.Role != "editor" {
        return fmt.Errorf("invalid role: %q", r.Role)
    }
    return nil
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
    var req CreateRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }
    if err := req.Validate(); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    h.service.Create(req)
}
```

### Secrets in code or logs

```go
// BAD — credentials in source code
const dbPassword = "supersecret123"

// BAD — sensitive data logged
log.Printf("Connecting as %s:%s", username, password)

// GOOD — read from environment
dbPassword := os.Getenv("DB_PASSWORD")
if dbPassword == "" {
    return errors.New("DB_PASSWORD environment variable is required")
}

// GOOD — log without secrets
log.Printf("Connecting as user=%s host=%s", username, host)
```

---

## Style and Conventions

### Import grouping

```go
// BAD — ungrouped imports
import (
    "fmt"
    "github.com/foo/bar"
    "os"
    "rsc.io/goversion/version"
    "hash/adler32"
)

// GOOD — grouped: stdlib first, then third-party, separated by blank lines
import (
    "fmt"
    "hash/adler32"
    "os"

    "github.com/foo/bar"
    "rsc.io/goversion/version"
)
```

### Receiver name consistency

```go
// BAD — inconsistent receiver names across methods
func (client *Client) Connect() { ... }
func (c *Client) Close() { ... }
func (self *Client) Send() { ... }

// GOOD — consistent short name across all methods
func (c *Client) Connect() { ... }
func (c *Client) Close() { ... }
func (c *Client) Send() { ... }
```

### Synchronous functions preferred

```go
// BAD — forces concurrency on caller, hard to test
func FetchAsync(url string, callback func(Result)) {
    go func() {
        result := doFetch(url)
        callback(result)
    }()
}

// GOOD — synchronous, caller adds concurrency if needed
func Fetch(ctx context.Context, url string) (Result, error) {
    return doFetch(ctx, url)
}

// Caller chooses concurrency:
// go func() { result, err := Fetch(ctx, url); handle(result, err) }()
```

### Crypto — use crypto/rand, not math/rand

```go
// BAD — predictable output, not suitable for security
import "math/rand"

func GenerateToken() string {
    return fmt.Sprintf("%d", rand.Int63())
}

// GOOD — cryptographically secure random
import "crypto/rand"

func GenerateToken() string {
    return rand.Text() // Go 1.22+: crypto/rand.Text
}
```

---

## Go-Specific Anti-Patterns

| Anti-pattern | Detection | Fix |
|---|---|---|
| `init()` with side effects | Imports cause DB connections, file I/O | Explicit init called from `main` |
| Global `var` with mutable state | Package-level maps, slices, configs | Dependency injection via struct fields |
| `panic` for runtime errors | `panic("something went wrong")` | Return `error`, let caller decide |
| `interface{}` when generics work | `func Process(v interface{})` | `func Process[T any](v T)` (Go 1.18+) |
| Range variable capture bug (pre-Go 1.22) | `for _, v := range items { go func() { use(v) } }` | `v := v` before goroutine, or upgrade to Go 1.22+ |
| `sync.Mutex` embedded as exported field | `type S struct { sync.Mutex }` → `s.Lock()` is public | `type S struct { mu sync.Mutex }` (unexported) |
| `context.TODO()` in production code | Search for `context.TODO` | Replace with `context.Context` from caller |
| Naked goroutine without recovery | `go doWork()` | `go func() { defer recoverPanic(); doWork() }()` if appropriate |
| JSON tags missing on exported structs | Struct fields marshaled as `FieldName` | Add `json:"fieldName"` tags |
| `time.Sleep` for synchronization | `time.Sleep(100 * time.Millisecond)` waiting for server | Use `WaitForReady` with retry/backoff or channel signal |
| `RWMutex` for trivial fields | `sync.RWMutex` protecting a single `int` | Use plain `sync.Mutex` or `atomic.Int64` — RWMutex has higher overhead |
| `math/rand` for security-sensitive values | `rand.Int63()` for tokens, IDs | Use `crypto/rand.Reader` or `crypto/rand.Text()` |
| Inconsistent receiver names | `(c *Client)` in one method, `(cl *Client)` in another | Pick one short name, use it everywhere |
| Unbuffered channel without comment | `make(chan T)` blocking producer unexpectedly | Buffer if async, or document why synchronous handoff is intentional |

---

## Architecture Review Questions

For reviewing Go service architecture, check:

| Question | What to look for |
|----------|-----------------|
| **Dependency direction** | Do `internal/` packages depend on `pkg/` or external packages only? No upward imports from domain to transport layer? |
| **Package coupling** | How many imports does each package have? >10 is a smell. Circular or mutual imports? |
| **Error boundary** | Does each layer wrap errors with context, or pass raw errors from dependencies? |
| **Context propagation** | Does every function that does I/O or blocks accept `context.Context` as first param? |
| **Configuration** | Hardcoded values or environment-derived? Config struct validated at startup? |
| **Graceful shutdown** | Signal handling, context cancellation, in-flight request draining? |
| **Observability** | Structured logging (`log/slog`), metrics, tracing integrated or bolted on? |
| **Test architecture** | Can you test business logic without starting HTTP servers or databases? Interfaces at boundaries? |

---

## Quick Reference

| Review Focus | Tool / Command | What It Catches |
|---|---|---|
| Race conditions | `go test -race ./...` | Data races, unsynchronized access |
| Vet issues | `go vet ./...` | Common bugs, suspicious constructs |
| Static analysis | `golangci-lint run ./...` | Style, bugs, complexity, security |
| Incremental lint | `golangci-lint run --new-from-rev HEAD~1 ./...` | Only new issues (gradual adoption) |
| Security scan | `gosec ./...` | SQL injection, hardcoded creds, weak crypto |
| Dependency audit | `govulncheck ./...` | Known CVEs in dependencies |
| Cyclomatic complexity | `gocyclo -over 10 .` | Functions that are too complex |
| Dead code | `deadcode -test ./...` | Unreachable functions |
| Escape analysis | `go build -gcflags="-m" ./...` | Unnecessary heap allocations |
| Benchmark comparison | `benchstat old.txt new.txt` | Performance regressions |
| Coverage gaps | `go test -coverprofile=c.out ./...` | Untested code paths |
| Formatting | `gofmt -d .` | Style deviations (run in CI, never skip) |

### Authoritative References

| Resource | Link |
|----------|------|
| Go Code Review Comments (official) | https://go.dev/wiki/CodeReviewComments |
| Effective Go | https://go.dev/doc/effective_go |
| Google Go Style Guide | https://google.github.io/styleguide/go/guide.html |
| Go Concurrency Checklist | https://github.com/code-review-checklists/go-concurrency |
| Microsoft Go Code Review Playbook | https://microsoft.github.io/code-with-engineering-playbook/code-reviews/recipes/go/ |
