This guide show how to publish release a plugin.

## Code review

Review the whole code and remove things like:

- Inappropriate comments

- Deactivated code

- Minor cases of code smell

## Resolve licensing and copyright issues

## Complete the gemspec

1. Add the license to the gemspec of the plugin if not already there.
2. Add any files that should be included to the gemspec (e.g. the`doc`folder, the`db`folder if there are any migrations, the `CHANGELOG.md`, and the `README.md`).
3. Check authors and email point to the right authors.
4. The homepage should be the homepage of the plugin.
5. Check if summary and description are there.
6. Check if all dependencies are listed (this might be difficult, I know): There should be a sentence in the README, that this is an OpenProject-Plugin and requires the core to run. Apart from that, state only dependencies that are not already present in core.
7. While you are at it, also check if there is any wiring to core versions necessary in engine.rb; also check, that the url of the plugin is wired correctly.
8. Push the version of the plugin, mostly by just removing any .preX specials at the end.
9. Don’t forget to add a changelog entry.
10. Commit everything.
11. Also create a release tag (named ‘release/’ for example ‘release/1.0.2′) to name the new version.
12. Push the tag with`git push --tags`.

## Publish the gem at Rubygems

```
$ gem update --system
```

Ensure gemspec fields are complete and version number is correct

```
$ gem build <name>.gemspec
```

This asks for your user/password:

```
$ gem push <name>-<version>.gem
```
