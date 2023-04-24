#!/bin/sh

tag=$1
repo=./chromium_lite_100_to_new_stable
remote=~/chromium/src
cache_dir=./chromium_archive_cache
default_author_name="Chrome Release Bot (LUCI)"
default_author_email="chrome-official-brancher@chops-service-accounts.iam.gserviceaccount.com"
tar_file=$cache_dir/$tag.tar
max_update_day=7

start_time=$(date +%s)


# init repo
if [ ! -d $repo ];then
	mkdir $repo
fi

cd $repo

if [ ! -d .git ];then
	echo "git init in \"$repo\"."
	../init_git.sh
fi

# check if tag exists
check_tag=`git tag -l $tag`
echo "check tag result: $check_tag"
if [[ $check_tag == $tag ]]; then
	echo "skip tag $tag"
	exit 0
fi

#check if a previous version of tag exists
find_tag=`echo $tag|cut -d'.' -f 1,2,3`
first_tag=`git tag -l --sort=version:refname ${find_tag}.*`
old_tag=`git tag -l --sort=-version:refname ${find_tag}.*`
push_branch="main"

if [[ $old_tag == "" ]]; then
	echo "new tag $tag"
	cur_branch=`git branch --show-current`
	if [[ $cur_branch != "main" ]];then
		echo "switch main"
		git switch -f --quiet --progres main
	fi
else
	echo "$old_tag --> $tag"
	old_commit_date=`git log -1 --format="%at" $old_tag`
	now_date=$(date +%s)
	time_diff=$(($now_date - $old_commit_date));
	need_update=$(($time_diff/3600/24>=$max_update_day))
	if [[ $need_update != 1 ]];then
		echo "skip tag $tag, Less than 10 days，no need to update."
		exit 0
	fi
	echo "need update."
	check_branch=`git branch | grep $first_tag`
	echo "check_branch=$check_branch"
	push_branch=v$first_tag
	if [[ $check_branch == "" && $first_tag == $old_tag ]];then
		echo "create branch $first_tag from tag $first_tag"
		git branch $push_branch $first_tag
	fi
	git branch
	git switch -f --quiet --progress $push_branch
	git branch
fi

echo "fetch tag $tag"

cd ..


# init cache
if [ ! -d $cache_dir ];then
	mkdir $cache_dir
fi


# export archive
if [ ! -f $tar_file ];then
	old_path=`pwd`
	cd $remote
	remote_tag=`git tag -l $tag`
	cd $old_path
	if [[ $remote_tag == "" ]];then
		echo "remote tag $tag is not exists."
		exit 0
	fi
	git archive --format=tar --remote=$remote $tag --output=$tar_file
	if [[ ! -s $tar_file ]];then
		echo "export archive \"$tar_file\" failed."
		exit 0
	fi
	echo "export archive \"$tar_file\" success."
fi


# read last commit body
commit_body=""
commit_date=`date -Ru`
commit_author_name=""
commit_author_email=""
commit_author=""
if [ -d $remote ]; then
	old_path=`pwd`
	cd $remote
	commit_body=`git log -2 --format="%B" $tag`
	commit_date=`git log -1 --format="%ad" $tag`
	commit_author_name=`git log -1 --format="%an" $tag`
	commit_author_email=`git log -1 --format="%ae" $tag`
	cd $old_path
fi

# use default author name
if [[ $commit_author_name == "" ]]; then
	commit_author_name=$default_author_name
fi

# use default author email
if [[ $commit_author_email == "" ]]; then
	commit_author_email=$default_author_email
fi

# use default commit body
if [[ $commit_body == "" ]]; then
	commit_body="branch $tag"
fi


#trace commit info
commit_author="$commit_author_name <$commit_author_email>"

echo "commit_author: $commit_author"
echo "commit_date: $commit_date"
echo "commit_body: $commit_body"


# remove git worktree files
./rm_all_git.sh $repo

# extract archive
echo "extract \"$tar_file\" to \"$repo\"."
tar  -xf $tar_file -C ./$repo
cd $repo

# commit
echo "add current dir"
git rm -q -r --cached .

git config --worktree user.name "$commit_author_name"
git config --worktree user.email "$commit_author_email"
export GIT_AUTHOR_DATE="$commit_date"
export GIT_COMMITTER_DATE="$commit_date"

git add -f --all

echo "commit tag $tag"

git commit -q -m "$commit_body"
git tag -a "$tag" -m ""

# repack
../git_gc.sh

git push origin refs/heads/$push_branch:refs/heads/$push_branch
git push --tags


cd ..

end_time=$(date +%s)
cost_time=$[ $end_time-$start_time ]
echo "fetch tag \"$tag\" used $(($cost_time/60))min $(($cost_time%60))s"

