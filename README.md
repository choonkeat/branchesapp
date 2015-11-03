# branchesapp

is a different take on visualizing the git(hub) network. the purpose of this visualizer is to quickly identify the difference between forks (and branches) in terms of "changes" (by way of commit logs). this helps me find forks that has the changes I want (usually because the original repository went dormant or something)

## summary

forks of the project will be fetched (and cached locally in a ``.json`` file). each fork (and all branches) will be fetched and placed into a tree (based on parentage). html is generated from this tree, sprinkled with commit logs between itself and the parent.

## run

ruby g2h.rb [url of github project]

e.g.

```
ruby g2h.rb https://github.com/jney/jquery.pageless
```

### rate limit

[To have a higher rate limit](https://github.com/choonkeat/branchesapp/issues/2), you can have `g2h.rb` make authenticated API calls by setting the `HTTP_USER` environment variable to your github username and `HTTP_PASSWORD` environment variable to a personal access tokens, OAuth token or your password

e.g.

```
HTTP_USER=choonkeat HTTP_PASSWORD=topsecret ruby g2h.rb https://github.com/jney/jquery.pageless
```

# author

Chew Choon Keat

# license

GPL

