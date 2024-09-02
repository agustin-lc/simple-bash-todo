#!/bin/bash

# Define ANSI codes for colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

tasks_file="tasks.txt"

if [ ! -e "$tasks_file" ]; then
    touch "$tasks_file"
fi

colorize_task() {
    task=$1
    case "$task" in
        *"[A]"*) echo -e "${RED}$task${RESET}";;
        *"[B]"*) echo -e "${YELLOW}$task${RESET}";;
        *"[C]"*) echo -e "${GREEN}$task${RESET}";;
        *) echo "$task";;
    esac
}

search_task() {
    search_keyword=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    while IFS= read -r task; do
        task_lowercase=$(echo "$task" | tr '[:upper:]' '[:lower:]')
        if [[ "$task_lowercase" == *"$search_keyword"* ]]; then
            colorized_task=$(colorize_task "$task")
            echo "$colorized_task"
        fi
    done < "$tasks_file"
}

case "$1" in
    "add")
        echo -n "Enter task description: "
        read task_description
        echo -n "Enter task priority (A/B/C): "
        read task_priority
        task_priority=${task_priority^^}
    
        if [[ "$task_priority" == "A" || "$task_priority" == "B" || "$task_priority" == "C" ]]; then
            # Obtener el último número de tarea y asignar el siguiente número disponible
            if [ -s "$tasks_file" ]; then
                last_task_number=$(awk '{print $1}' "$tasks_file" | sort -n | tail -n 1)
                new_task_number=$((last_task_number + 1))
            else
                new_task_number=1
            fi
        
            task="$new_task_number [$task_priority] $task_description"
            echo "$task" >> "$tasks_file"
            echo "Task added: $task"
        else
            echo "Invalid priority. Please enter A, B, or C."
        fi
        ;;
    "delete")
        task_number="$2" 
        if [ -z "$task_number" ]; then
            echo "Please specify the task number you want to delete."
        else
            grep -q "^$task_number " "$tasks_file"
            if [ $? -ne 0 ]; then
                echo "Task number not found."
            else
                grep -v "^$task_number " "$tasks_file" > tmpfile && mv tmpfile "$tasks_file"
                echo "Task deleted."
            fi
        fi
        ;;
    "deleteAll")
        echo -n "Are you sure you want to delete all tasks? (y/n): "
        read confirm
        if [ "${confirm,,}" = "y" ]; then
            > "$tasks_file"
            echo "All tasks deleted."
        else
            echo "Deletion canceled."
        fi
        ;;
    "edit")
        task_number="$2"
        if [ -z "$task_number" ]; then
            echo "Please specify the task number you want to edit."
        else
            old_task=$(grep "^$task_number " "$tasks_file")
            if [ -z "$old_task" ]; then
                echo "Task not found."
            else
                # Extraer la prioridad y la descripción de la tarea
                priority=$(echo "$old_task" | grep -o "\[.\]")
                description=$(echo "$old_task" | sed "s/\[$priority\]//" | cut -d' ' -f2-)
            
                echo "Current task: $description"
                echo -n "Enter the new task description: "
                read new_description
            
                new_task="$task_number $priority $new_description"
                grep -v "^$task_number " "$tasks_file" > tmpfile && echo "$new_task" >> tmpfile && mv tmpfile "$tasks_file"
                echo "Task edited."
            fi
        fi
        ;;
    "search")
        echo -n "Enter search keyword: "
        read search_keyword
        echo "Search results:"
        search_task "$search_keyword"
        ;;  
    "list")
        echo "To-do list:"
        while IFS= read -r task; do
            colorized_task=$(colorize_task "$task")
            echo "$colorized_task"
        done < "$tasks_file"
        ;;
    "listTag")
        echo -n "Enter tag to filter tasks: "
        read tag_to_filter
        tag_to_filter=$(echo "$tag_to_filter" | tr '[:upper:]' '[:lower:]')
        echo "Tasks with tag @$tag_to_filter:"
   
        while IFS= read -r task; do
            task_lowercase=$(echo "$task" | tr '[:upper:]' '[:lower:]')
       
            # Check for tags in the task
            if [[ "$task_lowercase" == *"@$tag_to_filter"* ]]; then
                colorized_task=$(colorize_task "$task")
                echo "$colorized_task"
            fi
        done < "$tasks_file"
        ;;
    "listPriority")
        echo -n "Enter priority to filter tasks (A/B/C): "
        read priority
        priority=${priority^^}

        if [[ "$priority" == "A" || "$priority" == "B" || "$priority" == "C" ]]; then
            echo "Tasks with priority [$priority]:"
            grep "$priority" "$tasks_file" | while IFS= read -r task; do
                colorized_task=$(colorize_task "$task")
                echo "$colorized_task"
            done
        else
            echo "Invalid priority. Please enter A, B, or C."
        fi
        ;;
    "done")
        task_number="$2"
        if [ -z "$task_number" ]; then
            echo "Specify the task number you want to mark as completed."
        else
            if ! grep -q "^$task_number " "$tasks_file"; then
                echo "Task number not found."
            else
                # Mover la tarea completada a un archivo diferente
                grep "^$task_number " "$tasks_file" >> completed_tasks.txt
                grep -v "^$task_number " "$tasks_file" > tmpfile && mv tmpfile "$tasks_file"
                echo "Task marked as completed and moved to completed_tasks.txt."
            fi
        fi
        ;;
    "export")
        echo "Select export format:"
        select export_format in "CSV" "JSON" "PDF" "Cancel"; do
            case "$export_format" in
                "CSV")
                    echo "Exporting tasks to CSV..."
                    cat "$tasks_file" > tasks.csv
                    echo "Tasks exported to tasks.csv"
                    ;;
                "JSON")
                    echo "Exporting tasks to JSON..."
                    jq -Rn '[inputs]' < "$tasks_file" > tasks.json
                    echo "Tasks exported to tasks.json"
                    ;;
                "PDF")
                    echo "Exporting tasks to PDF..."
                    wkhtmltopdf "$tasks_file" tasks.pdf
                    echo "Tasks exported to tasks.pdf"
                    ;;
                "Cancel")
                    echo "Export canceled."
                    ;;
            *)
                echo "Invalid option."
                ;;
        esac
        break
    done
    ;;
    *)
        echo "Uso: $0 {add|delete|deleteAll|edit|search|list|listTag|listPriority|done|export}"
        ;;
esac