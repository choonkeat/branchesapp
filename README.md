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

# author

Chew Choon Keat

# license

GPL

