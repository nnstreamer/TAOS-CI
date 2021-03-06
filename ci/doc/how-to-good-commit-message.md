---
title: Good commit message
...

## Commit Message Guidelines
```
Short (50 chars or less) summary

More detailed explanatory text. Wrap it to 72 characters. The blank
line separating the summary from the body is critical (unless you omit
the body entirely).

Write your commit message in the imperative: "Fix bug" and not "Fixed
bug" or "Fixes bug." This convention matches up with commit messages
generated by commands like git merge and git revert.

Further paragraphs come after blank lines.

- Bullet points are okay, too.
- Typically a hyphen or asterisk is used for the bullet, followed by a
  single space. Use a hanging indent.
```

### Example for a commit message
```
Add CPU arch filter scheduler support

In a mixed environment of…
```

### A properly formed git commit subject line should always be able to complete the following sentence
If applied, this commit will be *\<your subject line here\>*

### Rules for a great git commit message style
* Separate subject from body with a blank line
* Do not end the subject line with a period
* Capitalize the subject line and each paragraph
* Use the imperative mood in the subject line
* Wrap lines at 72 characters
* Use the body to explain what and why you have done something. In most cases, you can leave out details about how a change has been made.

### Information in commit messages
* Describe why a change is being made.
* How does it address the issue?
* What effects does the patch have?
* Do not assume the reviewer understands what the original problem was.
* Do not assume the code is self-evident/self-documenting.
* Read the commit message to see if it hints at improved code structure.
* The first commit line is the most important.
* Describe any limitations of the current code.
* Do not include patch set-specific comments.

Details for each point and good commit message examples can be found on https://wiki.openstack.org/wiki/GitCommitMessages#Information_in_commit_messages

### References in commit messages
If the commit refers to an issue, add this information to the commit message header or body. e.g. the GitHub web platform automatically converts issue ids (e.g. #123) to links referring to the related issue. For issues tracker like Jira there are plugins which also converts Jira tickets, e.g. [Jirafy](https://chrome.google.com/webstore/detail/jirafy/npldkpkhkmpnfhpmeoahhakbgcldplbj).

In header:
```
[#123] Refer to GitHub issue…
```
```
CAT-123 Refer to Jira ticket with project identifier CAT…
```
In body:
```
…
Fixes #123, #124
```

### Keep a changelog

A changelog is a file which contains a chronologically ordered list of notable changes for each version of a commit.
I has to be written to make it easier for users and contributors in order to see precisely what notable changes have been made between each version of the commit.
When a commit changes, reviewers want to know why and how.

**Guiding Principles**
* Changelogs are for humans, not machines.
* There should be an entry for every single version.
* The same types of changes should be grouped.
* Versions and sections should be linkable.
* The latest version comes first.
* The release date of each version is displayed.

**Types of Changes**
* `Added` for new features.
* `Changed` for changes in existing functionality.
* `Deprecated` for soon-to-be removed features.
* `Removed` for now removed features.
* `Fixed` for any bug fixes.
* `Security` in case of vulnerabilities.

**Case Study**
* https://lkml.org/lkml/2019/4/9/51 : V5, Add support for MIPID02 CSI-2
* https://lkml.org/lkml/2019/4/9/507 : V10, fieldbus_dev: add Fieldbus Device Subsystem
* https://lkml.org/lkml/2019/4/2/941 : V5, Perf: Add Icelake support


