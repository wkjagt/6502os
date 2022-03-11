.global print_file_name
.global clear_dir
.global clear_fat
.global load_dir
.global load_fat
.global show_dir
.global format_drive
.global save_dir
.global find_empty_page
.global format_drive
.global save_file
.global load_file

.globalzp dir_page
.globalzp next_empty_page

LAST_PAGE               = $FF
FAT_BUFFER              = $0400
DIR_BUFFER              = $0500
MAX_FILE_NAME_LEN       = 8