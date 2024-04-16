# config

Use this secrets pre-commit hook to detect many of the cases where a secret is inadvertently added to a repo

Edit `.gitconfig` to include your name and email, then put it in your home directory (check it may be there already, if you have already set your user name and email globally for git, and may include other options you need to keep)

You may need to hardcode your home directory - I added $USER to avoid having my own home directory hardcoded in this file.

Then the `git-secrets` dir should be copied in to your home directory too.


