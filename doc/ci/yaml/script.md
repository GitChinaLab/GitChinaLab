---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab CI/CD script syntax **(FREE)**

You can use special syntax in [`script`](index.md#script) sections to:

- [Split long commands](#split-long-commands) into multiline commands.
- [Use color codes](#add-color-codes-to-script-output) to make job logs easier to review.
- [Create custom collapsible sections](../jobs/index.md#custom-collapsible-sections)
  to simplify job log output.

## Use special characters with `script`

Sometimes, `script` commands must be wrapped in single or double quotes.
For example, commands that contain a colon (`:`) must be wrapped in single quotes (`'`).
The YAML parser needs to interpret the text as a string rather than
a "key: value" pair.

For example, this script uses a colon:

```yaml
job:
  script:
    - curl --request POST --header 'Content-Type: application/json' "https://gitlab/api/v4/projects"
```

To be considered valid YAML, you must wrap the entire command in single quotes. If
the command already uses single quotes, you should change them to double quotes (`"`)
if possible:

```yaml
job:
  script:
    - 'curl --request POST --header "Content-Type: application/json" "https://gitlab/api/v4/projects"'
```

You can verify the syntax is valid with the [CI Lint](../lint.md) tool.

Be careful when using these characters as well:

- `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@`, `` ` ``.

## Ignore non-zero exit codes

When script commands return an exit code other than zero, the job fails and further
commands do not execute.

Store the exit code in a variable to avoid this behavior:

```yaml
job:
  script:
    - false || exit_code=$?
    - if [ $exit_code -ne 0 ]; then echo "Previous command failed"; fi;
```

## Set a default `before_script` or `after_script` for all jobs

You can use [`before_script`](index.md#before_script) and [`after_script`](index.md#after_script)
with [`default`](index.md#default):

- Use `before_script` with `default` to define a default array of commands that
  should run before the `script` commands in all jobs.
- Use `after_script` with default to define a default array of commands
  that should run after the job completes.

You can overwrite a default by defining a different one in a job. To ignore the default
use `before_script: []` or `after_script: []`:

```yaml
default:
  before_script:
    - echo "Execute this `before_script` in all jobs by default."
  after_script:
    - echo "Execute this `after_script` in all jobs by default."

job1:
  script:
    - echo "These script commands execute after the default `before_script`,"
    - echo "and before the default `after_script`."

job2:
  before_script:
    - echo "Execute this script instead of the default `before_script`."
  script:
    - echo "This script executes after the job's `before_script`,"
    - echo "but the job does not use the default `after_script`."
  after_script: []
```

## Split long commands

You can split long commands into multiline commands to improve readability with
`|` (literal) and `>` (folded) [YAML multiline block scalar indicators](https://yaml-multiline.info/).

WARNING:
If multiple commands are combined into one command string, only the last command's
failure or success is reported.
[Failures from earlier commands are ignored due to a bug](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/25394).
To work around this, run each command as a separate `script` item, or add an `exit 1`
command to each command string.

You can use the `|` (literal) YAML multiline block scalar indicator to write
commands over multiple lines in the `script` section of a job description.
Each line is treated as a separate command.
Only the first command is repeated in the job log, but additional
commands are still executed:

```yaml
job:
  script:
    - |
      echo "First command line."
      echo "Second command line."
      echo "Third command line."
```

The example above renders in the job log as:

```shell
$ echo First command line # collapsed multiline command
First command line
Second command line.
Third command line.
```

The `>` (folded) YAML multiline block scalar indicator treats empty lines between
sections as the start of a new command:

```yaml
job:
  script:
    - >
      echo "First command line
      is split over two lines."

      echo "Second command line."
```

This behaves similarly to multiline commands without the `>` or `|` block
scalar indicators:

```yaml
job:
  script:
    - echo "First command line
      is split over two lines."

      echo "Second command line."
```

Both examples above render in the job log as:

```shell
$ echo First command line is split over two lines. # collapsed multiline command
First command line is split over two lines.
Second command line.
```

When you omit the `>` or `|` block scalar indicators, GitLab concatenates non-empty
lines to form the command. Make sure the lines can run when concatenated.

[These documents](https://en.wikipedia.org/wiki/Here_document) work with the
`|` and `>` operators as well. The example below transliterates lower case letters
to upper case:

```yaml
job:
  script:
    - |
      tr a-z A-Z << END_TEXT
        one two three
        four five six
      END_TEXT
```

Results in:

```shell
$ tr a-z A-Z << END_TEXT # collapsed multiline command
  ONE TWO THREE
  FOUR FIVE SIX
```

## Add color codes to script output

Script output can be colored using [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors),
or by running commands or programs that output ANSI escape codes.

For example, using [Bash with color codes](https://misc.flogisoft.com/bash/tip_colors_and_formatting):

```yaml
job:
  script:
    - echo -e "\e[31mThis text is red,\e[0m but this text isn't\e[31m however this text is red again."
```

You can define the color codes in Shell environment variables, or even [custom CI/CD variables](../variables/index.md#custom-cicd-variables),
which makes the commands easier to read and reusable.

For example, using the same example as above and environment variables defined in a `before_script`:

```yaml
job:
  before_script:
    - TXT_RED="\e[31m" && TXT_CLEAR="\e[0m"
  script:
    - echo -e "${TXT_RED}This text is red,${TXT_CLEAR} but this part isn't${TXT_RED} however this part is again."
    - echo "This text is not colored"
```

Or with [PowerShell color codes](https://superuser.com/a/1259916):

```yaml
job:
  before_script:
    - $esc="$([char]27)"; $TXT_RED="$esc[31m"; $TXT_CLEAR="$esc[0m"
  script:
    - Write-Host $TXT_RED"This text is red,"$TXT_CLEAR" but this text isn't"$TXT_RED" however this text is red again."
    - Write-Host "This text is not colored"
```

## Troubleshooting

### `Syntax is incorrect` in scripts that use `:`

If you use a colon (`:`) in a script, GitLab might output:

- `Syntax is incorrect`
- `script config should be a string or a nested array of strings up to 10 levels deep`

For example, if you use `"PRIVATE-TOKEN: ${PRIVATE_TOKEN}"` as part of a cURL command:

```yaml
pages-job:
  stage: deploy
  script:
    - curl --header 'PRIVATE-TOKEN: ${PRIVATE_TOKEN}' "https://gitlab.example.com/api/v4/projects"
```

The YAML parser thinks the `:` defines a YAML keyword, and outputs the
`Syntax is incorrect` error.

To use commands that contain a colon, you should wrap the whole command
in single quotes. You might need to change existing single quotes (`'`) into double quotes (`"`):

```yaml
pages-job:
  stage: deploy
  script:
    - 'curl --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "https://gitlab.example.com/api/v4/projects"'
```
