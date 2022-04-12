# Pg Generated Column Support

This is a backport of the generated column support that was added to
Rails 7: https://github.com/rails/rails/pull/41856

It also includes fixes from two other PRs:
I also pulled in changes from two other related PRs:
https://github.com/rails/rails/pull/43263
https://github.com/rails/rails/pull/44319

Much thanks and appreciation to everyone who worked on the
generated columns support PRs. :heart::tada:

NOTE: Generated columns are supported since version 12.0 of PostgreSQL.

## Usage

```ruby
# db/migrate/20131220144913_create_users.rb
create_table :users do |t|
  t.string :name
  t.virtual :name_upcased, type: :string, as: 'upper(name)', stored: true
end
# app/models/user.rb
class User < ApplicationRecord
end
# Usage
user = User.create(name: 'John')
User.last.name_upcased # => "JOHN"
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'pg_generated_column_support'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install pg_generated_column_support
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
