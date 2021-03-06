# Steps to deploy
## Preparation
1. Run tests
   ```bash
   bundle install --binstubs
   bin/rspec --format doc
   ```
2. Increase the version in the `lib/configcat/version.rb` file.
3. Commit & Push
## Publish
Use the **same version** for the git tag as in the `version.rb`.
- Via git tag
    1. Create a new version tag.
       ```bash
       git tag v[MAJOR].[MINOR].[PATCH]
       ```
       > Example: `git tag v2.5.5`
    2. Push the tag.
       ```bash
       git push origin --tags
       ```
- Via Github release 

  Create a new [Github release](https://github.com/configcat/ruby-sdk/releases) with a new version tag and release notes.

## RubyGems
Make sure the new version is available on [RubyGems](https://rubygems.org/gems/configcat).

## Update samples
Update and test sample apps with the new SDK version.
```bash
gem update configcat
```
