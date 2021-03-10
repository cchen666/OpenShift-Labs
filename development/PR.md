# How to commit PR

<https://blog.csdn.net/qq_33429968/article/details/62219783>

## Fork the Repo to your own github and clone to local

## Add upstream

~~~bash
$ git remote add upstream https://github.com/karmab/aicli.git
$ git remote -v
origin https://github.com/cchen666/aicli.git (fetch)
origin https://github.com/cchen666/aicli.git (push)
upstream https://github.com/karmab/aicli.git (fetch)
upstream https://github.com/karmab/aicli.git (push)
~~~

## Create your own branch

~~~bash
$ git checkout -b cchen-dev
~~~

## Make your changes to code

## Commit and Push

~~~bash
$ git add <changed file>
$ git commit -m "Only split the first = when overriding extra_args"
$ git push origin cchen-dev
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 12 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 465 bytes | 465.00 KiB/s, done.
Total 4 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
remote:
remote: Create a pull request for 'cchen-dev' on GitHub by visiting:
remote:      https://github.com/cchen666/aicli/pull/new/cchen-dev
remote:
To https://github.com/cchen666/aicli.git
 * [new branch]      cchen-dev -> cchen-dev
~~~

## Make sure the Local git is sync with Remote git

~~~bash

$ git checkout main
$ git pull upstream main # Pull = Fetch + Merge. Pull upstream to local main
$ git checkout <feature branch>
$ git rebase main # Put your commit aside first, sync upstream main commits, then put your commit back. Could have conflicts
$ git push origin <feature branch> -f

~~~

## Initiate PR in your own github repo through github Web

## Sync Local Repo with Remote Repo

<https://www.zhihu.com/question/28676261>

## Ref

<https://blog.csdn.net/qq_33429968/article/details/62219783>
<https://www.bilibili.com/video/BV19e4y1q7JJ/?spm_id_from=333.999.0.0&vd_source=3b5953ad183cffe85de62bfc0e7b0322>
<https://www.bilibili.com/video/BV1ne4y1S7S9/?spm_id_from=333.337.search-card.all.click&vd_source=3b5953ad183cffe85de62bfc0e7b0322>
