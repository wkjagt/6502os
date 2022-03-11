.global print_file_name
.global clear_dir
.global clear_fat
.global load_dir
.global load_fat

.globalzp dir_page
.globalzp next_empty_page

LAST_PAGE               = $FF
FAT_BUFFER              = $0400
DIR_BUFFER              = $0500
MAX_FILE_NAME_LEN       = 8