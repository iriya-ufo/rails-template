# Rails Application Template

```
$ mkdir [APP_NAME]; cd [APP_NAME]
$ rbenv local [RUBY_VERSION]
$ bundle init
$ sed -i '' -e 's/# gem "rails"/gem "rails"/g' Gemfile
$ bundle install -j16 --path vendor/bundle
```

```
$ bundle exec rails new . --skip-bundle --skip-git --skip-test-unit --database mysql --template https://raw.githubusercontent.com/rawhide/rails-template/master/web_template.rb
```
