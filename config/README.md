# config

Use this secrets pre-commit hook to detect many of the cases where a secret is inadvertently added to a repo

Edit `.gitconfig` to include your name and email, then put it in your home directory (check it may be there already, if you have already set your user name and email globally for git, and may include other options you need to keep)

You may need to hardcode your home directory - I added $USER to avoid having my own home directory hardcoded in this file.

Then the `git-secrets` dir should be copied in to your home directory too. Ensure that home directory is on the path.

Finally, make and install the [git-secrets](https://github.com/awslabs/git-secrets)

You will need `make`, which if you don't have can be installed with `build-essentials`:
```
sudo apt-get install build-essential
```
Then add hooks to all repos
```
git secrets --register-aws --global
git secrets --install ~/.git-templates/git-secrets
git config --global init.templateDir ~/.git-templates/git-secrets
```

Then add secrets to check for
```
git secrets --add --global '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
git secrets --add --global 'secret'
git secrets --add --global 'ey[a-zA-Z0-9]+.[a-zA-Z0-9]+.[a-zA-Z0-9]*'
```

After this your ~/.gitconfig should have at least these patterns for UUID and JWT token listed:
```
patterns = [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
patterns = ey[a-zA-Z0-9]+.[a-zA-Z0-9]+.[a-zA-Z0-9]*
```