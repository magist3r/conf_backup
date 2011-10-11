#!/bin/bash
GIT_PATH="/home/magist3r/code/conf_backup"
CURDIR="$(pwd)"

usage(){
	echo "Использование: $0 <команда> [файлы]"
}

init(){
	if [ ! -d "$GIT_PATH/.git" ]; then
		cd "$GIT_PATH" && git init
	fi
}

add(){
	if [ "$#" = 0 ]; then
		echo "Не указаны файлы для добавления"
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
			echo "Файл $FNAME не найден."
			usage
			exit 1
		fi			

		shift
	done
}

remove(){
	if [ "$#" = 0 ]; then
		echo "Не указаны файлы для удаления"
		usage
		exit 1
	fi

	while (( "$#" > 0 )); do
		NAME="$(basename "$1")"
		if [ -f "$GIT_PATH/$NAME" ]; then
			git rm "$GIT_PATH/$NAME"
			sed -i "/$NAME/d" "$GIT_PATH/.files"
		else
			echo "Нет такого файла в репозитории"
			exit 1
		fi
		shift
	done
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

restore(){
	if [ "$#" = 0 ]; then
		echo "Не указаны файлы для восстановления. Для восстановления всех файлов используйте gitconf revert all"
		exit 1
	fi

	if [ "$1" = "all" ]; then
		while read line; do
			NAME=$(basename "$line")
			if [ "${line:0:6}" != "/home/" ]; then
				sudo cp -a "$GIT_PATH/$NAME" "$line"
			else
				cp -a "$GIT_PATH/$NAME" "$line"
			fi
		done < <(cat "$GIT_PATH/.files")	
	else
		while (( "$#" > 0 )); do
			FNAME="$(grep "$1" "$GIT_PATH/.files")"
			NAME="$(basename "$FNAME")"
			if [ ! -z "$NAME" ]; then
				if [ "${FNAME:0:6}" != "/home/" ]; then
					sudo cp -a "$GIT_PATH/$NAME" "$FNAME"
				else
					cp -a "$GIT_PATH/$NAME" "$FNAME"
				fi
			else
				echo "Файла $FNAME нет в репозитории"
			fi
			shift
		done
	fi
}

if [[ "$#" = 0 ]]; then
	usage
else
	case "$1" in
		
	"add")
	shift
	add "$@"
	;;
	
	"rm")
	shift
	remove "$@"
	;;

	"commit")
	shift
	commit "$@"
	;;

	"push")
	push
	;;

	"update")
	update
	;;
	
	"restore")
	shift
	restore "$@"
	;;

	*)
	usage	
        exit 1
	;;
	esac
fi
exit 0
