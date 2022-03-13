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
.global error_code
.global add_to_dir
.global find_empty_dir
.global delete_dir
.global delete_file
.global save_fat
.global find_file

.globalzp dir_page
.globalzp next_empty_page

LAST_PAGE               = $FF
FAT_BUFFER              = $0400
DIR_BUFFER              = $0500
MAX_FILE_NAME_LEN       = 8

ERR_DIR_FULL            = 1
ERR_DRIVE_FULL          = 2
ERR_FILE_NOT_FOUND      = 3
ERR_FILE_EXISTS         = 4
ERR_NO_DATA             = 5             ; No data to save because load_size is 0