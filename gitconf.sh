#!/bin/bash
GIT_PATH="/home/magist3r/code/conf_backup"
GIT_REMOTE="git@github.com:magist3r/conf_backup.git"
CURDIR="$(pwd)"

usage(){
	echo "Использование: $0 <команда> [файлы]
	Команды:
	
	init - инициализировать репозиторий;
	add [файлы] - добавить файлы в репозиторий;
	rm [файлы] - удалить файлы из репозитория;
	commit [comment] - закоммитить изменения в репозиторий;
	update [файлы] - обновить указанные файлы в репозитории;
	update all - обновить все файлы в репозитории;
	push - отправить коммиты в удаленный репозиторий;
	restore [файлы] - восстановить указанные файлы из репозитория;
	restore all - восстановить все файлы из репозитория;
	usage - вывести эту справку."
}

init(){
	if [ ! -d "$GIT_PATH/.git" ]; then
		cd "$GIT_PATH" && git init && git remote add origin "$GIT_REMOTE"
	fi
}

add(){
	if [ "$#" = 0 ]; then
		echo "Не указаны файлы для добавления"
		usage
		exit 1
	fi
       
       	cd "$GIT_PATH"

	if [ ! -f "$GIT_PATH/.files" ]; then
		touch "$GIT_PATH/.files"
		cd "$GIT_PATH" && git add .files
	fi

	while (( "$#" > 0 )); do
		FNAME="$(readlink -f "$1")"
		if [ -f "$FNAME" ]; then 					# Проверка существования файла
			grep "$FNAME" "$GIT_PATH/.files" > /dev/null
			if [[ "$?" = 1 ]]; then					# Проверка существования файла в репозитории
				cp "$1" "$GIT_PATH" 				# Копируем файл в каталог с репозиторием
		 	 	echo "$FNAME" >> "$GIT_PATH/.files"		# Добавляем полный путь к файлу в .files
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

	cd "$GIT_PATH"

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
	if [ "$#" = 0 ]; then
		echo "Не указаны файлы для обновления. Для обновления всех файлов используйте gitconf update all"
		exit 1
	fi

	cd "$GIT_PATH"

	if [ "$1" = "all" ]; then
		while read line; do
			NAME=$(basename "$line")
			diff "$NAME" "$line" > /dev/null
	       		if [[ "$?" = 1 ]]; then
				cp -a "$line" "$GIT_PATH"
	       	        fi	       
		done < <(cat "$GIT_PATH/.files")	
	else
		while (( "$#" > 0 )); do
			FNAME="$(grep "$1" "$GIT_PATH/.files")"
			NAME="$(basename "$FNAME")"
			if [ ! -z "$NAME" ]; then
				diff "$NAME" "$FNAME" > /dev/null
				if [[ "$?" = 1 ]]; then
					cp -a "$FNAME" "$GIT_PATH"
				fi
			fi
			shift
		done
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
	git push origin
}	

restore(){
	if [ "$#" = 0 ]; then
		echo "Не указаны файлы для восстановления. Для восстановления всех файлов используйте gitconf revert all"
		exit 1
	fi

	cd "$GIT_PATH"

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
		
	"init")
	shift
	init
	;;
	
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
	shift
	update "$@"
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
