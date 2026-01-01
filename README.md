# gitneko
a zsh script that shows a neko prompt `(^>ω<^)` indicating git status

![demo](https://exiled-images.pages.dev/file/ec6d76b698b8143221a40.png)

## features
- [X] display a kawaii neko
- [X] display relative path
- [X] display branch
- [X] display git status
- [X] python venv prompt compatibility
- [X] display nonzero return value
- [X] 2-line mode
- [X] cascade print mode
- [X] display rebase-apply status
- [X] display stash count
- [X] display ahead and behind commits count
- [X] customize colors by setting `NEKOLOR_*`
- [X] customize icons by setting `NEKOICON_*`
- [X] ascii terminal compatibility
- [X] can be referred as a prompt component

# Usage

Simply source this script, run `gitneko -h` to show help information.

- If you use a static prompt, then you can enable the prompt by setting `NEKOPS_PS_T` to `true` after loading gitneko. Then gitneko will take over your prompt whenever you change into a git directory, and recover it back when you leave.
- If you already have a themed prompt but still want to add the neko to you own `PROMPT`, you can simply add `$NEKOPS_NEKO` to related zsh hook function, which is responsible for updating your prompt. Gitneko is designed for a prompt that supports run-time updating, if you don't know how, you may find help from the developer of your prompt theme.

Install it with `zsh-usepkg`:

``` shell
defpkg :ensure true :fetcher git \
       :from https://github.com :path gynamics/zsh-gitneko \
       :comp _gitneko :config 'NEKOPS_PS_T=true; gitneko -2'
```
