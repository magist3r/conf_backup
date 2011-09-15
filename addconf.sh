#!/bin/bash
GIT_PATH="/home/magist3r/code/conf_backup"
CURDIR="$(pwd)"

usage(){
	echo "Usage: $0 <ACTION> [FILES]"
}

init(){
	if [ ! -d "$GIT_PATH/.git" ]; then
		cd "$GIT_PATH"
		git init
	fi
}

add(){
	if [ "$#" = 0 ]; then
		echo "No files to add"
		usage
		exit 1
	fi
        
	if [ ! -f "$GIT_PATH/.files" ]; then
		touch "$GIT_PATH/.files"
		cd "$GIT_PATH" && git add .files
	fi

	while (( "$#" > 0 )); do
		FNAME="$(readlink -f "$1")"
		echo $FNAME
		if [ -f "$FNAME" ]; then 					# Проверка существования файла
			grep "$FNAME" "$GIT_PATH/.files" > /dev/null
			if [[ "$?" = 1 ]]; then					# Проверка существования файла в репозитории
				cp "$1" "$GIT_PATH" 				# Копируем файл в каталог с репозиторием
		 	 	echo "$FNAME" >> "$GIT_PATH/.files"		# Добавляем полный путь к файлу в .files
				cd $GIT_PATH
				git add "$(basename "$FNAME")"
			else 
				update $FNAME
			fi
		else
			echo "File not found... exiting"
			usage
			exit 1
		fi			

		shift
	done
#	sudo cp -a "$CURDIR$1" "$GITPATH" && cd $GIT_PATH && git add .
}

update(){
	if [ ! -z "$1" ] && [ -f "$1" ]; then
		NAME=$(basename "$1")
		diff "$NAME" "$1" > /dev/null
		if [[ "$?" = 1 ]]; then
			cp -a "$1" "$GIT_PATH"
		fi
	else
		while read line; do
			NAME=$(basename "$line")
			diff "$NAME" "$line" > /dev/null
	       		if [[ "$?" = 1 ]]; then
				cp -a "$line" "$GIT_PATH"
	       	        fi	       
		done < <(cat "$GIT_PATH/.files")	
	fi
}

commit(){
	cd "$GIT_PATH"
	if [ ! -z "$1" ]; then
		git commit -a -m "$1"
	else
		git commit -a
	fi
}

push(){
	cd "$GIT_PATH"
	git push origin master
}	


if [[ "$#" = 0 ]]; then
	usage
else
	case "$1" in
		
	"add")
	shift
	add "$@"
	;;

	"commit")
	commit "$@"
	;;

	"push")
	push
	;;

	"update")
	update
	;;

	*)
	usage	
        exit 0
	;;
	esac
fi


exit 0
