# Ruby Security Rules

Security rules for Ruby development in Claude Code.

## Prerequisites

- `rules/_core/owasp-2025.md` - Core web security

---

## Injection Prevention

### Rule: Use Parameterized Queries

**Level**: `strict`

**When**: Executing database queries.

**Do**:
```ruby
# ActiveRecord (safe)
user = User.where(email: email).first
users = User.where("status = ?", status)

# With placeholders
User.where("email = :email AND status = :status",
           email: email, status: status)

# Raw SQL with parameters
User.find_by_sql(["SELECT * FROM users WHERE email = ?", email])
```

**Don't**:
```ruby
# VULNERABLE: SQL injection
User.where("email = '#{email}'")
User.find_by_sql("SELECT * FROM users WHERE email = '#{email}'")
```

**Why**: SQL injection allows attackers to read, modify, or delete database data.

**Refs**: CWE-89, OWASP A03:2025

---

### Rule: Prevent Command Injection

**Level**: `strict`

**When**: Executing system commands.

**Do**:
```ruby
require 'open3'

def list_files(directory)
  # Validate input
  raise ArgumentError, "Invalid directory" if directory.include?('..')

  # Use array form to avoid shell
  stdout, status = Open3.capture2('ls', '-la', directory)
  stdout
end

# Or use Shellwords for escaping
require 'shellwords'
system('echo', Shellwords.escape(user_input))
```

**Don't**:
```ruby
# VULNERABLE: Command injection
system("ls -la #{user_input}")
`echo #{user_input}`
exec("cat #{filename}")
```

**Why**: Shell metacharacters allow executing arbitrary commands.

**Refs**: CWE-78, OWASP A03:2025

---

## Serialization

### Rule: Avoid Unsafe Deserialization

**Level**: `strict`

**When**: Deserializing external data.

**Do**:
```ruby
require 'json'

# Use JSON for external data
data = JSON.parse(json_string)

# If YAML needed, use safe_load
require 'yaml'
data = YAML.safe_load(yaml_string, permitted_classes: [Symbol, Date])
```

**Don't**:
```ruby
# VULNERABLE: Arbitrary code execution
Marshal.load(untrusted_data)

# VULNERABLE: Unsafe YAML
YAML.load(untrusted_yaml)  # Can execute arbitrary Ruby code
```

**Why**: Marshal and unsafe YAML loading can execute arbitrary code.

**Refs**: CWE-502, OWASP A08:2025

---

## Cryptography

### Rule: Use Strong Cryptographic Algorithms

**Level**: `strict`

**When**: Encrypting data or hashing passwords.

**Do**:
```ruby
require 'securerandom'
require 'bcrypt'
require 'openssl'

# Secure random
token = SecureRandom.hex(32)

# Password hashing
password_hash = BCrypt::Password.create(password, cost: 12)
valid = BCrypt::Password.new(password_hash) == password

# AES encryption
cipher = OpenSSL::Cipher.new('aes-256-gcm')
cipher.encrypt
key = cipher.random_key
iv = cipher.random_iv
encrypted = cipher.update(data) + cipher.final
```

**Don't**:
```ruby
require 'digest'

# VULNERABLE: Weak hash for passwords
hash = Digest::MD5.hexdigest(password)

# VULNERABLE: Predictable random
token = rand(1000000)
```

**Why**: Weak cryptography allows attackers to decrypt data or crack passwords.

**Refs**: CWE-327, CWE-328, CWE-330

---

## Path Traversal

### Rule: Validate File Paths

**Level**: `strict`

**When**: Accessing files based on user input.

**Do**:
```ruby
def safe_get_file(filename)
  base_path = File.expand_path('/app/uploads')
  requested_path = File.expand_path(File.join(base_path, filename))

  # Ensure path is within base directory
  unless requested_path.start_with?(base_path)
    raise SecurityError, "Path traversal attempt detected"
  end

  File.read(requested_path)
end
```

**Don't**:
```ruby
# VULNERABLE: Path traversal
def get_file(filename)
  File.read("/app/uploads/#{filename}")
end
```

**Why**: Path traversal allows reading sensitive files outside intended directories.

**Refs**: CWE-22, OWASP A01:2025

---

## Regular Expressions

### Rule: Prevent ReDoS Attacks

**Level**: `warning`

**When**: Using regular expressions with user input.

**Do**:
```ruby
# Use atomic groups or possessive quantifiers
pattern = /\A[\w.+-]+@[\w.-]+\.[a-z]{2,}\z/i

# Set timeout for regex operations
require 'timeout'
Timeout.timeout(1) do
  input.match?(pattern)
end

# Validate input length first
if input.length <= 255
  input.match?(email_pattern)
end
```

**Don't**:
```ruby
# VULNERABLE: Catastrophic backtracking
pattern = /^(a+)+$/
vulnerable_input = "aaaaaaaaaaaaaaaaaaaaaaaaaaab"
vulnerable_input.match?(pattern)  # Hangs
```

**Why**: ReDoS causes denial of service through regex backtracking.

**Refs**: CWE-1333, OWASP A05:2025

---

## Error Handling

### Rule: Don't Expose Stack Traces

**Level**: `warning`

**When**: Handling exceptions.

**Do**:
```ruby
class ApplicationController < ActionController::Base
  rescue_from StandardError do |exception|
    # Log full details internally
    Rails.logger.error(exception.full_message)

    # Return safe message to client
    render json: { error: 'Internal server error' }, status: 500
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: 'Not found' }, status: 404
  end
end
```

**Don't**:
```ruby
# VULNERABLE: Exposes stack trace
rescue_from StandardError do |exception|
  render json: {
    error: exception.message,
    backtrace: exception.backtrace
  }, status: 500
end
```

**Why**: Stack traces reveal internal paths, gem versions, and code structure.

**Refs**: CWE-209, OWASP A05:2025

---

## Mass Assignment

### Rule: Use Strong Parameters

**Level**: `strict`

**When**: Accepting model attributes from requests.

**Do**:
```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    if @user.save
      render json: @user, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :password)
  end
end
```

**Don't**:
```ruby
# VULNERABLE: Mass assignment
def create
  @user = User.new(params[:user])
  @user.save
end

# VULNERABLE: Permitting all
def user_params
  params.require(:user).permit!
end
```

**Why**: Mass assignment allows attackers to set admin flags or other sensitive attributes.

**Refs**: CWE-915, OWASP A01:2025

---

## Quick Reference

| Rule | Level | CWE |
|------|-------|-----|
| Parameterized queries | strict | CWE-89 |
| No command injection | strict | CWE-78 |
| Safe deserialization | strict | CWE-502 |
| Strong cryptography | strict | CWE-327 |
| Path traversal prevention | strict | CWE-22 |
| ReDoS prevention | warning | CWE-1333 |
| Safe error handling | warning | CWE-209 |
| Strong parameters | strict | CWE-915 |

---

## Version History

- **v1.0.0** - Initial Ruby security rules
