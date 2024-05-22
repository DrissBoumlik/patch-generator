#!/bin/bash


current_branch=`git rev-parse --abbrev-ref HEAD`
if [ $current_branch != 'master' ]; then
	echo "You're current branch is $current_branch !!, switch to the master branch and retry !!"
	exit
fi

echo "Would you like to pull the update ? (leave empty for no)"
read pull_updates

echo "Enter the commit id:"
read commit_id
if [[ -z "$commit_id" ]]; then # check if $commit_id is not set
    echo "Commit ID is mandatory !!"
	exit
fi

echo "Generate package for this commit only ? (leave empty for no)"
read generate_for_commit_only

current_date=$(date +"%d_%m_%Y")
echo "Enter the patch name [$current_date]:"
read patch_name  # [direcory patch name]
if [[ -z "$patch_name" ]]; then # check if $patch_name is not set
    # echo "Patch name is mandatory !!"
	# exit
	patch_name=$current_date
fi
echo "Enter the migrations count to rollback [integer] (leave it empty if no):"
read rollback_steps
echo "Run npm run prod ? (leave it empty if no):"
read generate_assets

print() {
	echo -e "\n"
	echo -e "  ================================================================"
	echo -e "    $1"
	echo -e "  ============================="
}

generate_sql() {
	php artisan migrate:rollback --step=$1
	echo -e "\n  Migrations rolledback : $1"
	if [ ! -d "./$patch_name/database" ]; then # check if database directory do not exists
		mkdir ./$patch_name/database/
	fi
	sqlfile="./$patch_name/database/migrate.sql"
	php artisan migrate --pretend --no-ansi > $sqlfile
	bakfile="./$patch_name/database/_migrate.sql"
	sed 's/[^ ]*:[^ ]* //' $sqlfile > $bakfile
	mv $bakfile $sqlfile
	rm -rf ./$patch_name/database/migrations
	echo -e "\n  Restoring the original state of the database\n"
	php artisan migrate
}
copy_public_assets() {
	print "Copying public assets"
	mkdir ./$patch_name/public/
	mkdir ./$patch_name/public/js/
	
	if [ -d "./$patch_name/resources/js/pages" ]; then # check if pages directory exists
		search_dir=./$patch_name/resources/js/pages
		mkdir ./$patch_name/public/js/pages/
		for entry in "$search_dir"/*
		do
			filename=`basename "$entry"`
			cp ./public/js/pages/$filename ./$patch_name/public/js/pages/$filename
			cp ./public/js/pages/$filename.map ./$patch_name/public/js/pages/$filename.map
		done
		echo -e "\n  Src: ./public/js/pages ==> Dest: ./$patch_name/public/js/pages\n"
	fi
	
	if [ -d "./$patch_name/resources/js/components" ]; then # check if components directory exists
		search_dir=./$patch_name/resources/js/components
		mkdir ./$patch_name/public/js/components/
		for entry in "$search_dir"/*
		do
			filename=`basename "$entry"`
			cp ./public/js/components/$filename ./$patch_name/public/js/components/$filename
			cp ./public/js/components/$filename.map ./$patch_name/public/js/components/$filename.map
		done
		echo -e "\n  Src: ./public/js/components ==> Dest: ./$patch_name/public/js/components\n"
	fi
	
	if [ -f "./$patch_name/resources/js/app.js" ]; then # check if app.js file exists
		cp ./public/js/laravel.app.js ./$patch_name/public/js/laravel.app.js
		cp ./public/js/laravel.app.js.map ./$patch_name/public/js/laravel.app.js.map
		echo -e "\n  Src: ./public/js/laravel.app.js ==> Dest: ./$patch_name/public/js/laravel.app.js\n"
	fi

	if [ -f "./$patch_name/resources/js/oneui/app.js" ]; then # check if app.js file exists
		cp ./public/js/oneui.app.js ./$patch_name/public/js/oneui.app.js
		cp ./public/js/oneui.app.js.map ./$patch_name/public/js/oneui.app.js.map
		echo -e "\n  Src: ./public/js/oneui.app.js ==> Dest: ./$patch_name/public/js/oneui.app.js\n"
	fi	
}


if [[ -n $pull_updates ]]; then
	print "Pulling the latest changes from remote branch"
	git pull origin master
fi

# ===============================================================
print "Removing previous patches"
rm -rf $patch_name*

# ===============================================================
print "Fetching changed files"
if [[ -n $generate_for_commit_only ]]; then # check if $generate_for_commit_only is set
	git diff-tree -r --no-commit-id --name-only $commit_id | xargs tar -cf $patch_name.tar
else
	git diff-tree -r --no-commit-id --name-only $commit_id master | xargs tar -cf $patch_name.tar
fi
mkdir $patch_name && tar -xf $patch_name.tar --directory ./$patch_name


# ===============================================================
if [[ -n $rollback_steps ]]; then # check if $rollback_steps is set
	print "Generating Newest migrations as sql script"
	if [ $rollback_steps -le 0 ]; then
		echo "  No migration will be rolledback"
	else
		generate_sql $rollback_steps
	fi
else
	# check migrations directory was generated by git-diff command
	if [ -d "./$patch_name/database/migrations" ]; then # check if migrations directory exists
		echo -e "\n We found migrations files inside the patch directory !!"
		echo " Do you want to generate sql for these files (empty if no):"
		read answer
		if [[ -n $answer ]]; then # check if $answer is set
			files_count=$(ls -1 "./$patch_name/database/migrations" | wc -l)
			generate_sql $files_count
		fi
	fi
fi

# ===============================================================
# TODO: copy remaining js/css files
if [[ -n $generate_assets ]]; then # check if $generate_assets is set
	print "Generating public assets"
	npm run prod
	copy_public_assets
else
	# check resources directory was generated by git-diff command
	if [ -d "./$patch_name/resources" ]; then
		echo -e "\n We found resources files inside the patch directory !!"
		echo " Do you want to run npm run prod (empty if no):"
		read answer
		if [[ -n $answer ]]; then # check if $answer is set
			npm run prod
		fi
		copy_public_assets
	fi
fi

# ===============================================================
print "Zipping & Removing any useless files/directories"
rm *.tar *.tar.gz *.zip
tar -cf $patch_name.zip $patch_name/* \
	&& rm -rf $patch_name

# clear

echo -e "\n\n  Generated path : $patch_name.zip\n\n"